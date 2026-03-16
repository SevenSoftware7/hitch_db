import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hitch_db/app_config.dart';

class LoginService {
  LoginService({
    String? baseUrl,
    this.loginPath = '/api/Auth/login',
    this.registerPath = '/api/Auth/register',
    http.Client? client,
  }) : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
       _client = client ?? http.Client();

  final String _baseUrl;
  final String loginPath;
  final String registerPath;
  final http.Client _client;

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userIdKey = 'auth_user_id';

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      path: loginPath,
      email: email,
      password: password,
      failureFallbackMessage: 'Login failed.',
      missingTokenMessage: 'Login response did not include an access token.',
    );
  }

  Future<LoginResult> register({
    required String email,
    required String password,
  }) async {
    return _authenticate(
      path: registerPath,
      email: email,
      password: password,
      failureFallbackMessage: 'Registration failed.',
      missingTokenMessage: 'Register response did not include an access token.',
    );
  }

  Future<bool> deleteAccount({required String password}) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No access token found for account deletion.');
    }

    if (password.trim().isEmpty) {
      throw Exception('Password is required for account deletion.');
    }

    final uri = Uri.parse('$_baseUrl/api/Auth/delete-account');
    http.Response response;
    try {
      response = await _client.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );
    } catch (e) {
      throw Exception('Account deletion request to $uri failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(
        response.body,
        fallbackMessage: 'Account deletion failed.',
      );
      throw Exception(errorMessage);
    }

    await logout();
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No access token found for password update.');
    }

    final uri = Uri.parse('$_baseUrl/api/Users/me/password');
    http.Response response;
    try {
      response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
    } catch (e) {
      throw Exception('Password update request to $uri failed: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(
        response.body,
        fallbackMessage: 'Password update failed.',
      );
      throw Exception(errorMessage);
    }

    return true;
  }

  Future<LoginResult> _authenticate({
    required String path,
    required String email,
    required String password,
    required String failureFallbackMessage,
    required String missingTokenMessage,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');

    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (e) {
      return LoginResult(
        isSuccess: false,
        message: 'Authentication request to $uri failed: $e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return LoginResult(
        isSuccess: false,
        statusCode: response.statusCode,
        message: _extractErrorMessage(
          response.body,
          fallbackMessage: failureFallbackMessage,
        ),
      );
    }

    final payload = _decodeObject(response.body);
    final accessToken = _extractToken(payload);
    if (accessToken == null || accessToken.isEmpty) {
      return LoginResult(isSuccess: false, message: missingTokenMessage);
    }

    if (JwtDecoder.isExpired(accessToken)) {
      return const LoginResult(
        isSuccess: false,
        message: 'Received an already expired token.',
      );
    }

    final refreshToken = _extractRefreshToken(payload);
    final userId = _extractUserId(accessToken);

    await _saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );

    return LoginResult(
      isSuccess: true,
      statusCode: response.statusCode,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    if (JwtDecoder.isExpired(token)) {
      await logout();
      return false;
    }

    return true;
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<Map<String, dynamic>?> getAccessTokenClaims() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    if (JwtDecoder.isExpired(token)) {
      return null;
    }

    return JwtDecoder.decode(token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
  }

  Future<void> _saveSession({
    required String accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_refreshTokenKey);
    }

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    } else {
      await prefs.remove(_userIdKey);
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected JSON object in response body.');
  }

  String? _extractToken(Map<String, dynamic> payload) {
    final value = payload['accessToken'] ?? payload['token'] ?? payload['jwt'];
    if (value is String) {
      return value;
    }
    return null;
  }

  String? _extractRefreshToken(Map<String, dynamic> payload) {
    final value = payload['refreshToken'] ?? payload['refresh_token'];
    if (value is String) {
      return value;
    }
    return null;
  }

  String? _extractUserId(String accessToken) {
    final claims = JwtDecoder.decode(accessToken);
    final value = claims['sub'] ?? claims['userId'] ?? claims['id'];
    if (value is String) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }

  String _extractErrorMessage(String body, {required String fallbackMessage}) {
    if (body.trim().isEmpty) {
      return fallbackMessage;
    }

    try {
      final payload = _decodeObject(body);
      final message = payload['message'] ?? payload['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      return fallbackMessage;
    } catch (_) {
      return body;
    }
  }
}

class LoginResult {
  const LoginResult({
    required this.isSuccess,
    this.statusCode,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.userId,
  });

  final bool isSuccess;
  final int? statusCode;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
}
