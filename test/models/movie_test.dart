import 'package:flutter_test/flutter_test.dart';

import 'package:hitch_db/models/movie.dart';

void main() {
  group('Movie', () {
    test('fromJson maps fields and computed values', () {
      final movie = Movie.fromJson({
        'id': 42,
        'title': 'Inception',
        'overview': 'Dreams within dreams.',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'vote_average': 8.7,
        'vote_count': 1234,
        'release_date': '2010-07-16',
        'genre_ids': [28, 878],
        'popularity': 250.5,
        'original_language': 'en',
        'adult': false,
      });

      expect(movie.id, 42);
      expect(movie.title, 'Inception');
      expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
      expect(
        movie.backdropUrl,
        'https://image.tmdb.org/t/p/w1280/backdrop.jpg',
      );
      expect(movie.year, '2010');
      expect(movie.genreIds, [28, 878]);
    });

    test('fromJson uses defaults for missing fields', () {
      final movie = Movie.fromJson({});

      expect(movie.id, 0);
      expect(movie.title, '');
      expect(movie.posterUrl, '');
      expect(movie.backdropUrl, '');
      expect(movie.year, 'N/A');
      expect(movie.genreIds, isEmpty);
      expect(movie.adult, isFalse);
    });
  });

  group('MovieExtensions', () {
    test('applyFilters keeps movies matching all filters', () {
      final movies = [
        Movie.fromJson({
          'id': 1,
          'title': 'Action Hit',
          'genre_ids': [28],
          'vote_average': 8.1,
        }),
        Movie.fromJson({
          'id': 2,
          'title': 'Drama Story',
          'genre_ids': [18],
          'vote_average': 7.4,
        }),
      ];

      final filtered = movies.applyFilters([
        (Movie movie, bool _) => movie.genreIds.contains(28),
        (Movie movie, bool _) => movie.voteAverage >= 8.0,
      ]);

      expect(filtered.map((movie) => movie.id), [1]);
    });
  });
}
