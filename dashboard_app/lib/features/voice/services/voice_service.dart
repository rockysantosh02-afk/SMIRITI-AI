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
  bool isLanguageSupported(String langCode) => true;
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
  String _activeSessionId = '';
  int _sessionCounter = 0;
  Completer<String>? _finalResultCompleter;
  bool _isSessionFinalized = false;
  bool _isDisposed = false;

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

  /// Current active listening session token for race-condition protection.
  String get activeSessionId => _activeSessionId;

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
            '[STT] Discovered ${_availableLocales.length} speech recognition locales',
          );
        } catch (e) {
          debugPrint('[STT] Could not fetch locales list: $e');
        }
        _isInitialized = true;
        _setStatus(VoiceAssistantStatus.idle);
        return true;
      } else {
        debugPrint('[STT] Speech recognition unavailable or permission denied');
        _setStatus(VoiceAssistantStatus.unavailable);
        return false;
      }
    } catch (e) {
      debugPrint('[STT] Exception during initialization: $e');
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
      debugPrint('[STT] Already listening. Ignoring duplicate start request.');
      return;
    }

    _sessionCounter++;
    final sessionToken = 'session_${_sessionCounter}_${DateTime.now().millisecondsSinceEpoch}';
    _activeSessionId = sessionToken;
    _isSessionFinalized = false;
    _finalResultCompleter = Completer<String>();

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
          // Stale callback guard: discard results if session has changed
          if (_activeSessionId != sessionToken) {
            debugPrint('[STT] Ignoring speech result from stale session $sessionToken');
            return;
          }

          _lastRecognizedWords = result.recognizedWords;
          _activeResultCallback?.call(_lastRecognizedWords);
          notifyListeners();

          if (result.finalResult) {
            if (!(_finalResultCompleter?.isCompleted ?? true)) {
              _finalResultCompleter?.complete(_lastRecognizedWords);
            }
            _finalizeRecognition(_lastRecognizedWords, sessionToken: sessionToken);
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
      debugPrint('[STT] Error while starting listen: $e');
      _setStatus(VoiceAssistantStatus.error);
    }
  }

  /// Explicitly stop listening and process whatever words were captured.
  @override
  Future<void> stopListening() async {
    if (_status != VoiceAssistantStatus.listening) return;

    final sessionToken = _activeSessionId;
    _setStatus(VoiceAssistantStatus.processing);
    try {
      await _speech.stop();
      // Safely wait for native recognizer to deliver final result before processing
      if (!(_finalResultCompleter?.isCompleted ?? true)) {
        await _finalResultCompleter?.future.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => _lastRecognizedWords,
        );
      }
    } catch (e) {
      debugPrint('[STT] Error during stop: $e');
    }

    _finalizeRecognition(_lastRecognizedWords, sessionToken: sessionToken);
  }

  /// Cancel speech recognition and discard recognized text without taking action.
  @override
  Future<void> cancelListening() async {
    _activeSessionId = '';
    _isSessionFinalized = true;
    if (!(_finalResultCompleter?.isCompleted ?? true)) {
      _finalResultCompleter?.complete('');
    }
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('[STT] Error during cancel: $e');
    }
    _lastRecognizedWords = '';
    _lastIntentResult = null;
    _setStatus(VoiceAssistantStatus.idle);
  }

  /// Normalize a locale tag for robust comparison: lowercase with hyphens and underscores removed.
  /// E.g. "te-IN" -> "tein", "te_IN" -> "tein", "te" -> "te".
  static String normalizeLocaleTag(String tag) {
    return tag.toLowerCase().replaceAll('-', '').replaceAll('_', '').trim();
  }

  /// Check whether the requested language is supported by available device speech recognition locales.
  @override
  bool isLanguageSupported(String langCode) {
    if (_availableLocales.isEmpty) {
      // When availableLocales is empty (e.g. initialization in progress or simulator),
      // do not falsely block user interaction.
      return true;
    }
    return _findMatchingLocaleId(langCode, allowEnglishFallback: false) != null;
  }

  /// Public locale resolver for testing and diagnostics.
  String? resolveLocaleId(String langCode, {bool allowEnglishFallback = true}) {
    return _findMatchingLocaleId(langCode, allowEnglishFallback: allowEnglishFallback);
  }

  /// Internal robust locale matcher supporting exact normalized matching,
  /// prefix matching (e.g., 'te' matches 'te-IN'), and controlled English fallback.
  String? _findMatchingLocaleId(String langCode, {bool allowEnglishFallback = true}) {
    if (_availableLocales.isEmpty) return null;

    final appLang = AppLanguages.fromCode(langCode);
    final targetCandidates = appLang.sttLocales;

    // 1. Exact normalized match against target candidates (e.g. 'te_IN' matches 'te-IN')
    for (final candidate in targetCandidates) {
      final normCand = normalizeLocaleTag(candidate);
      for (final locale in _availableLocales) {
        if (normalizeLocaleTag(locale.localeId) == normCand) {
          return locale.localeId;
        }
      }
    }

    // 2. Prefix matching on base language (e.g. 'te' matches 'te-IN' or 'te_IN')
    final langPrefix = normalizeLocaleTag(langCode.split(RegExp(r'[-_]')).first);
    for (final locale in _availableLocales) {
      final normLoc = normalizeLocaleTag(locale.localeId);
      if (normLoc == langPrefix || normLoc.startsWith(langPrefix)) {
        return locale.localeId;
      }
    }

    // 3. Fallback to English candidates only if explicitly allowed
    if (allowEnglishFallback && appLang != AppLanguage.english) {
      for (final candidate in AppLanguage.english.sttLocales) {
        final normCand = normalizeLocaleTag(candidate);
        for (final locale in _availableLocales) {
          if (normalizeLocaleTag(locale.localeId) == normCand) {
            return locale.localeId;
          }
        }
      }
    }

    return null;
  }

  String? _resolveLocaleId(String langCode) {
    return _findMatchingLocaleId(langCode, allowEnglishFallback: true);
  }

  void _finalizeRecognition(String words, {String? sessionToken}) {
    if (sessionToken != null && sessionToken != _activeSessionId) {
      debugPrint('[STT] Ignoring finalize from stale session $sessionToken');
      return;
    }

    if (_isSessionFinalized) {
      return; // Already finalized
    }
    _isSessionFinalized = true;

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
    debugPrint('[STT] SpeechToText status: $status');
    if (status == 'notListening' || status == 'done') {
      if (_status == VoiceAssistantStatus.listening) {
        if (!(_finalResultCompleter?.isCompleted ?? true)) {
          _finalResultCompleter?.complete(_lastRecognizedWords);
        }
        _finalizeRecognition(_lastRecognizedWords, sessionToken: _activeSessionId);
      }
    }
  }

  void _handleError(SpeechRecognitionError errorNotification) {
    debugPrint(
      '[STT] SpeechToText error: ${errorNotification.errorMsg} (permanent: ${errorNotification.permanent})',
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
    if (_isDisposed) return;
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _activeResultCallback = null;
    _activeCompleteCallback = null;
    _speech.cancel();
    super.dispose();
  }
}
