class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int> genreIds;
  final double popularity;
  final String? originalLanguage;
  final bool adult;

  // Local-only fields
  final bool isFavorite;
  final bool isInWatchlist;
  final String? userNotes;
  final DateTime? addedAt;

  const Movie({
    required this.id,
    required this.title,
    this.overview = '',
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.releaseDate,
    this.genreIds = const [],
    this.popularity = 0.0,
    this.originalLanguage,
    this.adult = false,
    this.isFavorite = false,
    this.isInWatchlist = false,
    this.userNotes,
    this.addedAt,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: (json['vote_count'] ?? 0) as int,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      popularity: (json['popularity'] ?? 0.0).toDouble(),
      originalLanguage: json['original_language'] as String?,
      adult: (json['adult'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genre_ids': genreIds,
      'popularity': popularity,
      'original_language': originalLanguage,
      'adult': adult,
    };
  }

  // SQLite map conversion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'release_date': releaseDate,
      'genre_ids': genreIds.join(','),
      'popularity': popularity,
      'original_language': originalLanguage,
      'adult': adult ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'is_in_watchlist': isInWatchlist ? 1 : 0,
      'user_notes': userNotes,
      'added_at': addedAt?.toIso8601String(),
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] as int,
      title: (map['title'] ?? '') as String,
      overview: (map['overview'] ?? '') as String,
      posterPath: map['poster_path'] as String?,
      backdropPath: map['backdrop_path'] as String?,
      voteAverage: (map['vote_average'] ?? 0.0).toDouble(),
      voteCount: (map['vote_count'] ?? 0) as int,
      releaseDate: map['release_date'] as String?,
      genreIds: map['genre_ids'] != null && (map['genre_ids'] as String).isNotEmpty
          ? (map['genre_ids'] as String).split(',').map((e) => int.parse(e.trim())).toList()
          : [],
      popularity: (map['popularity'] ?? 0.0).toDouble(),
      originalLanguage: map['original_language'] as String?,
      adult: (map['adult'] ?? 0) == 1,
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      isInWatchlist: (map['is_in_watchlist'] ?? 0) == 1,
      userNotes: map['user_notes'] as String?,
      addedAt: map['added_at'] != null
          ? DateTime.tryParse(map['added_at'] as String)
          : null,
    );
  }

  Movie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    List<int>? genreIds,
    double? popularity,
    String? originalLanguage,
    bool? adult,
    bool? isFavorite,
    bool? isInWatchlist,
    String? userNotes,
    DateTime? addedAt,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      popularity: popularity ?? this.popularity,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      adult: adult ?? this.adult,
      isFavorite: isFavorite ?? this.isFavorite,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
      userNotes: userNotes ?? this.userNotes,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.split('-').first;
  }

  String get ratingText => voteAverage.toStringAsFixed(1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
