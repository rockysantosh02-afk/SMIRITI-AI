import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../models/voice_intent.dart';
import 'voice_intent_matcher.dart';
import '../../../core/localization/app_languages.dart';

/// Voice assistant status states.
enum VoiceAssistantStatus {
  idle,
  listening,
  processing,
  success,
  notUnderstood,
  permissionDenied,
  unavailable,
  error,
}

/// Abstract contract for Voice Service to allow safe testability and mocking.
abstract class IVoiceService {
  VoiceAssistantStatus get status;
  bool get isListening;
  String get lastRecognizedWords;
  VoiceIntentResult? get lastIntentResult;
  List<stt.LocaleName> get availableLocales;

  Future<bool> initialize();
  Future<void> startListening({
    required ValueChanged<String> onResult,
    VoidCallback? onComplete,
    String? languageCode,
  });
  Future<void> stopListening();
  Future<void> cancelListening();
  void dispose();
}

/// Production implementation of [IVoiceService] wrapping [stt.SpeechToText].
///
/// Strict Privacy & Technical Guarantees:
/// - **Smriti AI application boundary**: Smriti AI does not record, save, or upload raw microphone audio.
/// - **Push-to-talk only**: Activates only upon explicit user button tap.
/// - **No wake words, no background recording**: Microphone is inactive until user interaction.
/// - **Device-delegated speech recognition**: Speech-to-text conversion is handled by the device's native speech recognition service; whether it functions offline depends on the device and installed language packs.
/// - **Local intent matching**: All intent matching from recognized text is executed 100% locally on device without network or external LLM calls.
class VoiceService with ChangeNotifier implements IVoiceService {
  final stt.SpeechToText _speech;
  final VoiceIntentMatcher _matcher;

  VoiceAssistantStatus _status = VoiceAssistantStatus.idle;
  String _lastRecognizedWords = '';
  VoiceIntentResult? _lastIntentResult;
  List<stt.LocaleName> _availableLocales = [];
  bool _isInitialized = false;

  ValueChanged<String>? _activeResultCallback;
  VoidCallback? _activeCompleteCallback;
  String _currentLanguageCode = 'en';

  VoiceService({
    stt.SpeechToText? speechToText,
    VoiceIntentMatcher? matcher,
  })  : _speech = speechToText ?? stt.SpeechToText(),
        _matcher = matcher ?? const VoiceIntentMatcher();

  @override
  VoiceAssistantStatus get status => _status;

  @override
  bool get isListening => _status == VoiceAssistantStatus.listening;

  @override
  String get lastRecognizedWords => _lastRecognizedWords;

  @override
  VoiceIntentResult? get lastIntentResult => _lastIntentResult;

  @override
  List<stt.LocaleName> get availableLocales => List.unmodifiable(_availableLocales);

