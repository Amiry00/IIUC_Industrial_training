import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';

/// SQLite database service for local storage.
class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.stationsTable} (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT,
        country_code TEXT,
        provider TEXT,
        latitude REAL,
        longitude REAL,
        timezone TEXT,
        is_mobile INTEGER DEFAULT 0,
        is_monitor INTEGER DEFAULT 0,
        latest_readings TEXT,
        last_updated TEXT,
        is_favorite INTEGER DEFAULT 0,
        is_local INTEGER DEFAULT 0,
        user_notes TEXT,
        cached_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.cacheMetaTable} (
        cache_key TEXT PRIMARY KEY,
        cached_at TEXT NOT NULL
      )
    ''');

    // Authentication
    await db.execute('''
      CREATE TABLE ${AppConstants.usersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        avatar_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Notifications
    await db.execute('''
      CREATE TABLE ${AppConstants.notificationsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Search History
    await db.execute('''
      CREATE TABLE ${AppConstants.searchHistoryTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT UNIQUE NOT NULL,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Recently Viewed
    await db.execute('''
      CREATE TABLE ${AppConstants.recentlyViewedTable} (
        station_id INTEGER PRIMARY KEY,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Settings
    await db.execute('''
      CREATE TABLE ${AppConstants.settingsTable} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Handle database upgrades — drop and recreate for schema migration.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop old tables from v1 (articles-based schema)
    await db.execute('DROP TABLE IF EXISTS articles');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.stationsTable}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.cacheMetaTable}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.usersTable}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.notificationsTable}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.searchHistoryTable}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.recentlyViewedTable}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.settingsTable}');
    await _onCreate(db, newVersion);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
