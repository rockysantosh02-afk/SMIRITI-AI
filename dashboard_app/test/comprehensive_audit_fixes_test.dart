import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/family_repository.dart';
import 'package:dashboard_app/core/database/repositories/journal_repository.dart';
import 'package:dashboard_app/core/database/repositories/reminder_repository.dart';
import 'package:dashboard_app/core/localization/app_languages.dart';
import 'package:dashboard_app/core/localization/app_localizations.dart';
import 'package:dashboard_app/features/games/models/game_item.dart';
import 'package:dashboard_app/features/games/services/game_localized_content.dart';
import 'package:dashboard_app/features/journal/journal_entry_screen.dart';
import 'package:dashboard_app/features/journal/journal_story_service.dart';
import 'package:dashboard_app/features/memory/family_member_screen.dart';
import 'package:dashboard_app/features/reminders/reminder_entry_screen.dart';
import 'package:dashboard_app/features/reminders/services/notification_service.dart';
import 'package:dashboard_app/features/voice/models/voice_intent.dart';
import 'package:dashboard_app/features/voice/services/language_detector.dart';
import 'package:dashboard_app/features/voice/services/voice_intent_matcher.dart';
import 'package:dashboard_app/features/voice/services/voice_service.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FamilyRepository familyRepo;
  late JournalRepository journalRepo;
  late ReminderRepository reminderRepo;
  late FakeNotificationService notificationService;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    if (Platform.isWindows) {
      open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
    }
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    DatabaseProvider.setInstance(db);
    familyRepo = FamilyRepository(db);
    journalRepo = JournalRepository(db);
    reminderRepo = ReminderRepository(db);
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    DatabaseProvider.resetInstance();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLanguages.supportedLocales,
      home: child,
    );
  }

  group('Phase 2 & 3: Games Language Synchronization Tests', () {
    test('GameLocalizedContent resolves English, Telugu, and Hindi correctly', () {
      final games = [
        'matching_image',
        'pick_correct',
        'number_game',
        'find_difference',
        'place_correctly',
        'draw_shape',
        'situation_match',
        'family_quiz',
        'recalling_memories',
      ];

      for (final gameId in games) {
        final dummyItem = GameItem(
          id: 'test_1',
          image: 'temple',
          prompt: 'Default prompt',
          options: const ['A', 'B'],
          correctIndex: 0,
        );
        final enText = GameLocalizedContent.getLocalizedPrompt(
          dummyItem,
          gameId: gameId,
          languageCode: 'en',
        );
        final teText = GameLocalizedContent.getLocalizedPrompt(
          dummyItem,
          gameId: gameId,
          languageCode: 'te',
        );
        final hiText = GameLocalizedContent.getLocalizedPrompt(
          dummyItem,
          gameId: gameId,
          languageCode: 'hi',
        );

        expect(enText, isNotEmpty);
        expect(teText, isNotEmpty);
        expect(hiText, isNotEmpty);

        // Telugu contains Telugu Unicode script \u0C00-\u0C7F
        expect(RegExp(r'[\u0C00-\u0C7F]').hasMatch(teText), isTrue,
            reason: '$gameId Telugu prompt must contain Telugu characters: $teText');

        // Hindi contains Devanagari Unicode script \u0900-\u097F
        expect(RegExp(r'[\u0900-\u097F]').hasMatch(hiText), isTrue,
            reason: '$gameId Hindi prompt must contain Devanagari characters: $hiText');
      }
    });

    test('Recall Memories prompts and questions synchronize with selected language', () {
      final item = GameItem(
        id: '1',
        prompt: '',
        image: 'temple',
        options: const ['A', 'B'],
        correctIndex: 0,
      );
      final promptEn = GameLocalizedContent.getLocalizedPrompt(
        item,
        gameId: 'recalling_memories',
        languageCode: 'en',
      );
      final promptTe = GameLocalizedContent.getLocalizedPrompt(
        item,
        gameId: 'recalling_memories',
        languageCode: 'te',
      );
      final promptHi = GameLocalizedContent.getLocalizedPrompt(
        item,
        gameId: 'recalling_memories',
        languageCode: 'hi',
      );

      expect(promptEn, contains('temple'));
      expect(promptTe, contains('దేవాలయ'));
      expect(promptHi, contains('मंदिर'));
    });
  });

  group('Phase 4, 5, 6, 7: Voice Assistant Multilingual Tests', () {
    const matcher = VoiceIntentMatcher();

    test('Voice intent recognition matches Telugu memory phrases to openJournal', () {
      final res1 = matcher.match('నా మెమరీస్ తెరువు', languageCode: 'te');
      expect(res1.intent, equals(VoiceIntent.openJournal));
      expect(res1.targetRoute, equals('/journal'));

      final res2 = matcher.match('మెమరీస్ తెరువు', languageCode: 'te');
      expect(res2.intent, equals(VoiceIntent.openJournal));

      final res3 = matcher.match('జ్ఞాపకాలు తెరువు', languageCode: 'te');
      expect(res3.intent, equals(VoiceIntent.openJournal));
    });

    test('Voice intent recognition matches Hindi memory phrases to openJournal', () {
      final res1 = matcher.match('मेरी मेमोरी खोलो', languageCode: 'hi');
      expect(res1.intent, equals(VoiceIntent.openJournal));
      expect(res1.targetRoute, equals('/journal'));

      final res2 = matcher.match('मेमोरी खोलो', languageCode: 'hi');
      expect(res2.intent, equals(VoiceIntent.openJournal));

      final res3 = matcher.match('यादें खोलो', languageCode: 'hi');
      expect(res3.intent, equals(VoiceIntent.openJournal));
    });

    test('Voice intent recognition matches English memory phrases to openJournal', () {
      final res = matcher.match('Open my memories', languageCode: 'en');
      expect(res.intent, equals(VoiceIntent.openJournal));
      expect(res.targetRoute, equals('/journal'));
    });

    test('LanguageDetector identifies script correctly across Telugu, Hindi, English', () {
      expect(LanguageDetector.detectLanguageCode('నా మెమరీస్ తెరువు'), equals('te'));
      expect(LanguageDetector.detectLanguageCode('मेरी मेमोरी खोलो'), equals('hi'));
      expect(LanguageDetector.detectLanguageCode('Open my memories'), equals('en'));
    });

    test('VoiceService locale normalization treats te_IN and te-IN as equivalent', () {
      expect(VoiceService.normalizeLocaleTag('te_IN'), equals('tein'));
      expect(VoiceService.normalizeLocaleTag('te-IN'), equals('tein'));
      expect(VoiceService.normalizeLocaleTag('hi_IN'), equals('hiin'));
      expect(VoiceService.normalizeLocaleTag('en-US'), equals('enus'));
    });
  });

  group('Phase 9 & 10: Family Memories Save & Validation Tests', () {
    testWidgets('Empty fields show validation message and prevent saving', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(
        FamilyMemberScreen(repository: familyRepo),
      ));
      await tester.pumpAndSettle();

      // Open Add Member dialog
      await tester.tap(find.text('Add Family Member'));
      await tester.pumpAndSettle();

      // Tap Save Member without entering name
      await tester.tap(find.text('Save Member'));
      await tester.pump();

      // Verify validation message
      expect(find.text('Please fill in the required details.'), findsOneWidget);

      // Verify repository remains empty
      final all = await familyRepo.getAllMembers();
      expect(all, isEmpty);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Valid details entered saves member to SQLite and updates UI', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(
        FamilyMemberScreen(repository: familyRepo),
      ));
      await tester.pumpAndSettle();

      // Open Add Member dialog
      await tester.tap(find.text('Add Family Member'));
      await tester.pumpAndSettle();

      // Enter name: Ramesh
      final nameFields = find.byType(TextField);
      await tester.enterText(nameFields.first, 'Ramesh');
      await tester.pump();

      // Tap Save Member
      await tester.tap(find.text('Save Member'));
      await tester.pumpAndSettle();

      // Verify database record
      final members = await familyRepo.getAllMembers();
      expect(members.length, equals(1));
      expect(members.first.name, equals('Ramesh'));

      // Verify UI displays Ramesh immediately
      expect(find.text('Ramesh'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Phase 11, 12, 13: New Memory Validation & Resilient Save Tests', () {
    testWidgets('Empty fields show validation message and reset loading state', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(
        JournalEntryScreen(repository: journalRepo),
      ));
      await tester.pumpAndSettle();

      // Tap Save without entering title or body
      await tester.tap(find.byKey(const Key('save_memory_button')));
      await tester.pump();

      expect(find.textContaining('Please fill in the required details.'), findsOneWidget);
      expect((await journalRepo.getAll()).isEmpty, isTrue);
    });

    testWidgets('Valid memory saves locally even if story generation fails', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Create a story service that returns failure/offline
      final failingStoryService = JournalStoryService(
        baseUrl: 'http://invalid-offline-backend-12345.local',
      );

      await tester.pumpWidget(buildTestableWidget(
        JournalEntryScreen(
          repository: journalRepo,
          storyService: failingStoryService,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('journal_title_input')), 'Walk in the Park');
      await tester.enterText(find.byKey(const Key('journal_body_input')), 'Beautiful roses and pleasant breeze.');
      await tester.pump();

      // Save memory
      await tester.tap(find.byKey(const Key('save_memory_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify memory is safely saved in SQLite
      final entries = await journalRepo.getAll();
      expect(entries.length, equals(1));
      expect(entries.first.title, equals('Walk in the Park'));
      expect(entries.first.body, equals('Beautiful roses and pleasant breeze.'));
    });
  });

  group('Phase 15 & 16: Reminder Time Selection UI Tests', () {
    testWidgets('Reminder Time section displays clean centered time and Change Time button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(
        ReminderEntryScreen(
          repository: reminderRepo,
          notificationService: notificationService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Reminder Time'), findsOneWidget);
      expect(find.byKey(const Key('change_time_button')), findsOneWidget);
      expect(find.text('Change Time'), findsOneWidget);

      // Enter title and save
      await tester.enterText(find.byType(TextField), 'Evening Walk');
      await tester.tap(find.text('Create Reminder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final all = await reminderRepo.getAll();
      expect(all.length, equals(1));
      expect(all.first.title, equals('Evening Walk'));
    });
  });
}
