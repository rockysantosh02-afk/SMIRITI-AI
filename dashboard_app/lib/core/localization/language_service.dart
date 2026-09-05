import 'package:shared_preferences/shared_preferences.dart';
import '../../features/voice/services/language_detector.dart';
import 'app_languages.dart';

/// Contract for persistent language preference storage.
abstract class ILanguageService {
  Future<AppLanguage> getSavedLanguage();
  Future<bool> saveLanguage(AppLanguage language);
  Future<bool> hasCompletedOnboarding();
  Future<bool> setOnboardingCompleted(bool completed);
  Future<VoiceResponseLanguageMode> getVoiceResponseLanguageMode();
  Future<bool> saveVoiceResponseLanguageMode(VoiceResponseLanguageMode mode);
}

/// Production implementation of [ILanguageService] using [SharedPreferences].
class LanguageService implements ILanguageService {
  static const String storageKey = 'app_language_code';
  static const String onboardingKey = 'language_onboarding_completed';
  static const String voiceResponseModeKey = 'voice_response_language_mode';

  final SharedPreferences? _prefs;

  LanguageService({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Retrieve the saved language preference. Defaults to [AppLanguages.defaultLanguage]
  /// if no preference exists or if an invalid code is stored.
  @override
  Future<AppLanguage> getSavedLanguage() async {
    try {
      final prefs = await _instance;
      final savedCode = prefs.getString(storageKey);
      if (savedCode == null || savedCode.isEmpty) {
        return AppLanguages.defaultLanguage;
      }
      return AppLanguages.fromCode(savedCode);
    } catch (_) {
      return AppLanguages.defaultLanguage;
    }
  }

  /// Persist the selected language preference to local storage.
  @override
  Future<bool> saveLanguage(AppLanguage language) async {
    try {
      final prefs = await _instance;
      return await prefs.setString(storageKey, language.code);
    } catch (_) {
      return false;
    }
  }

  /// Check whether first-time language onboarding has been completed.
  @override
  Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await _instance;
      return prefs.getBool(onboardingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Persist onboarding completion flag.
  @override
  Future<bool> setOnboardingCompleted(bool completed) async {
    try {
      final prefs = await _instance;
      return await prefs.setBool(onboardingKey, completed);
    } catch (_) {
      return false;
    }
  }

  /// Retrieve the saved voice response language mode. Defaults to [VoiceResponseLanguageMode.sameAsDetectedSpeech].
  @override
  Future<VoiceResponseLanguageMode> getVoiceResponseLanguageMode() async {
    try {
      final prefs = await _instance;
      final saved = prefs.getString(voiceResponseModeKey);
      return VoiceResponseLanguageModeExtension.fromCode(saved);
    } catch (_) {
      return VoiceResponseLanguageMode.sameAsDetectedSpeech;
    }
  }

  /// Persist the selected voice response language mode.
  @override
  Future<bool> saveVoiceResponseLanguageMode(VoiceResponseLanguageMode mode) async {
    try {
      final prefs = await _instance;
      return await prefs.setString(voiceResponseModeKey, mode.code);
    } catch (_) {
      return false;
    }
  }
}

