import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) {
      return _configuredApiBaseUrl;
    }

    final envApiBaseUrl = _tryGetEnv('API_BASE_URL');
    if (envApiBaseUrl.isNotEmpty) {
      return envApiBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5264';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5264';
      case TargetPlatform.iOS:
        return 'http://localhost:5264';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'http://localhost:5264';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5264';
    }
  }

  static String? get tmdbApiKey {
    final key = _tryGetEnv('TMDB_API_KEY');
    if (key.isEmpty) {
      return null;
    }
    return key;
  }

  static String _tryGetEnv(String key) {
    try {
      return dotenv.maybeGet(key)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}
