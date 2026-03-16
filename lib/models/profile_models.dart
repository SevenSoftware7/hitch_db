import 'package:hitch_db/models/movie.dart';

Map<String, dynamic> _movieJsonFromEntry(Map<String, dynamic> json) {
  final nested = json['movie'];
  if (nested is Map<String, dynamic>) {
    return nested;
  }
  // Backward-compatible fallback for older flat payloads.
  return json;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.pseudo,
  });

  final int id;
  final String email;
  final String pseudo;

  String get displayName => pseudo.trim().isNotEmpty ? pseudo.trim() : email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      pseudo: json['pseudo'] ?? '',
    );
  }
}

class FavoriteMovieEntry {
  const FavoriteMovieEntry({
    required this.id,
    required this.movie,
    required this.addedAt,
  });

  final int id;
  final Movie movie;
  final DateTime? addedAt;

  factory FavoriteMovieEntry.fromJson(Map<String, dynamic> json) {
    return FavoriteMovieEntry(
      id: json['id'] ?? 0,
      movie: Movie.fromJson(_movieJsonFromEntry(json)),
      addedAt: DateTime.tryParse(json['addedAt'] ?? ''),
    );
  }
}

class WatchLaterMovieEntry {
  const WatchLaterMovieEntry({
    required this.movie,
    required this.addedAt,
  });

  final Movie movie;
  final DateTime? addedAt;

  factory WatchLaterMovieEntry.fromJson(Map<String, dynamic> json) {
    return WatchLaterMovieEntry(
      movie: Movie.fromJson(_movieJsonFromEntry(json)),
      addedAt: DateTime.tryParse(json['addedAt'] ?? ''),
    );
  }
}

class WatchedMovieEntry {
  const WatchedMovieEntry({
    required this.id,
    required this.movie,
    required this.liked,
    required this.rating,
    required this.watchedAt,
  });

  final int id;
  final Movie movie;
  final bool liked;
  final int? rating;
  final DateTime? watchedAt;

  factory WatchedMovieEntry.fromJson(Map<String, dynamic> json) {
    return WatchedMovieEntry(
      id: json['id'] ?? 0,
      movie: Movie.fromJson(_movieJsonFromEntry(json)),
      liked: json['liked'] ?? false,
      rating: json['rating'],
      watchedAt: DateTime.tryParse(json['watchedAt'] ?? ''),
    );
  }
}

class UserMovieList {
  const UserMovieList({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String name;
  final String description;
  final DateTime? createdAt;
  final List<UserMovieListItem> items;

  factory UserMovieList.fromJson(Map<String, dynamic> json) {
    return UserMovieList(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UserMovieListItem.fromJson)
          .toList(),
    );
  }
}

class UserMovieListItem {
  const UserMovieListItem({
    required this.id,
    required this.movie,
    required this.addedAt,
  });

  final int id;
  final Movie movie;
  final DateTime? addedAt;

  factory UserMovieListItem.fromJson(Map<String, dynamic> json) {
    return UserMovieListItem(
      id: json['id'] ?? 0,
      movie: Movie.fromJson(_movieJsonFromEntry(json)),
      addedAt: DateTime.tryParse(json['addedAt'] ?? ''),
    );
  }
}
