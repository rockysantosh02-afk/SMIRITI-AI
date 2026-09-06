import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Contract for Text-to-Speech operations in Smriti AI.
abstract class ITtsService {
  bool get isSpeaking;
  Future<void> initialize();
  Future<bool> isLanguageAvailable(String languageCode);
  Future<void> speak(String text, {String? languageCode, VoidCallback? onComplete});
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
/// - Safe Android engine binding and awaitSpeakCompletion support
class TtsService implements ITtsService {
  final FlutterTts _flutterTts;
  bool _isInitialized = false;
  Future<void>? _initFuture;
  bool _isSpeaking = false;
  String? _currentlySpeakingText;
  Completer<void>? _activeSpeakCompleter;
  VoidCallback? _pendingCompleteCallback;
  List<dynamic> _availableLanguages = [];

  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts();

  @override
  bool get isSpeaking => _isSpeaking;

  /// Initialize TTS engine once safely, preventing concurrent re-initialization races.
  @override
  Future<void> initialize() {
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('[TTS] Initializing TextToSpeech service...');

      // On Android, enable awaitSpeakCompletion and flush queue mode for reliable audio playback
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _flutterTts.awaitSpeakCompletion(true);
          await _flutterTts.setQueueMode(0); // 0 = QUEUE_FLUSH
        } catch (e) {
          debugPrint('[TTS] Note: awaitSpeakCompletion/setQueueMode setup: $e');
        }
      }

      // Configure elderly-friendly audio attributes
      await _flutterTts.setSpeechRate(0.46); // Calm, easily intelligible tempo
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Lifecycle handlers
      _flutterTts.setStartHandler(() {
        debugPrint('[TTS] Speech started');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('[TTS] Speech completed');
        _isSpeaking = false;
        _currentlySpeakingText = null;
        _notifyComplete();
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('[TTS] Speech cancelled');
        _isSpeaking = false;
        _currentlySpeakingText = null;
        _notifyComplete();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('[TTS] Error event from native engine: $msg');
        _isSpeaking = false;
        _currentlySpeakingText = null;
        _notifyComplete();
      });

      // Query available engine languages
      try {
        final languages = await _flutterTts.getLanguages;
        if (languages is List) {
          _availableLanguages = languages;
          debugPrint('[TTS] Discovered ${_availableLanguages.length} available TTS languages');
        }
      } catch (e) {
        debugPrint('[TTS] Could not query TTS languages: $e');
      }

      _isInitialized = true;
      debugPrint('[TTS] TextToSpeech service initialized successfully');
    } catch (e) {
      debugPrint('[TTS] Exception during TTS initialization: $e');
      _isInitialized = false;
      _initFuture = null; // Allow retry on subsequent calls if initialization failed
    }
  }

  void _notifyComplete() {
    final cb = _pendingCompleteCallback;
    _pendingCompleteCallback = null;
    if (_activeSpeakCompleter != null && !_activeSpeakCompleter!.isCompleted) {
      _activeSpeakCompleter!.complete();
    }
    cb?.call();
  }

  /// Check if the device engine supports the specified language locale.
  @override
  Future<bool> isLanguageAvailable(String languageCode) async {
    await initialize();

    try {
      final res = await _flutterTts.isLanguageAvailable(languageCode);
      debugPrint('[TTS] isLanguageAvailable("$languageCode") native result: $res');

      // Native Android TextToSpeech codes:
      // LANG_AVAILABLE = 0, LANG_COUNTRY_AVAILABLE = 1, LANG_COUNTRY_VAR_AVAILABLE = 2.
      // LANG_MISSING_DATA = -1, LANG_NOT_SUPPORTED = -2.
      // Boolean true or integer >= 0 indicates support.
      if (res == true || (res is num && res >= 0)) {
        return true;
      }

      // Also check against cached languages list
      final clean = languageCode.toLowerCase().replaceAll('_', '-');
      final langPrefix = clean.split('-').first;
      for (final l in _availableLanguages) {
        final cand = l.toString().toLowerCase().replaceAll('_', '-');
        if (cand == clean || cand == langPrefix || cand.startsWith('$langPrefix-')) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[TTS] Exception in isLanguageAvailable: $e');
      return false;
    }
  }

  /// Speak the provided [text] in the requested [languageCode] (or fallback to en-US).
  @override
  Future<void> speak(String text, {String? languageCode, VoidCallback? onComplete}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      onComplete?.call();
      return;
    }

    await initialize();

    // Prevent duplicate speech of the exact same utterance while it is currently speaking
    if (_isSpeaking && _currentlySpeakingText == cleanText) {
      debugPrint('[TTS] Ignoring duplicate speech request for active utterance: "$cleanText"');
      return;
    }

    final targetLocale = languageCode ?? 'en-US';
    String resolvedLocale = targetLocale;

    try {
      // 1. Check if the target locale is supported on the physical device
      final available = await isLanguageAvailable(targetLocale);
      if (!available) {
        debugPrint('[TTS] Voice locale "$targetLocale" is unavailable on this device.');

        // Try short 2-letter code if region tag was used (e.g. 'te' for 'te-IN')
        final shortCode = targetLocale.split(RegExp(r'[-_]')).first;
        final shortAvailable = await isLanguageAvailable(shortCode);

        if (shortAvailable) {
          resolvedLocale = shortCode;
          debugPrint('[TTS] Found compatible regional voice fallback: "$shortCode"');
        } else {
          resolvedLocale = 'en-US';
          debugPrint('[TTS] Falling back to default English voice "en-US".');
        }
      }

      // 2. Set resolved language
      await _flutterTts.setLanguage(resolvedLocale);

      // 3. Set up awaitable completion mechanism
      if (_activeSpeakCompleter != null && !_activeSpeakCompleter!.isCompleted) {
        _activeSpeakCompleter!.complete();
      }
      final completer = Completer<void>();
      _activeSpeakCompleter = completer;
      _pendingCompleteCallback = onComplete;
      _isSpeaking = true;
      _currentlySpeakingText = cleanText;

      // In headless test environments, complete immediately as no native audio hardware runs
      if (const bool.fromEnvironment('flutter.test') ||
          (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
        _isSpeaking = false;
        _currentlySpeakingText = null;
        _notifyComplete();
        return;
      }

      // 4. Speak text via FlutterTts
      final result = await _flutterTts.speak(cleanText);
      debugPrint('[TTS] FlutterTts.speak initiated (result: $result, locale: $resolvedLocale)');

      // If speak returned 0 (failure), notify completion immediately rather than hanging
      if (result == 0) {
        debugPrint('[TTS] Native speech dispatch failed');
        _isSpeaking = false;
        _currentlySpeakingText = null;
        _notifyComplete();
        return;
      }

      // 5. Wait for speaking operation to actually complete or time out safely
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[TTS] Speech operation timed out after 15s');
          _isSpeaking = false;
          _currentlySpeakingText = null;
          _notifyComplete();
        },
      );
    } catch (e) {
      debugPrint('[TTS] Error speaking text: $e');
      _isSpeaking = false;
      _currentlySpeakingText = null;
      _notifyComplete();
    } finally {
      _currentlySpeakingText = null;
    }
  }

  /// Stop any currently active speech.
  @override
  Future<void> stop() async {
    _isSpeaking = false;
    _currentlySpeakingText = null;
    _notifyComplete();
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('[TTS] Error stopping speech: $e');
    }
  }

  @override
  void dispose() {
    stop();
  }
}
