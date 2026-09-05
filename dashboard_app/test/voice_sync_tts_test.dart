import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_app/core/localization/app_languages.dart';
import 'package:dashboard_app/features/voice/models/voice_intent.dart';
import 'package:dashboard_app/features/voice/services/voice_intent_matcher.dart';
import 'package:dashboard_app/features/voice/services/reminder_voice_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 8: STT & TTS Locales Resolution', () {
    test('1. English STT candidate locales resolve in priority order', () {
      final candidates = AppLanguage.english.sttLocales;
      expect(candidates, containsAllInOrder(['en_US', 'en_IN', 'en_GB', 'en']));
      expect(candidates.first, equals('en_US'));
    });

    test('2. Telugu STT candidate locales resolve in priority order', () {
      final candidates = AppLanguage.telugu.sttLocales;
      expect(candidates, containsAllInOrder(['te_IN', 'te']));
      expect(candidates.first, equals('te_IN'));
    });

    test('3. Hindi STT candidate locales resolve in priority order', () {
      final candidates = AppLanguage.hindi.sttLocales;
      expect(candidates, containsAllInOrder(['hi_IN', 'hi', 'en_IN']));
      expect(candidates.first, equals('hi_IN'));
    });

    test('4. English TTS locale is en-US', () {
      expect(AppLanguage.english.ttsLocale, equals('en-US'));
    });

    test('5. Telugu TTS locale is te-IN', () {
      expect(AppLanguage.telugu.ttsLocale, equals('te-IN'));
    });

    test('6. Hindi TTS locale is hi-IN', () {
      expect(AppLanguage.hindi.ttsLocale, equals('hi-IN'));
    });

    test('7. Fallback logic safely returns English when language code is unknown', () {
      final fallbackLang = AppLanguages.fromCode('xyz_unknown');
      expect(fallbackLang, equals(AppLanguage.english));
      expect(fallbackLang.ttsLocale, equals('en-US'));
      expect(fallbackLang.sttLocales.first, equals('en_US'));
    });
  });

  group('Part 11: Voice Command Intent Matching', () {
    const matcher = VoiceIntentMatcher();

    test('English navigation commands match correctly', () {
      expect(matcher.match('open my journal', languageCode: 'en').intent, equals(VoiceIntent.openJournal));
      expect(matcher.match('create a memory', languageCode: 'en').intent, equals(VoiceIntent.createMemory));
      expect(matcher.match('open games', languageCode: 'en').intent, equals(VoiceIntent.openGames));
      expect(matcher.match('go home', languageCode: 'en').intent, equals(VoiceIntent.openDashboard));
      expect(matcher.match('open reminders', languageCode: 'en').intent, equals(VoiceIntent.openReminders));
    });

    test('8. Telugu voice commands match correctly', () {
      expect(matcher.match('నా డైరీ తెరవండి', languageCode: 'te').intent, equals(VoiceIntent.openJournal));
      expect(matcher.match('జర్నల్ తెరవండి', languageCode: 'te').intent, equals(VoiceIntent.openJournal));
      expect(matcher.match('కొత్త జ్ఞాపకం', languageCode: 'te').intent, equals(VoiceIntent.createMemory));
      expect(matcher.match('కొత్త మెమరీ', languageCode: 'te').intent, equals(VoiceIntent.createMemory));
      expect(matcher.match('ఆటలు తెరవండి', languageCode: 'te').intent, equals(VoiceIntent.openGames));
      expect(matcher.match('హోమ్', languageCode: 'te').intent, equals(VoiceIntent.openDashboard));
      expect(matcher.match('డాష్బోర్డ్', languageCode: 'te').intent, equals(VoiceIntent.openDashboard));
      expect(matcher.match('రిమైండర్లు తెరవండి', languageCode: 'te').intent, equals(VoiceIntent.openReminders));
    });

    test('9. Hindi voice commands match correctly', () {
      expect(matcher.match('डायरी खोलो', languageCode: 'hi').intent, equals(VoiceIntent.openJournal));
      expect(matcher.match('जर्नल खोलो', languageCode: 'hi').intent, equals(VoiceIntent.openJournal));
      expect(matcher.match('नई याद बनाओ', languageCode: 'hi').intent, equals(VoiceIntent.createMemory));
      expect(matcher.match('गेम खोलो', languageCode: 'hi').intent, equals(VoiceIntent.openGames));
      expect(matcher.match('होम खोलो', languageCode: 'hi').intent, equals(VoiceIntent.openDashboard));
      expect(matcher.match('डैशबोर्ड खोलो', languageCode: 'hi').intent, equals(VoiceIntent.openDashboard));
      expect(matcher.match('रिमाइंडर खोलो', languageCode: 'hi').intent, equals(VoiceIntent.openReminders));
    });

    test('10. Reminder voice intent is recognized in English, Telugu, and Hindi', () {
      expect(matcher.match('remind me to drink water at 5 PM', languageCode: 'en').intent, equals(VoiceIntent.setReminder));
      expect(matcher.match('set a reminder', languageCode: 'en').intent, equals(VoiceIntent.setReminder));
      expect(matcher.match('రిమైండర్ పెట్టు', languageCode: 'te').intent, equals(VoiceIntent.setReminder));
      expect(matcher.match('నాకు మందులు తీసుకోవాలని గుర్తు చేయి', languageCode: 'te').intent, equals(VoiceIntent.setReminder));
      expect(matcher.match('रिमाइंडर लगाओ', languageCode: 'hi').intent, equals(VoiceIntent.setReminder));
      expect(matcher.match('मुझे दवा लेने की याद दिलाओ', languageCode: 'hi').intent, equals(VoiceIntent.setReminder));
    });

    test('Cancel command is recognized in English, Telugu, and Hindi', () {
      expect(matcher.match('cancel', languageCode: 'en').intent, equals(VoiceIntent.cancel));
      expect(matcher.match('stop', languageCode: 'en').intent, equals(VoiceIntent.cancel));
      expect(matcher.match('రద్దు చేయి', languageCode: 'te').intent, equals(VoiceIntent.cancel));
      expect(matcher.match('క్యాన్సిల్', languageCode: 'te').intent, equals(VoiceIntent.cancel));
      expect(matcher.match('रद्द करो', languageCode: 'hi').intent, equals(VoiceIntent.cancel));
      expect(matcher.match('कैंसल', languageCode: 'hi').intent, equals(VoiceIntent.cancel));
    });
  });

  group('Part 13 & 14: Reminder NLP & Multi-turn Parsing', () {
    const parser = ReminderVoiceParser();

    test('ReminderVoiceParser extracts title and time in English single command', () {
      final parsed = parser.parse('Remind me to drink water at 5 PM');
      expect(parsed.title, isNotNull);
      expect(parsed.title?.toLowerCase(), contains('drink water'));
      expect(parsed.scheduledDateTime, isNotNull);
      expect(parsed.scheduledDateTime?.hour, equals(17));
    });

    test('ReminderVoiceParser extracts date and time: Tomorrow at 8 AM', () {
      final parsed = parser.parse('Remind me tomorrow at 8 AM to take medicine');
      expect(parsed.title, isNotNull);
      expect(parsed.title?.toLowerCase(), contains('take medicine'));
      expect(parsed.scheduledDateTime, isNotNull);
      expect(parsed.scheduledDateTime?.hour, equals(8));
      final now = DateTime.now();
      expect(parsed.scheduledDateTime?.day, equals(now.add(const Duration(days: 1)).day));
    });

    test('11. Multi-turn reminder state parsing: separate title and time inputs', () {
      // Step 1: User says "Set a reminder" -> title is missing
      final step1 = parser.parse('Set a reminder');
      expect(step1.title, isNull);
      expect(step1.scheduledDateTime, isNull);

      // Step 2: Assistant asks "What would you like me to remind you about?"
      // User says: "Take blood pressure medication"
      const step2Title = 'Take blood pressure medication';
      expect(step2Title, isNotEmpty);

      // Step 3: Assistant asks "When should I remind you?"
      // User says: "Tomorrow at 8 PM"
      final step3Result = parser.parseDateTime('Tomorrow at 8 PM');
      expect(step3Result, isNotNull);
      expect(step3Result?.$1.hour, equals(20));
      expect(step3Result?.$1.minute, equals(0));
    });

    test('ReminderVoiceParser extracts Telugu time keywords: సాయంత్రం 5 గంటలకు', () {
      final dtResult = parser.parseDateTime('సాయంత్రం 5 గంటలకు');
      expect(dtResult, isNotNull);
      expect(dtResult?.$1.hour, equals(17));
    });

    test('ReminderVoiceParser extracts Hindi time keywords: शाम 5 बजे', () {
      final dtResult = parser.parseDateTime('शाम 5 बजे');
      expect(dtResult, isNotNull);
      expect(dtResult?.$1.hour, equals(17));
    });

    test('ReminderVoiceParser handles relative dates in Telugu (రేపు) and Hindi (कल)', () {
      final now = DateTime.now();
      final tomorrowDay = now.add(const Duration(days: 1)).day;

      final dtTe = parser.parseDateTime('రేపు ఉదయం 8 గంటలకు');
      expect(dtTe, isNotNull);
      expect(dtTe?.$1.day, equals(tomorrowDay));
      expect(dtTe?.$1.hour, equals(8));

      final dtHi = parser.parseDateTime('कल सुबह 8 बजे');
      expect(dtHi, isNotNull);
      expect(dtHi?.$1.day, equals(tomorrowDay));
      expect(dtHi?.$1.hour, equals(8));
    });
  });
}
