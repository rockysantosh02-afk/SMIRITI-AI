import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/reminder_repository.dart';
import 'package:dashboard_app/features/voice/models/voice_intent.dart';
import 'package:dashboard_app/features/voice/services/voice_intent_matcher.dart';
import 'package:dashboard_app/features/voice/services/conversational_intent_engine.dart';
import 'package:dashboard_app/features/voice/services/voice_conversation_service.dart';
import 'package:dashboard_app/features/reminders/services/notification_service.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Voice Navigation Command Routing Tests', () {
    const matcher = VoiceIntentMatcher();

    test('"open the journal" routes to Journal, not Games', () {
      final res = matcher.match('open the journal', languageCode: 'en');
      expect(res.intent, equals(VoiceIntent.openJournal));
      expect(res.targetRoute, equals('/journal'));
    });

    test('Journal variations route to Journal', () {
      final res1 = matcher.match('open journal', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.openJournal));

      final res2 = matcher.match('take me to journal', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openJournal));

      final res3 = matcher.match('show journal', languageCode: 'en');
      expect(res3.intent, equals(VoiceIntent.openJournal));

      final res4 = matcher.match('write in journal', languageCode: 'en');
      expect(res4.intent, equals(VoiceIntent.openJournal));
    });

    test('Games commands route to Games', () {
      final res1 = matcher.match('open games', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.openGames));
      expect(res1.targetRoute, equals('/games'));

      final res2 = matcher.match('show games', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openGames));

      final res3 = matcher.match('go to games', languageCode: 'en');
      expect(res3.intent, equals(VoiceIntent.openGames));

      final res4 = matcher.match('play a game', languageCode: 'en');
      expect(res4.intent, equals(VoiceIntent.openGames));
    });

    test('Reminders commands route to Reminders', () {
      final res = matcher.match('open reminders', languageCode: 'en');
      expect(res.intent, equals(VoiceIntent.openReminders));
      expect(res.targetRoute, equals('/reminders'));

      final res2 = matcher.match('show reminders', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openReminders));

      final res3 = matcher.match('go to reminders', languageCode: 'en');
      expect(res3.intent, equals(VoiceIntent.openReminders));
    });

    test('Settings commands route to Settings', () {
      final res1 = matcher.match('open settings', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.openSettings));
      expect(res1.targetRoute, equals('/settings'));

      final res2 = matcher.match('show settings', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openSettings));

      final res3 = matcher.match('go to settings', languageCode: 'en');
      expect(res3.intent, equals(VoiceIntent.openSettings));
    });

    test('Profile commands route to Profile', () {
      final res1 = matcher.match('open profile', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.openProfile));
      expect(res1.targetRoute, equals('/profile'));

      final res2 = matcher.match('show profile', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openProfile));

      final res3 = matcher.match('go to profile', languageCode: 'en');
      expect(res3.intent, equals(VoiceIntent.openProfile));
    });

    test('Home commands route to Home/Dashboard', () {
      final res1 = matcher.match('go home', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.openDashboard));
      expect(res1.targetRoute, equals('/dashboard'));

      final res2 = matcher.match('open home', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openDashboard));

      final res3 = matcher.match('show home', languageCode: 'en');
      expect(res3.intent, equals(VoiceIntent.openDashboard));
    });

    test('Conversational statements DO NOT accidentally route to navigation', () {
      final res1 = matcher.match(
        'My daughter is going to USA for higher studies.',
        languageCode: 'en',
      );
      expect(res1.intent, equals(VoiceIntent.unknown));
      expect(res1.targetRoute, isNull);

      final res2 = matcher.match(
        'I played with my grandchildren in the garden.',
        languageCode: 'en',
      );
      expect(res2.intent, equals(VoiceIntent.unknown));
      expect(res2.targetRoute, isNull);

      final res3 = matcher.match(
        'Life is an interesting game.',
        languageCode: 'en',
      );
      expect(res3.intent, equals(VoiceIntent.unknown));
      expect(res3.targetRoute, isNull);
    });
  });

  group('Conversational Intent Engine Tests', () {
    const engine = ConversationalIntentEngine();

    test('Daughter going to USA for higher studies: identifies family news with context', () {
      const utterance = 'My daughter is going to USA for higher studies.';
      final result = engine.detect(utterance);

      expect(result.intent, equals(ConversationalIntent.familyNews));
      expect(result.extractedContext['isAbroad'], isTrue);
      expect(result.extractedContext['isStudies'], isTrue);
      expect(result.extractedContext['relation'], equals('daughter'));

      final response = engine.generateResponse(
        analysis: result,
        userText: utterance,
        languageCode: 'en',
      );

      // Verify response acknowledges proud feelings, emotional separation, and asks natural follow-up question
      expect(response, contains('proud'));
      expect(response, contains('emotional'));
      expect(response, contains('university'));
    });

    test('Telugu family milestone response produces culturally warm guidance', () {
      const utterance = 'మా కూతురు పై చదువుల కోసం అమెరికా వెళ్తోంది';
      final result = engine.detect(utterance);

      expect(result.intent, equals(ConversationalIntent.familyNews));
      final response = engine.generateResponse(
        analysis: result,
        userText: utterance,
        languageCode: 'te',
      );

      expect(response, contains('గర్వపడుతుంటారు'));
      expect(response, contains('విశ్వవిద్యాలయంలో'));
    });

    test('Hindi family milestone response produces warm guidance', () {
      const utterance = 'मेरी बेटी उच्च शिक्षा के लिए अमेरिका जा रही है';
      final result = engine.detect(utterance);

      expect(result.intent, equals(ConversationalIntent.familyNews));
      final response = engine.generateResponse(
        analysis: result,
        userText: utterance,
        languageCode: 'hi',
      );

      expect(response, contains('गर्व'));
      expect(response, contains('विश्वविद्यालय'));
    });

    test('VoiceConversationService generates empathetic follow-up response', () async {
      final service = VoiceConversationService();
      final reply = await service.generateResponse(
        userText: 'My daughter is going to USA for higher studies.',
        conversationHistory: [],
        languageCode: 'en',
      );
      expect(reply, contains('proud'));
      expect(reply, contains('university'));
    });
  });

  group('Voice Created Reminders Pipeline Tests', () {
    late AppDatabase database;
    late ReminderRepository repository;
    late FakeNotificationService notificationService;

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      if (Platform.isWindows) {
        open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
      }
    });

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      DatabaseProvider.setInstance(database);
      repository = ReminderRepository(database);
      notificationService = FakeNotificationService();
    });

    tearDown(() async {
      await database.close();
      DatabaseProvider.resetInstance();
    });

    test('Voice reminder command parses and saves to SQLite then schedules notification', () async {
      const matcher = VoiceIntentMatcher();
      final res = matcher.match('Remind me to call my daughter at 7 PM', languageCode: 'en');

      expect(res.intent, equals(VoiceIntent.setReminder));
      expect(res.reminderTitle?.toLowerCase(), contains('call my daughter'));
      expect(res.reminderDateTime, isNotNull);

      // Save to SQLite
      final title = res.reminderTitle!;
      final dt = res.reminderDateTime!;
      final tod = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      final daysOfWeek = 'once:${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

      final id = await repository.create(
        title: title,
        timeOfDay: tod,
        daysOfWeek: daysOfWeek,
        enabled: true,
      );
      expect(id, isNotEmpty);

      // Verify stored in SQLite
      final all = await repository.getAll();
      expect(all.length, equals(1));
      expect(all.first.title.toLowerCase(), contains('call my daughter'));

      // Schedule notification
      final notifId = notificationIdFromReminderId(id);
      final scheduled = await notificationService.scheduleReminder(
        notificationId: notifId,
        title: 'Reminder: $title',
        body: 'It is time for your reminder: $title',
        scheduledDate: dt,
      );
      expect(scheduled, isTrue);
      expect(notificationService.scheduled.containsKey(notifId), isTrue);
    });
  });
}
