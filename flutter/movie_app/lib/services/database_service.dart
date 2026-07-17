import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cinema/data/model/movie.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'cinevault.db';
  static const int _dbVersion = 4;

  int currentUserId = 0;

  // Table names
  static const String tableMovies = 'movies';
  static const String tableWatchlist = 'watchlist';
  static const String tableRecentlyViewed = 'recently_viewed';
  static const String tableGenres = 'genres';
  static const String tableMovieDetails = 'movie_details';
  static const String tableUsers = 'users';
  static const String tableSession = 'session';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cached movies from API
    await db.execute('''
      CREATE TABLE $tableMovies (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        overview TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        vote_average REAL DEFAULT 0.0,
        vote_count INTEGER DEFAULT 0,
        release_date TEXT,
        genre_ids TEXT,
        popularity REAL DEFAULT 0.0,
        original_language TEXT,
        adult INTEGER DEFAULT 0,
        category TEXT NOT NULL,
        page INTEGER DEFAULT 1,
        cached_at TEXT NOT NULL
      )
    ''');

    // User's watchlist (CRUD operations)
    await db.execute('''
      CREATE TABLE $tableWatchlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER DEFAULT 0,
        movie_id INTEGER,
        title TEXT NOT NULL,
        overview TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        vote_average REAL DEFAULT 0.0,
        vote_count INTEGER DEFAULT 0,
        release_date TEXT,
        genre_ids TEXT,
        popularity REAL DEFAULT 0.0,
        original_language TEXT,
        adult INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        is_in_watchlist INTEGER DEFAULT 1,
        user_notes TEXT,
        added_at TEXT NOT NULL
      )
    ''');

    // Recently viewed movies
    await db.execute('''
      CREATE TABLE $tableRecentlyViewed (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        poster_path TEXT,
        backdrop_path TEXT,
        vote_average REAL DEFAULT 0.0,
        release_date TEXT,
        genre_ids TEXT,
        overview TEXT,
        vote_count INTEGER DEFAULT 0,
        popularity REAL DEFAULT 0.0,
        original_language TEXT,
        adult INTEGER DEFAULT 0,
        viewed_at TEXT NOT NULL
      )
    ''');

    // Cached genres
    await db.execute('''
      CREATE TABLE $tableGenres (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    // Cached movie details
    await db.execute('''
      CREATE TABLE $tableMovieDetails (
        movie_id INTEGER PRIMARY KEY,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Users
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Session (only stores 1 row for active user)
    await db.execute('''
      CREATE TABLE $tableSession (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableMovieDetails (
          movie_id INTEGER PRIMARY KEY,
          json_data TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableSession (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          user_id INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE $tableWatchlist ADD COLUMN user_id INTEGER DEFAULT 0
      ''');
    }
  }

  // ===== CACHE OPERATIONS =====

  Future<void> cacheMovies(List<Movie> movies, String category, int page) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final movie in movies) {
      final map = movie.toMap();
      map.remove('is_favorite');
      map.remove('is_in_watchlist');
      map.remove('user_notes');
      map.remove('added_at');

      batch.insert(
        tableMovies,
        {
          ...map,
          'category': category,
          'page': page,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Movie>> getCachedMovies(String category, {int? page}) async {
    final db = await database;
    final where = page != null ? 'category = ? AND page = ?' : 'category = ?';
    final whereArgs = page != null ? [category, page] : [category];

    final maps = await db.query(
      tableMovies,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'popularity DESC',
    );
    return maps.map((m) => Movie.fromMap(m)).toList();
  }

  Future<void> clearCategoryCache(String category) async {
    final db = await database;
    await db.delete(tableMovies, where: 'category = ?', whereArgs: [category]);
  }

  // ===== MOVIE DETAILS CACHE =====

  Future<void> cacheMovieDetail(int movieId, Map<String, dynamic> jsonData) async {
    final db = await database;
    await db.insert(
      tableMovieDetails,
      {
        'movie_id': movieId,
        'json_data': jsonEncode(jsonData),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedMovieDetail(int movieId) async {
    final db = await database;
    final result = await db.query(
      tableMovieDetails,
      where: 'movie_id = ?',
      whereArgs: [movieId],
    );
    if (result.isNotEmpty) {
      return jsonDecode(result.first['json_data'] as String) as Map<String, dynamic>;
    }
    return null;
  }

  // ===== WATCHLIST CRUD =====

  Future<int> addToWatchlist(Movie movie) async {
    final db = await database;
    return await db.insert(
      tableWatchlist,
      {
        'user_id': currentUserId,
        'movie_id': movie.id,
        'title': movie.title,
        'overview': movie.overview,
        'poster_path': movie.posterPath,
        'backdrop_path': movie.backdropPath,
        'vote_average': movie.voteAverage,
        'vote_count': movie.voteCount,
        'release_date': movie.releaseDate,
        'genre_ids': movie.genreIds.join(','),
        'popularity': movie.popularity,
        'original_language': movie.originalLanguage,
        'adult': movie.adult ? 1 : 0,
        'is_favorite': movie.isFavorite ? 1 : 0,
        'is_in_watchlist': 1,
        'user_notes': movie.userNotes,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Movie>> getWatchlist() async {
    final db = await database;
    final maps = await db.query(
      tableWatchlist,
      where: 'user_id = ?',
      whereArgs: [currentUserId],
      orderBy: 'added_at DESC',
    );
    return maps.map((m) => Movie(
      id: m['movie_id'] as int? ?? m['id'] as int,
      title: (m['title'] ?? '') as String,
      overview: (m['overview'] ?? '') as String,
      posterPath: m['poster_path'] as String?,
      backdropPath: m['backdrop_path'] as String?,
      voteAverage: (m['vote_average'] ?? 0.0) as double,
      voteCount: (m['vote_count'] ?? 0) as int,
      releaseDate: m['release_date'] as String?,
      genreIds: m['genre_ids'] != null && (m['genre_ids'] as String).isNotEmpty
          ? (m['genre_ids'] as String).split(',').map((e) => int.parse(e.trim())).toList()
          : [],
      popularity: (m['popularity'] ?? 0.0) as double,
      originalLanguage: m['original_language'] as String?,
      adult: (m['adult'] ?? 0) == 1,
      isFavorite: (m['is_favorite'] ?? 0) == 1,
      isInWatchlist: true,
      userNotes: m['user_notes'] as String?,
      addedAt: m['added_at'] != null ? DateTime.tryParse(m['added_at'] as String) : null,
    )).toList();
  }

  Future<int> updateWatchlistItem(int movieId, Map<String, dynamic> updates) async {
    final db = await database;
    return await db.update(
      tableWatchlist,
      updates,
      where: 'movie_id = ? AND user_id = ?',
      whereArgs: [movieId, currentUserId],
    );
  }

  Future<int> removeFromWatchlist(int movieId) async {
    final db = await database;
    return await db.delete(
      tableWatchlist,
      where: 'movie_id = ? AND user_id = ?',
      whereArgs: [movieId, currentUserId],
    );
  }

  Future<bool> isInWatchlist(int movieId) async {
    final db = await database;
    final result = await db.query(
      tableWatchlist,
      where: 'movie_id = ? AND user_id = ?',
      whereArgs: [movieId, currentUserId],
    );
    return result.isNotEmpty;
  }

  Future<int> toggleFavorite(int movieId, bool isFavorite) async {
    final db = await database;
    return await db.update(
      tableWatchlist,
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'movie_id = ? AND user_id = ?',
      whereArgs: [movieId, currentUserId],
    );
  }

  Future<List<Movie>> getFavorites() async {
    final db = await database;
    final maps = await db.query(
      tableWatchlist,
      where: 'is_favorite = ? AND user_id = ?',
      whereArgs: [1, currentUserId],
      orderBy: 'added_at DESC',
    );
    return maps.map((m) => Movie(
      id: m['movie_id'] as int? ?? m['id'] as int,
      title: (m['title'] ?? '') as String,
      overview: (m['overview'] ?? '') as String,
      posterPath: m['poster_path'] as String?,
      backdropPath: m['backdrop_path'] as String?,
      voteAverage: (m['vote_average'] ?? 0.0) as double,
      isFavorite: true,
      isInWatchlist: true,
      releaseDate: m['release_date'] as String?,
      genreIds: m['genre_ids'] != null && (m['genre_ids'] as String).isNotEmpty
          ? (m['genre_ids'] as String).split(',').map((e) => int.parse(e.trim())).toList()
          : [],
    )).toList();
  }

  // ===== RECENTLY VIEWED =====

  Future<void> addToRecentlyViewed(Movie movie) async {
    final db = await database;
    await db.insert(
      tableRecentlyViewed,
      {
        'id': movie.id,
        'title': movie.title,
        'poster_path': movie.posterPath,
        'backdrop_path': movie.backdropPath,
        'vote_average': movie.voteAverage,
        'release_date': movie.releaseDate,
        'genre_ids': movie.genreIds.join(','),
        'overview': movie.overview,
        'vote_count': movie.voteCount,
        'popularity': movie.popularity,
        'original_language': movie.originalLanguage,
        'adult': movie.adult ? 1 : 0,
        'viewed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Keep only last 20 viewed
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableRecentlyViewed'),
    );
    if (count != null && count > 20) {
      await db.rawDelete('''
        DELETE FROM $tableRecentlyViewed WHERE id NOT IN (
          SELECT id FROM $tableRecentlyViewed ORDER BY viewed_at DESC LIMIT 20
        )
      ''');
    }
  }

  Future<List<Movie>> getRecentlyViewed() async {
    final db = await database;
    final maps = await db.query(
      tableRecentlyViewed,
      orderBy: 'viewed_at DESC',
      limit: 20,
    );
    return maps.map((m) => Movie.fromMap(m)).toList();
  }

  // ===== GENRES =====

  Future<void> cacheGenres(List<Map<String, dynamic>> genres) async {
    final db = await database;
    final batch = db.batch();
    for (final genre in genres) {
      batch.insert(tableGenres, genre, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedGenres() async {
    final db = await database;
    return await db.query(tableGenres);
  }

  // ===== UTILITY =====

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete(tableMovies);
    await db.delete(tableRecentlyViewed);
    await db.delete(tableGenres);
  }

  // ===== AUTHENTICATION =====

  Future<Map<String, dynamic>?> registerUser(String name, String email, String password) async {
    final db = await database;
    try {
      final id = await db.insert(
        tableUsers,
        {'name': name, 'email': email, 'password': password},
      );
      return {'id': id, 'name': name, 'email': email};
    } catch (e) {
      return null; // Email likely already exists due to UNIQUE constraint
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      final user = result.first;
      // Save session
      await db.insert(
        tableSession,
        {'id': 1, 'user_id': user['id']},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return user;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentSession() async {
    final db = await database;
    final sessionResult = await db.query(tableSession, where: 'id = 1');
    if (sessionResult.isNotEmpty) {
      final userId = sessionResult.first['user_id'];
      final userResult = await db.query(tableUsers, where: 'id = ?', whereArgs: [userId]);
      if (userResult.isNotEmpty) {
        return userResult.first;
      }
    }
    return null;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete(tableSession);
  }
}
