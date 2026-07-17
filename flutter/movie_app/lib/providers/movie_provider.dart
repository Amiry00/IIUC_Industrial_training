import 'package:flutter/material.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/model/genre.dart';
import 'package:cinema/data/repository/movie_repository.dart';

enum LoadingState { initial, loading, loaded, error }

class MovieProvider extends ChangeNotifier {
  final MovieRepository _repository;

  MovieProvider(this._repository);

  // State
  LoadingState _state = LoadingState.initial;
  LoadingState get state => _state;
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Movie lists
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _topRated = [];
  List<Movie> _nowPlaying = [];
  List<Movie> _upcoming = [];
  List<Genre> _genres = [];

  List<Movie> get trending => _trending;
  List<Movie> get popular => _popular;
  List<Movie> get topRated => _topRated;
  List<Movie> get nowPlaying => _nowPlaying;
  List<Movie> get upcoming => _upcoming;
  List<Genre> get genres => _genres;

  // Pagination
  final Map<String, int> _currentPage = {
    'trending': 1,
    'popular': 1,
    'top_rated': 1,
    'now_playing': 1,
    'upcoming': 1,
  };
  final Map<String, bool> _hasMore = {
    'trending': true,
    'popular': true,
    'top_rated': true,
    'now_playing': true,
    'upcoming': true,
  };
  final Map<String, bool> _isLoadingMore = {
    'trending': false,
    'popular': false,
    'top_rated': false,
    'now_playing': false,
    'upcoming': false,
  };

  bool hasMore(String category) => _hasMore[category] ?? false;
  bool isLoadingMore(String category) => _isLoadingMore[category] ?? false;

  // Featured movie (first trending)
  Movie? get featuredMovie => _trending.isNotEmpty ? _trending.first : null;

  // Initialize all data
  Future<void> initialize() async {
    if (_state == LoadingState.loading) return;
    _state = LoadingState.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getTrending(),
        _repository.getPopular(),
        _repository.getTopRated(),
        _repository.getNowPlaying(),
        _repository.getUpcoming(),
        _repository.getGenres(),
      ]);

      _trending = results[0] as List<Movie>;
      _popular = results[1] as List<Movie>;
      _topRated = results[2] as List<Movie>;
      _nowPlaying = results[3] as List<Movie>;
      _upcoming = results[4] as List<Movie>;
      _genres = results[5] as List<Genre>;

      _state = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LoadingState.error;
    }
    notifyListeners();
  }

  // Load more for infinite scroll
  Future<void> loadMore(String category) async {
    if (_isLoadingMore[category] == true || _hasMore[category] == false) return;

    _isLoadingMore[category] = true;
    notifyListeners();

    try {
      final nextPage = (_currentPage[category] ?? 1) + 1;
      List<Movie> newMovies;

      switch (category) {
        case 'trending':
          newMovies = await _repository.getTrending(page: nextPage);
          _trending.addAll(newMovies);
          break;
        case 'popular':
          newMovies = await _repository.getPopular(page: nextPage);
          _popular.addAll(newMovies);
          break;
        case 'top_rated':
          newMovies = await _repository.getTopRated(page: nextPage);
          _topRated.addAll(newMovies);
          break;
        case 'now_playing':
          newMovies = await _repository.getNowPlaying(page: nextPage);
          _nowPlaying.addAll(newMovies);
          break;
        case 'upcoming':
          newMovies = await _repository.getUpcoming(page: nextPage);
          _upcoming.addAll(newMovies);
          break;
        default:
          newMovies = [];
      }

      _currentPage[category] = nextPage;
      if (newMovies.isEmpty || newMovies.length < 20) {
        _hasMore[category] = false;
      }
    } catch (e) {
      // Silently fail on load more
    }

    _isLoadingMore[category] = false;
    notifyListeners();
  }

  // Pull to refresh
  Future<void> refresh() async {
    _currentPage.updateAll((key, value) => 1);
    _hasMore.updateAll((key, value) => true);

    try {
      final results = await Future.wait([
        _repository.getTrending(forceRefresh: true),
        _repository.getPopular(forceRefresh: true),
        _repository.getTopRated(forceRefresh: true),
        _repository.getNowPlaying(forceRefresh: true),
        _repository.getUpcoming(forceRefresh: true),
      ]);

      _trending = results[0];
      _popular = results[1];
      _topRated = results[2];
      _nowPlaying = results[3];
      _upcoming = results[4];

      _state = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
