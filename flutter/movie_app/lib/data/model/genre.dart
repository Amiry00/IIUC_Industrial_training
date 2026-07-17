class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Genre.fromMap(Map<String, dynamic> map) {
    return Genre(
      id: map['id'] as int,
      name: (map['name'] ?? '') as String,
    );
  }

  // Predefined genre list as fallback
  static const List<Genre> defaultGenres = [
    Genre(id: 28, name: 'Action'),
    Genre(id: 12, name: 'Adventure'),
    Genre(id: 16, name: 'Animation'),
    Genre(id: 35, name: 'Comedy'),
    Genre(id: 80, name: 'Crime'),
    Genre(id: 99, name: 'Documentary'),
    Genre(id: 18, name: 'Drama'),
    Genre(id: 10751, name: 'Family'),
    Genre(id: 14, name: 'Fantasy'),
    Genre(id: 36, name: 'History'),
    Genre(id: 27, name: 'Horror'),
    Genre(id: 10402, name: 'Music'),
    Genre(id: 9648, name: 'Mystery'),
    Genre(id: 10749, name: 'Romance'),
    Genre(id: 878, name: 'Science Fiction'),
    Genre(id: 10770, name: 'TV Movie'),
    Genre(id: 53, name: 'Thriller'),
    Genre(id: 10752, name: 'War'),
    Genre(id: 37, name: 'Western'),
  ];

  static String getGenreName(int id) {
    final genre = defaultGenres.where((g) => g.id == id).firstOrNull;
    return genre?.name ?? '';
  }

  static List<String> getGenreNames(List<int> ids) {
    return ids.map((id) => getGenreName(id)).where((n) => n.isNotEmpty).toList();
  }
}
