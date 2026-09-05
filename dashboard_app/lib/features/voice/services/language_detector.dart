import '../../../core/localization/app_languages.dart';

/// Supported response language modes for the voice assistant.
enum VoiceResponseLanguageMode {
  sameAsDetectedSpeech,
  sameAsAppLanguage,
  alwaysEnglish,
  alwaysTelugu,
  alwaysHindi,
}

extension VoiceResponseLanguageModeExtension on VoiceResponseLanguageMode {
  String get displayName {
    switch (this) {
      case VoiceResponseLanguageMode.sameAsDetectedSpeech:
        return 'Same as detected speech';
      case VoiceResponseLanguageMode.sameAsAppLanguage:
        return 'Same as app language';
      case VoiceResponseLanguageMode.alwaysEnglish:
        return 'Always English';
      case VoiceResponseLanguageMode.alwaysTelugu:
        return 'Always Telugu';
      case VoiceResponseLanguageMode.alwaysHindi:
        return 'Always Hindi';
    }
  }

  String get code {
    switch (this) {
      case VoiceResponseLanguageMode.sameAsDetectedSpeech:
        return 'detected';
      case VoiceResponseLanguageMode.sameAsAppLanguage:
        return 'app_language';
      case VoiceResponseLanguageMode.alwaysEnglish:
        return 'en';
      case VoiceResponseLanguageMode.alwaysTelugu:
        return 'te';
      case VoiceResponseLanguageMode.alwaysHindi:
        return 'hi';
    }
  }

  static VoiceResponseLanguageMode fromCode(String? code) {
    switch (code) {
      case 'app_language':
        return VoiceResponseLanguageMode.sameAsAppLanguage;
      case 'en':
        return VoiceResponseLanguageMode.alwaysEnglish;
      case 'te':
        return VoiceResponseLanguageMode.alwaysTelugu;
      case 'hi':
        return VoiceResponseLanguageMode.alwaysHindi;
      case 'detected':
      default:
        return VoiceResponseLanguageMode.sameAsDetectedSpeech;
    }
  }
}

/// Utility for detecting spoken/written speech language across English, Telugu, and Hindi.
class LanguageDetector {
  const LanguageDetector();

  // Unicode Ranges
  // Telugu: U+0C00 - U+0C7F
  static final RegExp _teluguRegex = RegExp(r'[\u0C00-\u0C7F]');

  // Devanagari / Hindi: U+0900 - U+097F
  static final RegExp _hindiRegex = RegExp(r'[\u0900-\u097F]');

  // Latin / English characters
  static final RegExp _englishRegex = RegExp(r'[a-zA-Z]');

  /// Detect language directly from text.
  /// Returns 'te', 'hi', 'en', or null if undetermined.
  static String? detectLanguageCode(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    int teluguCount = 0;
    int hindiCount = 0;
    int englishCount = 0;

    for (final rune in clean.runes) {
      final char = String.fromCharCode(rune);
      if (_teluguRegex.hasMatch(char)) {
        teluguCount++;
      } else if (_hindiRegex.hasMatch(char)) {
        hindiCount++;
      } else if (_englishRegex.hasMatch(char)) {
        englishCount++;
      }
    }

    if (teluguCount > 0 && teluguCount >= hindiCount && teluguCount >= englishCount) {
      return 'te';
    }
    if (hindiCount > 0 && hindiCount >= teluguCount && hindiCount >= englishCount) {
      return 'hi';
    }
    if (englishCount > 0) {
      return 'en';
    }

    return null;
  }

  /// Resolve final voice response language code given the recognized speech,
  /// current active app language code, and user's preferred [VoiceResponseLanguageMode].
  ///
  /// Fallback order:
  /// 1. Detected Speech (if mode is sameAsDetectedSpeech)
  /// 2. App Language
  /// 3. English ('en')
  static String resolveResponseLanguage({
    required String spokenText,
    required String appLanguageCode,
    VoiceResponseLanguageMode mode = VoiceResponseLanguageMode.sameAsDetectedSpeech,
  }) {
    switch (mode) {
      case VoiceResponseLanguageMode.alwaysEnglish:
        return 'en';
      case VoiceResponseLanguageMode.alwaysTelugu:
        return 'te';
      case VoiceResponseLanguageMode.alwaysHindi:
        return 'hi';
      case VoiceResponseLanguageMode.sameAsAppLanguage:
        final cleanAppCode = appLanguageCode.toLowerCase().trim();
        if (cleanAppCode == 'te' || cleanAppCode == 'hi' || cleanAppCode == 'en') {
          return cleanAppCode;
        }
        return AppLanguages.defaultLanguage.code;
      case VoiceResponseLanguageMode.sameAsDetectedSpeech:
        final detected = detectLanguageCode(spokenText);
        if (detected != null) {
          return detected;
        }
        // Fallback to active app language
        final cleanAppCode = appLanguageCode.toLowerCase().trim();
        if (cleanAppCode == 'te' || cleanAppCode == 'hi' || cleanAppCode == 'en') {
          return cleanAppCode;
        }
        // Ultimate fallback
        return AppLanguages.defaultLanguage.code;
    }
  }
}
