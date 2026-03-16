import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:hitch_db/models/movie.dart';
import 'package:hitch_db/services/login_service.dart';
import 'package:hitch_db/services/movie_service.dart';

class _TestLoginService extends LoginService {
  _TestLoginService(this.token) : super(baseUrl: 'https://api.example.com');

  final String? token;

  @override
  Future<String?> getAccessToken() async => token;
}

void main() {
  group('MovieService', () {
    test('getPopularMovies parses results, caches movies, and sends auth header', () async {
      http.BaseRequest? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 100,
                'title': 'Arrival',
                'poster_path': '/arrival.jpg',
                'vote_average': 8.0,
              },
            ],
          }),
          200,
        );
      });

      final service = MovieService(
        _TestLoginService('token-123'),
        baseUrl: 'https://api.example.com',
        client: client,
      );

      final movies = await service.getPopularMovies(page: 2);

      expect(movies, hasLength(1));
      expect(movies.first.id, 100);
      expect(service.cachedMovies, hasLength(1));
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.path, '/api/Movies/popular');
      expect(capturedRequest!.url.queryParameters['page'], '2');
      expect(capturedRequest!.headers['Authorization'], 'Bearer token-123');
    });

    test('searchMovies returns empty list and skips request when query is blank', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      final service = MovieService(
        _TestLoginService('token-123'),
        baseUrl: 'https://api.example.com',
        client: client,
      );

      final results = await service.searchMovies('');

      expect(results, isEmpty);
      expect(requestCount, 0);
    });

    test('swiperMovies excludes watched and watch-later entries', () async {
      final client = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/Movies/popular') {
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 1, 'title': 'A', 'poster_path': '/a.jpg'},
                {'id': 2, 'title': 'B', 'poster_path': '/b.jpg'},
                {'id': 3, 'title': 'C', 'poster_path': '/c.jpg'},
              ],
            }),
            200,
          );
        }

        if (path == '/api/Users/me') {
          return http.Response(
            jsonEncode({'id': 9, 'email': 'user@example.com', 'pseudo': 'Neo'}),
            200,
          );
        }

        if (path == '/api/FavoriteMovies') {
          return http.Response('[]', 200);
        }

        if (path == '/api/WatchLaterMovies') {
          return http.Response(
            jsonEncode([
              {
                'movie': {'id': 2, 'title': 'B', 'poster_path': '/b.jpg'},
                'addedAt': '2026-03-16T10:00:00Z',
              },
            ]),
            200,
          );
        }

        if (path == '/api/WatchedMovies') {
          return http.Response(
            jsonEncode([
              {
                'id': 77,
                'movie': {'id': 3, 'title': 'C', 'poster_path': '/c.jpg'},
                'liked': true,
                'rating': 4,
                'watchedAt': '2026-03-16T10:00:00Z',
              },
            ]),
            200,
          );
        }

        if (path == '/api/MovieLists') {
          return http.Response('[]', 200);
        }

        return http.Response('Not found', 404);
      });

      final service = MovieService(
        _TestLoginService('token-123'),
        baseUrl: 'https://api.example.com',
        client: client,
      );

      await service.getPopularMovies();
      await service.refreshProfileData();

      expect(service.swiperMovies.map((movie) => movie.id), [1]);
      expect(service.watchLaterMovies.map((entry) => entry.movie.id), [2]);
      expect(service.isInWatchLater(Movie.fromJson({'id': 2})), isTrue);
      expect(service.isWatched(Movie.fromJson({'id': 3})), isTrue);
    });

    test('throws StateError when token is missing', () async {
      final client = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final service = MovieService(
        _TestLoginService(null),
        baseUrl: 'https://api.example.com',
        client: client,
      );

      expect(
        () => service.getPopularMovies(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
