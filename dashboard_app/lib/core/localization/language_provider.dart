import 'package:flutter/material.dart';
import '../../features/voice/services/language_detector.dart';
import 'app_languages.dart';
import 'language_service.dart';

/// Provider for managing and reactively broadcasting the active application language.
class LanguageProvider extends ChangeNotifier {
  final ILanguageService _service;
  AppLanguage _currentLanguage;
  VoiceResponseLanguageMode _voiceResponseLanguageMode;

  LanguageProvider({
    ILanguageService? service,
    ILanguageService? languageService,
    AppLanguage initialLanguage = AppLanguages.defaultLanguage,
    VoiceResponseLanguageMode initialVoiceMode =
        VoiceResponseLanguageMode.sameAsDetectedSpeech,
  })  : _service = service ?? languageService ?? LanguageService(),
        _currentLanguage = initialLanguage,
        _voiceResponseLanguageMode = initialVoiceMode;

  /// Alias for [loadLanguage]
  Future<void> initialize() async {
    await loadLanguage();
    await loadVoiceResponseMode();
  }

  /// Currently selected [AppLanguage]
  AppLanguage get currentLanguage => _currentLanguage;

  /// Primary Flutter [Locale] for the active language
  Locale get currentLocale => _currentLanguage.locale;

  /// ISO 639-1 language code for the active language ('en', 'te', 'hi')
  String get languageCode => _currentLanguage.code;

  /// Currently selected voice response language mode
  VoiceResponseLanguageMode get voiceResponseLanguageMode =>
      _voiceResponseLanguageMode;

  /// Initialize and load previously persisted language from disk
  Future<void> loadLanguage() async {
    final saved = await _service.getSavedLanguage();
    if (saved != _currentLanguage) {
      _currentLanguage = saved;
      notifyListeners();
    }
  }

  /// Load voice response mode from disk
  Future<void> loadVoiceResponseMode() async {
    final saved = await _service.getVoiceResponseLanguageMode();
    if (saved != _voiceResponseLanguageMode) {
      _voiceResponseLanguageMode = saved;
      notifyListeners();
    }
  }

  /// Change active language, persist to local storage, and notify listeners immediately.
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    // Persist to SharedPreferences
    await _service.saveLanguage(language);
  }

  /// Change voice response language mode and persist
  Future<void> setVoiceResponseLanguageMode(
      VoiceResponseLanguageMode mode) async {
    if (_voiceResponseLanguageMode == mode) return;

    _voiceResponseLanguageMode = mode;
    notifyListeners();

    await _service.saveVoiceResponseLanguageMode(mode);
  }

  /// Complete onboarding and persist language
  Future<void> completeOnboarding(AppLanguage language) async {
    await setLanguage(language);
    await _service.setOnboardingCompleted(true);
  }
}

