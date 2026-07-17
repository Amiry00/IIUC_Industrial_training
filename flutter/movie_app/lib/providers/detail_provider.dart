import 'package:flutter/material.dart';
import 'package:cinema/data/model/cast.dart';
import 'package:cinema/data/repository/movie_repository.dart';
import 'package:cinema/data/model/movie.dart';

class DetailProvider extends ChangeNotifier {
  final MovieRepository _repository;

  DetailProvider(this._repository);

  MovieDetail? _movieDetail;
  MovieDetail? get movieDetail => _movieDetail;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool _isInWatchlist = false;
  bool get isInWatchlist => _isInWatchlist;

  Future<void> fetchMovieDetail(int movieId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _movieDetail = await _repository.getMovieDetail(movieId);
      _isInWatchlist = await _repository.isInWatchlist(movieId);

      // Add to recently viewed
      await _repository.addToRecentlyViewed(Movie(
        id: movieId,
        title: _movieDetail!.title,
        overview: _movieDetail!.overview,
        posterPath: _movieDetail!.posterPath,
        backdropPath: _movieDetail!.backdropPath,
        voteAverage: _movieDetail!.voteAverage,
        releaseDate: _movieDetail!.releaseDate,
        genreIds: _movieDetail!.genres.map((g) => g.id).toList(),
      ));
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleWatchlist(Movie movie) async {
    if (_isInWatchlist) {
      await _repository.removeFromWatchlist(movie.id);
      _isInWatchlist = false;
    } else {
      await _repository.addToWatchlist(movie);
      _isInWatchlist = true;
    }
    notifyListeners();
  }

  void clear() {
    _movieDetail = null;
    _isLoading = false;
    _errorMessage = '';
    _isInWatchlist = false;
  }
}
