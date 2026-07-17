class ApiConstants {
  ApiConstants._();

  // TMDb API - Free public API from https://github.com/public-apis/public-apis
  // Get your free API key at: https://www.themoviedb.org/settings/api
  static const String apiKey = '2c070769381ebd36e833cd5daae75d50';
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';

  // Image sizes
  static const String posterSize = '/w500';
  static const String backdropSize = '/w780';
  static const String profileSize = '/w185';

  // Endpoints
  static const String trending = '/trending/movie/day';
  static const String popular = '/movie/popular';
  static const String topRated = '/movie/top_rated';
  static const String nowPlaying = '/movie/now_playing';
  static const String upcoming = '/movie/upcoming';
  static const String searchMovie = '/search/movie';
  static const String movieDetail = '/movie'; // /{id}
  static const String genreList = '/genre/movie/list';
  static const String discover = '/discover/movie';

  // Helper methods
  static String posterUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$imageBaseUrl$posterSize$path';
  }

  static String backdropUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$imageBaseUrl$backdropSize$path';
  }

  static String profileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$imageBaseUrl$profileSize$path';
  }
}
