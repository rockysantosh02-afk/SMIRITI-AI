import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashboard_app/core/localization/app_languages.dart';
import 'package:dashboard_app/core/localization/language_service.dart';
import 'package:dashboard_app/core/localization/language_provider.dart';
import 'package:dashboard_app/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 1 & 2: AppLanguages & LanguageService Tests', () {
    test('1. Default language is English', () {
      expect(AppLanguages.defaultLanguage, equals(AppLanguage.english));
      expect(AppLanguages.defaultLanguage.code, equals('en'));
      expect(AppLanguages.defaultLanguage.locale, equals(const Locale('en', 'US')));
      expect(AppLanguages.defaultLanguage.ttsLocale, equals('en-US'));
    });

    test('2. LanguageService returns English if nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LanguageService();
      final lang = await service.getSavedLanguage();
      expect(lang, equals(AppLanguage.english));
    });

    test('3. Telugu persists correctly in LanguageService', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LanguageService();

      final saved = await service.saveLanguage(AppLanguage.telugu);
      expect(saved, isTrue);

      final lang = await service.getSavedLanguage();
      expect(lang, equals(AppLanguage.telugu));
      expect(lang.code, equals('te'));
      expect(lang.nativeName, equals('తెలుగు'));
      expect(lang.ttsLocale, equals('te-IN'));
    });

    test('4. Hindi persists correctly in LanguageService', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LanguageService();

      final saved = await service.saveLanguage(AppLanguage.hindi);
      expect(saved, isTrue);

      final lang = await service.getSavedLanguage();
      expect(lang, equals(AppLanguage.hindi));
      expect(lang.code, equals('hi'));
      expect(lang.nativeName, equals('हिन्दी'));
      expect(lang.ttsLocale, equals('hi-IN'));
    });

    test('5. Invalid language code safely falls back to English', () async {
      SharedPreferences.setMockInitialValues({
        LanguageService.storageKey: 'invalid_xyz',
      });
      final service = LanguageService();
      final lang = await service.getSavedLanguage();
      expect(lang, equals(AppLanguage.english));

      // Test helper directly
      expect(AppLanguages.fromCode('unknown'), equals(AppLanguage.english));
      expect(AppLanguages.fromCode(null), equals(AppLanguage.english));
    });

    test('Supported languages contains English, Telugu, and Hindi', () {
      expect(AppLanguages.supportedLanguages.length, equals(3));
      expect(AppLanguages.supportedLocales.length, equals(6));
      expect(
        AppLanguages.supportedLocales,
        containsAll([
          const Locale('en', 'US'),
          const Locale('te', 'IN'),
          const Locale('hi', 'IN'),
        ]),
      );
    });
  });

  group('Part 2: LanguageProvider Tests', () {
    test('6. LanguageProvider updates correctly and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final service = LanguageService();
      final provider = LanguageProvider(languageService: service);

      expect(provider.currentLanguage, equals(AppLanguage.english));
      expect(provider.languageCode, equals('en'));
      expect(provider.currentLocale, equals(const Locale('en', 'US')));

      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      await provider.setLanguage(AppLanguage.telugu);
      expect(notifyCount, equals(1));
      expect(provider.currentLanguage, equals(AppLanguage.telugu));
      expect(provider.languageCode, equals('te'));
      expect(provider.currentLocale, equals(const Locale('te', 'IN')));

      // Verify persisted in service
      final loadedLang = await service.getSavedLanguage();
      expect(loadedLang, equals(AppLanguage.telugu));

      // Switch to Hindi
      await provider.setLanguage(AppLanguage.hindi);
      expect(notifyCount, equals(2));
      expect(provider.currentLanguage, equals(AppLanguage.hindi));
      expect(provider.languageCode, equals('hi'));
      expect(provider.currentLocale, equals(const Locale('hi', 'IN')));
    });

    test('LanguageProvider.initialize loads saved language without flicker', () async {
      SharedPreferences.setMockInitialValues({
        LanguageService.storageKey: 'te',
      });
      final service = LanguageService();
      final provider = LanguageProvider(languageService: service);

      await provider.initialize();
      expect(provider.currentLanguage, equals(AppLanguage.telugu));
      expect(provider.languageCode, equals('te'));
    });
  });

  group('Part 3: AppLocalizations Tests', () {
    test('7. AppLocalizations returns correct English strings', () {
      final loc = AppLocalizations(const Locale('en', 'US'));
      expect(loc.appName, equals('Smriti AI'));
      expect(loc.home, equals('Home'));
      expect(loc.journal, equals('Journal'));
      expect(loc.games, equals('Games'));
      expect(loc.voiceAssistant, equals('Voice Assistant'));
      expect(loc.reminders, equals('Reminders'));
      expect(loc.settings, equals('Settings'));
      expect(loc.language, equals('Language'));
      expect(loc.tapToSpeak, equals('Tap to Speak'));
      expect(loc.createReminder, equals('Create Reminder'));
      expect(loc.greetingMorning, equals('Good Morning'));
    });

    test('8. AppLocalizations returns correct Telugu strings', () {
      final loc = AppLocalizations(const Locale('te', 'IN'));
      expect(loc.appName, equals('స్మృతి AI'));
      expect(loc.home, equals('హోమ్'));
      expect(loc.journal, equals('డైరీ'));
      expect(loc.games, equals('ఆటలు'));
      expect(loc.voiceAssistant, equals('వాయిస్ అసిస్టెంట్'));
      expect(loc.reminders, equals('రిమైండర్లు'));
      expect(loc.settings, equals('సెట్టింగ్స్'));
      expect(loc.language, equals('భాష'));
      expect(loc.tapToSpeak, equals('మాట్లాడటానికి నొక్కండి'));
      expect(loc.createReminder, equals('రిమైండర్ సెట్ చేయండి'));
      expect(loc.greetingMorning, equals('శుభోదయం'));
    });

    test('9. AppLocalizations returns correct Hindi strings', () {
      final loc = AppLocalizations(const Locale('hi', 'IN'));
      expect(loc.appName, equals('स्मृति AI'));
      expect(loc.home, equals('होम'));
      expect(loc.journal, equals('डायरी'));
      expect(loc.games, equals('खेल'));
      expect(loc.voiceAssistant, equals('आवाज़ सहायक'));
      expect(loc.reminders, equals('रिमाइंडर'));
      expect(loc.settings, equals('सेटिंग्स'));
      expect(loc.language, equals('भाषा'));
      expect(loc.tapToSpeak, equals('बोलने के लिए दबाएं'));
      expect(loc.createReminder, equals('रिमाइंडर बनाएं'));
      expect(loc.greetingMorning, equals('शुभ प्रभात'));
    });

    test('AppLocalizations delegate supports declared locales and loads', () async {
      const delegate = AppLocalizations.delegate;
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('te')), isTrue);
      expect(delegate.isSupported(const Locale('hi')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);

      final loaded = await delegate.load(const Locale('te', 'IN'));
      expect(loaded.language, equals('భాష'));
    });
  });
}
