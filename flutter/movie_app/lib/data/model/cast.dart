class CastMember {
  final int id;
  final String name;
  final String character;
  final String? profilePath;
  final int order;

  const CastMember({
    required this.id,
    required this.name,
    this.character = '',
    this.profilePath,
    this.order = 0,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      character: (json['character'] ?? '') as String,
      profilePath: json['profile_path'] as String?,
      order: (json['order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'character': character,
      'profile_path': profilePath,
      'order': order,
    };
  }
}

class MovieDetail {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<Genre> genres;
  final int? runtime;
  final String? tagline;
  final int? budget;
  final int? revenue;
  final String? status;
  final List<CastMember> cast;
  final List<MovieSummary> similar;
  final String? trailerId;

  const MovieDetail({
    required this.id,
    required this.title,
    this.overview = '',
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.releaseDate,
    this.genres = const [],
    this.runtime,
    this.tagline,
    this.budget,
    this.revenue,
    this.status,
    this.cast = const [],
    this.similar = const [],
    this.trailerId,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    final creditsJson = json['credits'] as Map<String, dynamic>?;
    final similarJson = json['similar'] as Map<String, dynamic>?;
    final videosJson = json['videos'] as Map<String, dynamic>?;
    
    String? trailerId;
    if (videosJson != null && videosJson['results'] != null) {
      final results = videosJson['results'] as List<dynamic>;
      try {
        final trailers = results.where(
          (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
        ).toList();
        
        if (trailers.isNotEmpty) {
          final officialTrailer = trailers.firstWhere(
            (v) => v['official'] == true,
            orElse: () => trailers.first,
          );
          trailerId = officialTrailer['key'] as String?;
        } else {
          final anyYoutube = results.where(
            (v) => v['site'] == 'YouTube',
          ).toList();
          if (anyYoutube.isNotEmpty) {
            trailerId = anyYoutube.first['key'] as String?;
          }
        }
      } catch (_) {
        // No trailer found
      }
    }

    return MovieDetail(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      voteCount: (json['vote_count'] ?? 0) as int,
      releaseDate: json['release_date'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => Genre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      runtime: json['runtime'] as int?,
      tagline: json['tagline'] as String?,
      budget: json['budget'] as int?,
      revenue: json['revenue'] as int?,
      status: json['status'] as String?,
      cast: (creditsJson?['cast'] as List<dynamic>?)
              ?.take(15)
              .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      similar: (similarJson?['results'] as List<dynamic>?)
              ?.take(10)
              .map((m) => MovieSummary.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      trailerId: trailerId,
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
      'genres': genres.map((g) => g.toJson()).toList(),
      'runtime': runtime,
      'tagline': tagline,
      'budget': budget,
      'revenue': revenue,
      'status': status,
      'credits': {
        'cast': cast.map((c) => c.toJson()).toList(),
      },
      'similar': {
        'results': similar.map((s) => s.toJson()).toList(),
      },
      if (trailerId != null)
        'videos': {
          'results': [
            {'type': 'Trailer', 'site': 'YouTube', 'key': trailerId}
          ]
        }
    };
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.split('-').first;
  }

  String get runtimeFormatted {
    if (runtime == null || runtime == 0) return '';
    final hours = runtime! ~/ 60;
    final minutes = runtime! % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String get genreText => genres.map((g) => g.name).join(', ');
}

class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'] as int, name: (json['name'] ?? '') as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class MovieSummary {
  final int id;
  final String title;
  final String? posterPath;
  final double voteAverage;

  const MovieSummary({
    required this.id,
    required this.title,
    this.posterPath,
    this.voteAverage = 0.0,
  });

  factory MovieSummary.fromJson(Map<String, dynamic> json) {
    return MovieSummary(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'vote_average': voteAverage,
    };
  }
}
