import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:cinema/core/constants/api_constants.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      queryParameters: {
        'api_key': ApiConstants.apiKey,
        'language': 'en-US',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) {
        if (kDebugMode) {
          debugPrint('[API] $obj');
        }
      },
    ));
  }

  // Trending movies
  Future<Map<String, dynamic>> getTrending({int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.trending,
      queryParameters: {'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  // Popular movies
  Future<Map<String, dynamic>> getPopular({int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.popular,
      queryParameters: {'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  // Top rated movies
  Future<Map<String, dynamic>> getTopRated({int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.topRated,
      queryParameters: {'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  // Now playing movies
  Future<Map<String, dynamic>> getNowPlaying({int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.nowPlaying,
      queryParameters: {'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  // Upcoming movies
  Future<Map<String, dynamic>> getUpcoming({int page = 1}) async {
    final response = await _dio.get(
      ApiConstants.upcoming,
      queryParameters: {'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  // Search movies
  Future<Map<String, dynamic>> searchMovies({
    required String query,
    int page = 1,
  }) async {
    final response = await _dio.get(
      ApiConstants.searchMovie,
      queryParameters: {'query': query, 'page': page},
    );
    return response.data as Map<String, dynamic>;
  }

  // Movie details with credits and similar
  Future<Map<String, dynamic>> getMovieDetail(int movieId) async {
    final response = await _dio.get(
      '${ApiConstants.movieDetail}/$movieId',
      queryParameters: {'append_to_response': 'credits,similar,videos'},
    );
    return response.data as Map<String, dynamic>;
  }

  // Genre list
  Future<Map<String, dynamic>> getGenres() async {
    final response = await _dio.get(ApiConstants.genreList);
    return response.data as Map<String, dynamic>;
  }

  // Discover movies by genre
  Future<Map<String, dynamic>> discoverByGenre({
    required int genreId,
    int page = 1,
  }) async {
    final response = await _dio.get(
      ApiConstants.discover,
      queryParameters: {
        'with_genres': genreId,
        'page': page,
        'sort_by': 'popularity.desc',
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