  /// Initialize the underlying speech recognition engine and discover available locales.
  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: kDebugMode,
      );

      if (available) {
        try {
          _availableLocales = await _speech.locales();
          debugPrint(
            '[VoiceService] Discovered ${_availableLocales.length} speech recognition locales',
          );
        } catch (e) {
          debugPrint('[VoiceService] Could not fetch locales list: $e');
        }
        _isInitialized = true;
        _setStatus(VoiceAssistantStatus.idle);
        return true;
      } else {
        debugPrint('[VoiceService] Speech recognition unavailable or permission denied');
        _setStatus(VoiceAssistantStatus.unavailable);
        return false;
      }
    } catch (e) {
      debugPrint('[VoiceService] Exception during initialization: $e');
      _setStatus(VoiceAssistantStatus.unavailable);
      return false;
    }
  }

  /// Start push-to-talk speech recognition.
  ///
  /// Requires explicit user button tap. Will automatically stop when speech completes,
  /// or when [stopListening] is tapped by the user.
  @override
  Future<void> startListening({
    required ValueChanged<String> onResult,
    VoidCallback? onComplete,
    String? languageCode,
  }) async {
    // Prevent duplicate concurrent listening sessions
    if (_status == VoiceAssistantStatus.listening) {
      debugPrint('[VoiceService] Already listening. Ignoring duplicate start request.');
      return;
    }

    _activeResultCallback = onResult;
    _activeCompleteCallback = onComplete;
    _currentLanguageCode = languageCode ?? 'en';
    _lastRecognizedWords = '';
    _lastIntentResult = null;

    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    final targetLocaleId = _resolveLocaleId(_currentLanguageCode);

    _setStatus(VoiceAssistantStatus.listening);

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastRecognizedWords = result.recognizedWords;
          _activeResultCallback?.call(_lastRecognizedWords);
          notifyListeners();

          if (result.finalResult) {
            _finalizeRecognition(_lastRecognizedWords);
          }
        },
        localeId: targetLocaleId,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('[VoiceService] Error while starting listen: $e');
      _setStatus(VoiceAssistantStatus.error);
    }
  }

  /// Explicitly stop listening and process whatever words were captured.
  @override
  Future<void> stopListening() async {
    if (_status != VoiceAssistantStatus.listening) return;

    _setStatus(VoiceAssistantStatus.processing);
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('[VoiceService] Error during stop: $e');
    }

    _finalizeRecognition(_lastRecognizedWords);
  }

  /// Cancel speech recognition and discard recognized text without taking action.
  @override
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('[VoiceService] Error during cancel: $e');
    }
    _lastRecognizedWords = '';
    _lastIntentResult = null;
    _setStatus(VoiceAssistantStatus.idle);
  }

  /// Resolve the best available device locale for the requested language code.
  String? _resolveLocaleId(String langCode) {
    if (_availableLocales.isEmpty) return null;

    final appLang = AppLanguages.fromCode(langCode);
    final candidates = [
      ...appLang.sttLocales,
      // If the selected language is not English, include English as fallback
      if (appLang != AppLanguage.english) ...AppLanguage.english.sttLocales,
    ];

    for (final candidate in candidates) {
      for (final locale in _availableLocales) {
        if (locale.localeId.toLowerCase().replaceAll('-', '_') ==
            candidate.toLowerCase().replaceAll('-', '_')) {
          return locale.localeId;
        }
      }
    }

    // Default to the first available or null (system default)
    return null;
  }

  void _finalizeRecognition(String words) {
    if (_status == VoiceAssistantStatus.success ||
        _status == VoiceAssistantStatus.notUnderstood) {
      return; // Already finalized
    }

    _setStatus(VoiceAssistantStatus.processing);

    final clean = VoiceIntentMatcher.normalizeText(words);
    if (clean.isEmpty) {
      _setStatus(VoiceAssistantStatus.notUnderstood);
      _activeCompleteCallback?.call();
      return;
    }

    final matchResult = _matcher.match(words, languageCode: _currentLanguageCode);
    _lastIntentResult = matchResult;

    if (matchResult.intent == VoiceIntent.unknown) {
      _setStatus(VoiceAssistantStatus.notUnderstood);
    } else {
      _setStatus(VoiceAssistantStatus.success);
    }

    _activeCompleteCallback?.call();
  }

  void _handleStatus(String status) {
    debugPrint('[VoiceService] SpeechToText status: $status');
    if (status == 'notListening' || status == 'done') {
      if (_status == VoiceAssistantStatus.listening) {
        _finalizeRecognition(_lastRecognizedWords);
      }
    }
  }

  void _handleError(SpeechRecognitionError errorNotification) {
    debugPrint(
      '[VoiceService] SpeechToText error: ${errorNotification.errorMsg} (permanent: ${errorNotification.permanent})',
    );

    if (errorNotification.errorMsg.contains('error_permission') ||
        errorNotification.errorMsg.contains('permission')) {
      _setStatus(VoiceAssistantStatus.permissionDenied);
    } else if (errorNotification.errorMsg.contains('error_no_match') ||
        errorNotification.errorMsg.contains('no match')) {
      _setStatus(VoiceAssistantStatus.notUnderstood);
    } else {
      _setStatus(VoiceAssistantStatus.error);
    }
  }

  void _setStatus(VoiceAssistantStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _activeResultCallback = null;
    _activeCompleteCallback = null;
    _speech.cancel();
    super.dispose();
  }
}
