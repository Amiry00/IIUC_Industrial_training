import 'package:flutter/material.dart';
import 'package:cinema/data/model/movie.dart';
import 'package:cinema/data/repository/movie_repository.dart';

enum WatchlistSort { dateAdded, rating, title }

class WatchlistProvider extends ChangeNotifier {
  final MovieRepository _repository;

  WatchlistProvider(this._repository);

  List<Movie> _watchlist = [];
  List<Movie> get watchlist => _watchlist;

  List<Movie> _favorites = [];
  List<Movie> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  WatchlistSort _sortBy = WatchlistSort.dateAdded;
  WatchlistSort get sortBy => _sortBy;

  String _filterText = '';

  // Load watchlist
  Future<void> loadWatchlist() async {
    _isLoading = true;
    notifyListeners();

    _watchlist = await _repository.getWatchlist();
    _favorites = await _repository.getFavorites();
    _sortWatchlist();

    _isLoading = false;
    notifyListeners();
  }

  // CREATE - Add to watchlist
  Future<void> addToWatchlist(Movie movie) async {
    await _repository.addToWatchlist(movie);
    await loadWatchlist();
  }

  // UPDATE - Update watchlist item
  Future<void> updateWatchlistItem(int movieId, {
    String? title,
    String? overview,
    double? voteAverage,
    String? userNotes,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (overview != null) updates['overview'] = overview;
    if (voteAverage != null) updates['vote_average'] = voteAverage;
    if (userNotes != null) updates['user_notes'] = userNotes;

    if (updates.isNotEmpty) {
      await _repository.updateWatchlistItem(movieId, updates);
      await loadWatchlist();
    }
  }

  // DELETE - Remove from watchlist
  Future<void> removeFromWatchlist(int movieId) async {
    await _repository.removeFromWatchlist(movieId);
    await loadWatchlist();
  }

  // Toggle favorite
  Future<void> toggleFavorite(int movieId) async {
    final movie = _watchlist.where((m) => m.id == movieId).firstOrNull;
    if (movie != null) {
      await _repository.toggleFavorite(movieId, !movie.isFavorite);
      await loadWatchlist();
    }
  }

  // Check if in watchlist
  Future<bool> isInWatchlist(int movieId) => _repository.isInWatchlist(movieId);

  // Sort
  void setSortBy(WatchlistSort sort) {
    _sortBy = sort;
    _sortWatchlist();
    notifyListeners();
  }

  void _sortWatchlist() {
    switch (_sortBy) {
      case WatchlistSort.dateAdded:
        _watchlist.sort((a, b) => (b.addedAt ?? DateTime(2000)).compareTo(a.addedAt ?? DateTime(2000)));
        break;
      case WatchlistSort.rating:
        _watchlist.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        break;
      case WatchlistSort.title:
        _watchlist.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
  }

  // Filter
  void setFilter(String text) {
    _filterText = text;
    notifyListeners();
  }

  List<Movie> get filteredWatchlist {
    if (_filterText.isEmpty) return _watchlist;
    return _watchlist
        .where((m) => m.title.toLowerCase().contains(_filterText.toLowerCase()))
        .toList();
  }
}
