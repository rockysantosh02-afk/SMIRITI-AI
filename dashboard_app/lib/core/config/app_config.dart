import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized application configuration for SMIRITI-AI.
class AppConfig {
  AppConfig._();

  /// Current environment name: development, staging, production.
  static String get environment =>
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  /// Whether the app is running in production mode.
  static bool get isProduction => environment == 'production';

  /// Centralized production API Base URL for deployed Render backend.
  static const String productionApiBaseUrl = 'https://smiriti-ai.onrender.com';

  /// Centralized API Base URL for backend communication.
  ///
  /// Priority:
  /// 1. `--dart-define=API_BASE_URL=...` (CI / custom build overrides)
  /// 2. `.env` file (`API_BASE_URL`) if set to a valid non-localhost URL
  /// 3. Default production URL: `https://smiriti-ai.onrender.com`
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return _normalizeUrl(fromDefine);
    }

    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['API_BASE_URL'];
      if (fromEnv != null && fromEnv.trim().isNotEmpty) {
        final trimmed = fromEnv.trim();
        // Never use obsolete localhost/emulator stubs in production builds
        if (!trimmed.contains('localhost') &&
            !trimmed.contains('127.0.0.1') &&
            !trimmed.contains('10.0.2.2')) {
          return _normalizeUrl(trimmed);
        }
      }
    }

    return productionApiBaseUrl;
  }

  static String _normalizeUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
