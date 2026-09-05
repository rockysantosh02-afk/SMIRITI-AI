import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Contract for Text-to-Speech operations in Smriti AI.
abstract class ITtsService {
  Future<bool> isLanguageAvailable(String languageCode);
  Future<void> speak(String text, {String? languageCode});
  Future<void> stop();
  void dispose();
}

/// Production implementation of [ITtsService] using [FlutterTts].
///
/// Designed with elderly-accessible voice characteristics:
/// - Moderate, calm speech rate (~0.45-0.5)
/// - Natural pitch and clear volume
/// - Defensive language availability detection with graceful fallback to English
/// - Zero unhandled exceptions
class TtsService implements ITtsService {
  final FlutterTts _flutterTts;
  bool _isInitialized = false;
  List<dynamic> _availableLanguages = [];

  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts();

  /// Initialize TTS engine, configure elderly-friendly parameters, and cache available languages.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio attributes
      await _flutterTts.setSpeechRate(0.46); // Calm, easily intelligible tempo
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // On Android, set engine audio focus mode
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts.setSilence(150);
      }

      // Query available engine languages
      try {
        final languages = await _flutterTts.getLanguages;
        if (languages is List) {
          _availableLanguages = languages;
          debugPrint(
            '[TtsService] Discovered ${_availableLanguages.length} available TTS languages',
          );
        }
      } catch (e) {
        debugPrint('[TtsService] Could not query TTS languages: $e');
      }

      _flutterTts.setErrorHandler((msg) {
        debugPrint('[TtsService] FlutterTts error event: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TtsService] Exception during TTS initialization: $e');
    }
  }

  /// Check if the device engine supports the specified language locale.
  @override
  Future<bool> isLanguageAvailable(String languageCode) async {
    if (!_isInitialized) await initialize();

    try {
      final res = await _flutterTts.isLanguageAvailable(languageCode);
      if (res == 1 || res == true) return true;

      // Also check against cached languages list
      final clean = languageCode.toLowerCase().replaceAll('_', '-');
      for (final l in _availableLanguages) {
        final cand = l.toString().toLowerCase().replaceAll('_', '-');
        if (cand == clean || cand.startsWith(clean)) return true;
      }
      return false;
    } catch (e) {
      debugPrint('[TtsService] Exception in isLanguageAvailable: $e');
      return false;
    }
  }

  /// Speak the provided [text] in the requested [languageCode] (or fallback to en-US).
  @override
  Future<void> speak(String text, {String? languageCode}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    if (!_isInitialized) await initialize();

    final targetLocale = languageCode ?? 'en-US';
    String resolvedLocale = targetLocale;

    try {
      // 1. Check if the target locale is supported on the physical device
      final available = await isLanguageAvailable(targetLocale);
      if (!available) {
        debugPrint(
          '[TtsService] Voice locale "$targetLocale" is unavailable on this device.',
        );

        // Try short 2-letter code if region tag was used (e.g. 'te' for 'te-IN')
        final shortCode = targetLocale.split(RegExp(r'[-_]')).first;
        final shortAvailable = await isLanguageAvailable(shortCode);

        if (shortAvailable) {
          resolvedLocale = shortCode;
          debugPrint(
            '[TtsService] Found compatible regional voice fallback: "$shortCode"',
          );
        } else {
          // Graceful fallback to English
          resolvedLocale = 'en-US';
          debugPrint(
            '[TtsService] Falling back to default English voice "en-US".',
          );
        }
      }

      // 2. Cease any ongoing speech before beginning
      await _flutterTts.stop();

      // 3. Set resolved language
      await _flutterTts.setLanguage(resolvedLocale);

      // 4. Speak text
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('[TtsService] Error speaking text: $e');
    }
  }

  /// Stop any currently active speech.
  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('[TtsService] Error stopping speech: $e');
    }
  }

  @override
  void dispose() {
    stop();
  }
}
