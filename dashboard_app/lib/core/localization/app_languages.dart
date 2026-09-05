import 'package:flutter/material.dart';

/// Supported application languages for Smriti AI.
enum AppLanguage {
  english,
  telugu,
  hindi,
}

/// Extension providing metadata, locales, STT candidates, and TTS locale mapping.
extension AppLanguageExtension on AppLanguage {
  /// ISO 639-1 language code
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.telugu:
        return 'te';
      case AppLanguage.hindi:
        return 'hi';
    }
  }

  /// Primary Flutter [Locale]
  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en', 'US');
      case AppLanguage.telugu:
        return const Locale('te', 'IN');
      case AppLanguage.hindi:
        return const Locale('hi', 'IN');
    }
  }

  /// English display name
  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.telugu:
        return 'Telugu';
      case AppLanguage.hindi:
        return 'Hindi';
    }
  }

  /// Culturally authentic native name
  String get nativeName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.telugu:
        return 'తెలుగు';
      case AppLanguage.hindi:
        return 'हिन्दी';
    }
  }

  /// Candidate Speech-to-Text locale tags in order of preference
  List<String> get sttLocales {
    switch (this) {
      case AppLanguage.english:
        return const ['en_US', 'en_IN', 'en_GB', 'en'];
      case AppLanguage.telugu:
        return const ['te_IN', 'te'];
      case AppLanguage.hindi:
        return const ['hi_IN', 'hi', 'en_IN'];
    }
  }

  /// Candidate Text-to-Speech locale identifier
  String get ttsLocale {
    switch (this) {
      case AppLanguage.english:
        return 'en-US';
      case AppLanguage.telugu:
        return 'te-IN';
      case AppLanguage.hindi:
        return 'hi-IN';
    }
  }
}

/// Centralized registry and helper utilities for application languages.
class AppLanguages {
  AppLanguages._();

  /// Default application language (English)
  static const AppLanguage defaultLanguage = AppLanguage.english;

  /// All supported application languages
  static const List<AppLanguage> supportedLanguages = AppLanguage.values;

  /// Supported Flutter locales for MaterialApp
  static List<Locale> get supportedLocales => [
        const Locale('en', 'US'),
        const Locale('en'),
        const Locale('te', 'IN'),
        const Locale('te'),
        const Locale('hi', 'IN'),
        const Locale('hi'),
      ];

  /// Parse [AppLanguage] from language code with safe fallback to [defaultLanguage].
  static AppLanguage fromCode(String? code) {
    if (code == null) return defaultLanguage;
    final clean = code.toLowerCase().trim();
    for (final lang in AppLanguage.values) {
      if (lang.code == clean || clean.startsWith(lang.code)) {
        return lang;
      }
    }
    return defaultLanguage;
  }
}
