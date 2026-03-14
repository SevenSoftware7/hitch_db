import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginService {
	LoginService({
		required String baseUrl,
		this.loginPath = '/auth/login',
		http.Client? client,
	})  : _baseUrl = baseUrl,
				_client = client ?? http.Client();

	final String _baseUrl;
	final String loginPath;
	final http.Client _client;

	static const String _accessTokenKey = 'auth_access_token';
	static const String _refreshTokenKey = 'auth_refresh_token';
	static const String _userIdKey = 'auth_user_id';

	Future<LoginResult> login({
		required String email,
		required String password,
	}) async {
		final uri = Uri.parse('$_baseUrl$loginPath');
		final response = await _client.post(
			uri,
			headers: {'Content-Type': 'application/json'},
			body: jsonEncode({
				'email': email,
				'password': password,
			}),
		);

		if (response.statusCode < 200 || response.statusCode >= 300) {
			return LoginResult(
				isSuccess: false,
				statusCode: response.statusCode,
				message: _extractErrorMessage(response.body),
			);
		}

		final payload = _decodeObject(response.body);
		final accessToken = _extractToken(payload);
		if (accessToken == null || accessToken.isEmpty) {
			return const LoginResult(
				isSuccess: false,
				message: 'Login response did not include an access token.',
			);
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

	String _extractErrorMessage(String body) {
		try {
			final payload = _decodeObject(body);
			final message = payload['message'] ?? payload['error'];
			if (message is String && message.isNotEmpty) {
				return message;
			}
			return 'Login failed.';
		} catch (_) {
			return 'Login failed.';
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
