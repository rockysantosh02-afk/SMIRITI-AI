import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard_app/core/localization/app_languages.dart';
import 'package:dashboard_app/core/localization/app_localizations.dart';
import 'package:dashboard_app/core/localization/language_provider.dart';
import 'package:dashboard_app/core/localization/language_service.dart';
import 'package:dashboard_app/features/onboarding/language_onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Language Onboarding & Management Tests', () {
    late LanguageService languageService;
    late LanguageProvider languageProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      languageService = LanguageService(prefs: prefs);
      languageProvider = LanguageProvider(service: languageService);
    });

    testWidgets('LanguageOnboardingScreen renders 3 language cards with high contrast',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
            child: const LanguageOnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WELCOME TO SMRITI AI'), findsOneWidget);
      expect(find.text('Please choose your preferred language'), findsOneWidget);
      expect(find.text('English'), findsWidgets);
      expect(find.text('తెలుగు'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Selecting Telugu card updates provider and saves to SharedPreferences',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('Login Screen')),
            '/dashboard': (_) => const Scaffold(body: Text('Dashboard Screen')),
          },
          home: ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
            child: const LanguageOnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Telugu card
      final teluguCard = find.text('తెలుగు');
      expect(teluguCard, findsOneWidget);
      await tester.tap(teluguCard);
      await tester.pumpAndSettle();

      // Tap continue button
      final continueButton = find.byType(ElevatedButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verify onboarding completed and language saved
      final completed = await languageService.hasCompletedOnboarding();
      final savedLang = await languageService.getSavedLanguage();
      expect(completed, isTrue);
      expect(savedLang, equals(AppLanguage.telugu));
      expect(languageProvider.currentLanguage, equals(AppLanguage.telugu));
      expect(languageProvider.languageCode, equals('te'));
      expect(languageProvider.currentLocale.languageCode, equals('te'));
    });

    testWidgets('Selecting Hindi card updates provider and saves to SharedPreferences',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('Login Screen')),
            '/dashboard': (_) => const Scaffold(body: Text('Dashboard Screen')),
          },
          home: ChangeNotifierProvider<LanguageProvider>.value(
            value: languageProvider,
            child: const LanguageOnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Hindi card
      final hindiCard = find.text('हिन्दी');
      expect(hindiCard, findsOneWidget);
      await tester.tap(hindiCard);
      await tester.pumpAndSettle();

      // Tap continue button
      final continueButton = find.byType(ElevatedButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verify onboarding completed and language saved
      final completed = await languageService.hasCompletedOnboarding();
      final savedLang = await languageService.getSavedLanguage();
      expect(completed, isTrue);
      expect(savedLang, equals(AppLanguage.hindi));
      expect(languageProvider.currentLanguage, equals(AppLanguage.hindi));
      expect(languageProvider.languageCode, equals('hi'));
      expect(languageProvider.currentLocale.languageCode, equals('hi'));
    });

    test('AppLocalizations provides correct strings across English, Telugu, and Hindi', () {
      final locEn = AppLocalizations(const Locale('en', 'US'));
      final locTe = AppLocalizations(const Locale('te', 'IN'));
      final locHi = AppLocalizations(const Locale('hi', 'IN'));

      expect(locEn.appTitle, equals('Smriti AI'));
      expect(locTe.appTitle, equals('స్మృతి AI'));
      expect(locHi.appTitle, equals('स्मृति AI'));

      expect(locEn.journal, equals('Journal'));
      expect(locTe.journal, equals('డైరీ'));
      expect(locHi.journal, equals('डायरी'));

      expect(locEn.games, equals('Games'));
      expect(locTe.games, equals('ఆటలు'));
      expect(locHi.games, equals('खेल'));

      expect(locEn.voiceAssistant, equals('Voice Assistant'));
      expect(locTe.voiceAssistant, equals('వాయిస్ అసిస్టెంట్'));
      expect(locHi.voiceAssistant, equals('आवाज़ सहायक'));

      expect(locEn.typeReminder, equals('Type Reminder'));
      expect(locTe.typeReminder, equals('టైప్ చేసి రాయండి'));
      expect(locHi.typeReminder, equals('टाइप करके लिखें'));

      expect(locEn.speakReminder, equals('Speak Reminder'));
      expect(locTe.speakReminder, equals('మాట్లాడి చెప్పండి'));
      expect(locHi.speakReminder, equals('बोलकर बताएं'));
    });

    testWidgets('Dynamic language switching updates UI in real-time without app restart',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child: Consumer<LanguageProvider>(
            builder: (context, lang, _) {
              final loc = AppLocalizations(lang.currentLocale);
              return MaterialApp(
                locale: lang.currentLocale,
                home: Scaffold(
                  body: Text(loc.reminders),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reminders'), findsOneWidget);

      // Switch to Telugu
      languageProvider.setLanguage(AppLanguage.telugu);
      await tester.pumpAndSettle();
      expect(find.text('రిమైండర్లు'), findsOneWidget);

      // Switch to Hindi
      languageProvider.setLanguage(AppLanguage.hindi);
      await tester.pumpAndSettle();
      expect(find.text('रिमाइंडर'), findsOneWidget);
    });
  });
}
