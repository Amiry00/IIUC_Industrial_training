import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/repository/movie_repository.dart';

class SearchProvider extends ChangeNotifier {
  final MovieRepository _repository;

  SearchProvider(this._repository);

  List<Movie> _results = [];
  List<Movie> get results => _results;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _query = '';
  String get query => _query;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  Timer? _debounceTimer;

  // Debounced search
  void search(String query) {
    _query = query;
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _results = [];
      _isLoading = false;
      _errorMessage = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      _currentPage = 1;
      _hasMore = true;
      _results = await _repository.searchMovies(query: query, page: 1);
      if (_results.length < 20) _hasMore = false;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _results = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // Load more search results
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _query.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newResults = await _repository.searchMovies(
        query: _query,
        page: _currentPage,
      );
      _results.addAll(newResults);
      if (newResults.isEmpty || newResults.length < 20) _hasMore = false;
    } catch (_) {}

    _isLoadingMore = false;
    notifyListeners();
  }

  void clear() {
    _query = '';
    _results = [];
    _isLoading = false;
    _errorMessage = '';
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
