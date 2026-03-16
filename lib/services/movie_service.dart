import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:hitch_db/app_config.dart';
import 'package:hitch_db/models/profile_models.dart';
import 'package:hitch_db/services/login_service.dart';

import '../models/movie.dart';

class MovieService extends ChangeNotifier {
  MovieService(this._loginService, {String? baseUrl, http.Client? client})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _client = client ?? http.Client();

  LoginService _loginService;
  final String _baseUrl;
  final http.Client _client;

  List<Movie> _cachedMovies = [];
  UserProfile? _profile;
  List<FavoriteMovieEntry> _favorites = const [];
  List<WatchLaterMovieEntry> _watchLaterMovies = const [];
  List<WatchedMovieEntry> _watchedMovies = const [];
  List<UserMovieList> _movieLists = const [];
  bool _isInitializing = false;
  bool _isLoadingMovies = false;
  bool _isLoadingProfile = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;

  List<Movie> get cachedMovies => _cachedMovies;

  List<Movie> get swiperMovies {
    final excludedIds = {
      ..._watchedMovies.map((e) => e.movie.id),
      ..._watchLaterMovies.map((e) => e.movie.id),
    };
    return _cachedMovies.where((m) => !excludedIds.contains(m.id)).toList();
  }

  UserProfile? get profile => _profile;
  List<FavoriteMovieEntry> get favorites => _favorites;
  List<WatchLaterMovieEntry> get watchLaterMovies {
    final excludedIds = {
      ..._watchedMovies.map((e) => e.movie.id),
    };
    return _watchLaterMovies.where((m) => !excludedIds.contains(m.movie.id)).toList();
  }
  List<WatchedMovieEntry> get watchedMovies => _watchedMovies;
  List<UserMovieList> get movieLists => _movieLists;
  bool get isInitializing => _isInitializing;
  bool get isLoadingMovies => _isLoadingMovies;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get errorMessage => _errorMessage;

