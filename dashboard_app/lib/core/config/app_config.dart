import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized application configuration for SMIRITI-AI.
class AppConfig {
  AppConfig._();

  /// Current environment name: development, staging, production.
  static String get environment =>
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  /// Whether the app is running in production mode.
  static bool get isProduction => environment == 'production';

  /// Centralized API Base URL for backend communication.
  ///
  /// Evaluation priority:
  /// 1. `--dart-define=API_BASE_URL=...` (Production builds / CI)
  /// 2. `.env` file (`API_BASE_URL`) if initialized
  /// 3. Platform default fallback:
  ///    - Android emulator: `http://10.0.2.2:8000`
  ///    - iOS Simulator / Web / Desktop: `http://127.0.0.1:8000`
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return _normalizeUrl(fromDefine);
    }

    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['API_BASE_URL'];
      if (fromEnv != null && fromEnv.trim().isNotEmpty) {
        return _normalizeUrl(fromEnv.trim());
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static String _normalizeUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
