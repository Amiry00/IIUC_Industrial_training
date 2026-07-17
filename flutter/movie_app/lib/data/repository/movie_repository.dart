import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/model/cast.dart' hide Genre;
import 'package:cinema/data/model/genre.dart';
import 'package:cinema/services/api_service.dart';
import 'package:cinema/services/database_service.dart';
import 'package:cinema/services/connectivity_service.dart';
import 'package:cinema/core/constants/api_constants.dart';

class MovieRepository {
  final ApiService _apiService;
  final DatabaseService _dbService;
  final ConnectivityService _connectivityService;

  MovieRepository({
    required this._apiService,
    required this._dbService,
    required this._connectivityService,
  });

  // ===== MOVIE LISTS (with cache) =====

  Future<List<Movie>> getTrending({int page = 1, bool forceRefresh = false}) async {
    return _getMovies('trending', page, forceRefresh, () => _apiService.getTrending(page: page));
  }

  Future<List<Movie>> getPopular({int page = 1, bool forceRefresh = false}) async {
    return _getMovies('popular', page, forceRefresh, () => _apiService.getPopular(page: page));
  }

  Future<List<Movie>> getTopRated({int page = 1, bool forceRefresh = false}) async {
    return _getMovies('top_rated', page, forceRefresh, () => _apiService.getTopRated(page: page));
  }

  Future<List<Movie>> getNowPlaying({int page = 1, bool forceRefresh = false}) async {
    return _getMovies('now_playing', page, forceRefresh, () => _apiService.getNowPlaying(page: page));
  }

  Future<List<Movie>> getUpcoming({int page = 1, bool forceRefresh = false}) async {
    return _getMovies('upcoming', page, forceRefresh, () => _apiService.getUpcoming(page: page));
  }

  Future<List<Movie>> _getMovies(
    String category,
    int page,
    bool forceRefresh,
    Future<Map<String, dynamic>> Function() apiCall,
  ) async {
    final isOnline = await _connectivityService.isConnected;
    final hasRealApiKey = ApiConstants.apiKey.isNotEmpty && ApiConstants.apiKey != 'YOUR_TMDB_API_KEY_HERE';

    if (isOnline && hasRealApiKey) {
      if (forceRefresh || page > 1) {
        try {
          final response = await apiCall();
          final movies = (response['results'] as List<dynamic>)
              .map((m) => Movie.fromJson(m as Map<String, dynamic>))
              .toList();

          // Cache the results
          await _dbService.cacheMovies(movies, category, page);
          return movies;
        } catch (_) {
          // Fall through to cache
        }
      } else {
        try {
          final response = await apiCall();
          final movies = (response['results'] as List<dynamic>)
              .map((m) => Movie.fromJson(m as Map<String, dynamic>))
              .toList();
          await _dbService.cacheMovies(movies, category, page);
          return movies;
        } catch (_) {
          // Fall through to cache
        }
      }
    }

    // Return cached data
    final cached = await _dbService.getCachedMovies(category, page: page);
    if (cached.isNotEmpty) {
      return cached;
    }

    throw Exception('Failed to load movies. Please check your internet connection.');
  }

  // ===== MOVIE DETAIL =====

  Future<MovieDetail> getMovieDetail(int movieId) async {
    final isOnline = await _connectivityService.isConnected;
    final hasRealApiKey = ApiConstants.apiKey.isNotEmpty && ApiConstants.apiKey != 'YOUR_TMDB_API_KEY_HERE';

    // 1. Try to get from cache first
    final cachedData = await _dbService.getCachedMovieDetail(movieId);
    if (cachedData != null) {
      try {
        return MovieDetail.fromJson(cachedData);
      } catch (_) {
        // Fall through on parse error
      }
    }

    if (isOnline && hasRealApiKey) {
      try {
        final response = await _apiService.getMovieDetail(movieId);
        // Cache the full JSON response
        await _dbService.cacheMovieDetail(movieId, response);
        return MovieDetail.fromJson(response);
      } catch (_) {
        // Fall through to mock details
      }
    }

    throw Exception('Failed to load movie details. Please check your internet connection.');
  }

  // ===== SEARCH =====

  Future<List<Movie>> searchMovies({required String query, int page = 1}) async {
    final isOnline = await _connectivityService.isConnected;
    final hasRealApiKey = ApiConstants.apiKey.isNotEmpty && ApiConstants.apiKey != 'YOUR_TMDB_API_KEY_HERE';

    if (isOnline && hasRealApiKey) {
      try {
        final response = await _apiService.searchMovies(query: query, page: page);
        return (response['results'] as List<dynamic>)
            .map((m) => Movie.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fall through to mock search
      }
    }

    throw Exception('Search failed. Please check your internet connection.');
  }

  // ===== GENRES =====

  Future<List<Genre>> getGenres() async {
    final isOnline = await _connectivityService.isConnected;
    final hasRealApiKey = ApiConstants.apiKey.isNotEmpty && ApiConstants.apiKey != 'YOUR_TMDB_API_KEY_HERE';

    if (isOnline && hasRealApiKey) {
      try {
        final response = await _apiService.getGenres();
        final genres = (response['genres'] as List<dynamic>)
            .map((g) => Genre.fromJson(g as Map<String, dynamic>))
            .toList();
        await _dbService.cacheGenres(genres.map((g) => g.toMap()).toList());
        return genres;
      } catch (_) {}
    }

    final cached = await _dbService.getCachedGenres();
    if (cached.isNotEmpty) {
      return cached.map((m) => Genre.fromMap(m)).toList();
    }
    return Genre.defaultGenres;
  }

  // ===== DISCOVER =====

  Future<List<Movie>> discoverByGenre({required int genreId, int page = 1}) async {
    final isOnline = await _connectivityService.isConnected;
    final hasRealApiKey = ApiConstants.apiKey.isNotEmpty && ApiConstants.apiKey != 'YOUR_TMDB_API_KEY_HERE';

    if (isOnline && hasRealApiKey) {
      try {
        final response = await _apiService.discoverByGenre(genreId: genreId, page: page);
        return (response['results'] as List<dynamic>)
            .map((m) => Movie.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fall through to mock discover
      }
    }

    throw Exception('Failed to load movies. Please check your internet connection.');
  }

  // ===== WATCHLIST (LOCAL CRUD) =====

  Future<int> addToWatchlist(Movie movie) => _dbService.addToWatchlist(movie);
  Future<List<Movie>> getWatchlist() => _dbService.getWatchlist();
  Future<int> updateWatchlistItem(int movieId, Map<String, dynamic> updates) =>
      _dbService.updateWatchlistItem(movieId, updates);
  Future<int> removeFromWatchlist(int movieId) => _dbService.removeFromWatchlist(movieId);
  Future<bool> isInWatchlist(int movieId) => _dbService.isInWatchlist(movieId);
  Future<int> toggleFavorite(int movieId, bool isFavorite) =>
      _dbService.toggleFavorite(movieId, isFavorite);
  Future<List<Movie>> getFavorites() => _dbService.getFavorites();

  // ===== RECENTLY VIEWED =====

  Future<void> addToRecentlyViewed(Movie movie) => _dbService.addToRecentlyViewed(movie);
  Future<List<Movie>> getRecentlyViewed() => _dbService.getRecentlyViewed();

  // ===== CACHE =====

  Future<void> clearCache() => _dbService.clearAllCache();

  Future<bool> get isOnline => _connectivityService.isConnected;
}