  void updateLoginService(LoginService loginService) {
    _loginService = loginService;
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isInitializing) {
      return;
    }
    if (_hasLoadedOnce && !forceRefresh) {
      return;
    }

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([getPopularMovies(), refreshProfileData()]);
      _hasLoadedOnce = true;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    _isLoadingMovies = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = await _getJson('/api/Movies/popular?page=$page');
      final movies = _parseMovieResults(payload);
      _cachedMovies = movies;
      return movies;
    } catch (e) {
      _errorMessage = 'Unable to load movies: $e';
      rethrow;
    } finally {
      _isLoadingMovies = false;
      notifyListeners();
    }
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];

    final encodedQuery = Uri.encodeQueryComponent(query);
    final payload = await _getJson(
      '/api/Movies/search?query=$encodedQuery&page=$page',
    );
    return _parseMovieResults(payload);
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    final payload = await _getJson('/api/Movies/top-rated?page=$page');
    return _parseMovieResults(payload);
  }

  Future<Movie?> getMovieById(int tmdbId) async {
    try {
      final payload = await _getJson('/api/Movies/$tmdbId');
      final movie = Movie.fromJson(payload as Map<String, dynamic>);
      _cachedMovies.add(movie);
      return movie;
    } catch (e) {
      _errorMessage = 'Unable to load movie details: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshProfileData() async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _getJson('/api/Users/me'),
        _getJson('/api/FavoriteMovies'),
        _getJson('/api/WatchLaterMovies'),
        _getJson('/api/WatchedMovies'),
        _getJson('/api/MovieLists'),
      ]);

      _profile = UserProfile.fromJson(results[0] as Map<String, dynamic>);
      _favorites = _parseJsonList(
        results[1],
      ).map(FavoriteMovieEntry.fromJson).toList();
      _watchLaterMovies = _parseJsonList(
        results[2],
      ).map(WatchLaterMovieEntry.fromJson).toList();
      _watchedMovies = _parseJsonList(
        results[3],
      ).map(WatchedMovieEntry.fromJson).toList();
      _movieLists = _parseJsonList(
        results[4],
      ).map(UserMovieList.fromJson).toList();
    } catch (e) {
      _errorMessage = 'Unable to load profile data: $e';
      rethrow;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<UserProfile> updatePseudo(String pseudo) async {
    final payload = await _sendJson(
      'PUT',
      '/api/Users/me',
      body: {'pseudo': pseudo.trim()},
    );
    final profile = UserProfile.fromJson(payload as Map<String, dynamic>);
    _profile = profile;
    notifyListeners();
    return profile;
  }

  Future<void> addFavorite(Movie movie) async {
    await _sendJson('POST', '/api/FavoriteMovies', body: _moviePayload(movie));
    await Future.wait([refreshFavorites(), refreshWatchedMovies(), refreshWatchLaterMovies()]);
  }

  Future<void> removeFavorite(Movie movie) async {
    await _send('DELETE', '/api/FavoriteMovies/${movie.id}');
    _favorites = _favorites.where((fav) => fav.movie.id != movie.id).toList();
    notifyListeners();
  }

  Future<void> addToWatchLater(Movie movie) async {
    await _sendJson('POST', '/api/WatchLaterMovies', body: _moviePayload(movie));
    await refreshWatchLaterMovies();
  }

  Future<void> removeFromWatchLater(Movie movie) async {
    await _send('DELETE', '/api/WatchLaterMovies/${movie.id}');
    _watchLaterMovies = _watchLaterMovies
        .where((watchLater) => watchLater.movie.id != movie.id)
        .toList();
    notifyListeners();
  }

  Future<void> markWatched(
    Movie movie, {
    int? rating,
  }) async {
    await _sendJson('POST', '/api/WatchedMovies', body: {
      ..._moviePayload(movie),
      'rating': rating
      }
    );
    await Future.wait([refreshWatchedMovies(), refreshWatchLaterMovies()]);
  }

  Future<void> removeWatchedMovie(Movie movie) async {
    await _send('DELETE', '/api/WatchedMovies/${movie.id}');
    _watchedMovies = _watchedMovies.where((watched) => watched.movie.id != movie.id).toList();
    notifyListeners();
    await Future.wait([refreshFavorites(), refreshWatchLaterMovies()]);
  }

  Future<void> createMovieList({
    required String name,
    required String description,
  }) async {
    await _sendJson(
      'POST',
      '/api/MovieLists',
      body: {'name': name.trim(), 'description': description.trim()},
    );
    await refreshMovieLists();
  }

  Future<void> deleteMovieList(int id) async {
    await _send('DELETE', '/api/MovieLists/$id');
    _movieLists = _movieLists.where((list) => list.id != id).toList();
    notifyListeners();
  }

  Future<void> addMovieToList(int listId, Movie movie) async {
    await _sendJson(
      'POST',
      '/api/MovieLists/$listId/movies',
      body: _moviePayload(movie),
    );
    await refreshMovieLists();
  }

  Future<void> removeMovieFromList(int listId, int itemId) async {
    await _send('DELETE', '/api/MovieLists/$listId/movies/$itemId');
    await refreshMovieLists();
  }

  bool isFavorite(Movie movie) {
    return _favorites.any((favorite) => favorite.movie.id == movie.id);
  }

  bool isWatched(Movie movie) {
    return _watchedMovies.any((watched) => watched.movie.id == movie.id);
  }

  bool isInWatchLater(Movie movie) {
    return _watchLaterMovies.any(
      (watchLater) => watchLater.movie.id == movie.id,
    );
  }

  Future<void> refreshFavorites() async {
    final payload = await _getJson('/api/FavoriteMovies');
    _favorites = _parseJsonList(
      payload,
    ).map(FavoriteMovieEntry.fromJson).toList();
    notifyListeners();
  }

  Future<void> refreshWatchedMovies() async {
    final payload = await _getJson('/api/WatchedMovies');
    _watchedMovies = _parseJsonList(
      payload,
    ).map(WatchedMovieEntry.fromJson).toList();
    notifyListeners();
  }

  Future<void> refreshWatchLaterMovies() async {
    final payload = await _getJson('/api/WatchLaterMovies');
    _watchLaterMovies = _parseJsonList(
      payload,
    ).map(WatchLaterMovieEntry.fromJson).toList();
    notifyListeners();
  }

  Future<void> refreshMovieLists() async {
    final payload = await _getJson('/api/MovieLists');
    _movieLists = _parseJsonList(payload).map(UserMovieList.fromJson).toList();
    notifyListeners();
  }

  List<Movie> _parseMovieResults(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final results = payload['results'] as List<dynamic>? ?? const [];
      return results
          .whereType<Map<String, dynamic>>()
          .map(Movie.fromJson)
          .toList();
    }
    throw const FormatException('Expected movie search results payload.');
  }

  List<Map<String, dynamic>> _parseJsonList(dynamic payload) {
    if (payload is List<dynamic>) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }
    throw const FormatException('Expected JSON array payload.');
  }

  Map<String, dynamic> _moviePayload(Movie movie) {
    return {
      'movieId': movie.id,
    };
  }

  Future<dynamic> _getJson(String path) async {
    final response = await _send('GET', path);
    return _decodeJson(response.body);
  }

  Future<dynamic> _sendJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(method, path, body: body);
    if (response.body.trim().isEmpty) {
      return null;
    }
    return _decodeJson(response.body);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _loginService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing access token.');
    }

    final uri = Uri.parse('$_baseUrl$path');
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }
    return response;
  }

  dynamic _decodeJson(String body) {
    return jsonDecode(body);
  }

  String _extractErrorMessage(http.Response response) {
    if (response.body.trim().isEmpty) {
      return 'HTTP ${response.statusCode}';
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['title'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      return response.body;
    }

    return response.body;
  }
}
