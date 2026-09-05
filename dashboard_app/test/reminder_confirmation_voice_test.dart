import 'package:flutter_test/flutter_test.dart';

import 'package:dashboard_app/features/voice/services/reminder_voice_parser.dart';
import 'package:dashboard_app/features/voice/voice_prompts.dart';

void main() {
  group('Smart Voice Reminder Parser & Confirmation Tests', () {
    const parser = ReminderVoiceParser();
    final fixedNow = DateTime(2026, 9, 5, 10, 0); // 10:00 AM

    test('Single-turn reminder parsing in English', () {
      final res = parser.parse(
        'Remind me to take medicine tomorrow at 8 AM',
        referenceTime: fixedNow,
      );

      expect(res.title?.toLowerCase(), contains('medicine'));
      expect(res.scheduledDateTime, isNotNull);
      expect(res.scheduledDateTime!.day, equals(6)); // Tomorrow
      expect(res.scheduledDateTime!.hour, equals(8));
      expect(res.scheduledDateTime!.minute, equals(0));
      expect(res.timeOfDayStr, equals('08:00'));
      expect(res.isComplete, isTrue);
    });

    test('Single-turn reminder parsing in Telugu', () {
      final res = parser.parse(
        'రేపు ఉదయం 8 గంటలకు మందులు',
        referenceTime: fixedNow,
      );

      expect(res.title, isNotNull);
      expect(res.title, contains('మందులు'));
      expect(res.scheduledDateTime, isNotNull);
      expect(res.scheduledDateTime!.day, equals(6)); // Tomorrow
      expect(res.scheduledDateTime!.hour, equals(8));
      expect(res.timeOfDayStr, equals('08:00'));
    });

    test('Single-turn reminder parsing in Hindi', () {
      final res = parser.parse(
        'कल सुबह 8 बजे दवा',
        referenceTime: fixedNow,
      );

      expect(res.title, isNotNull);
      expect(res.title, contains('दवा'));
      expect(res.scheduledDateTime, isNotNull);
      expect(res.scheduledDateTime!.day, equals(6)); // Tomorrow
      expect(res.scheduledDateTime!.hour, equals(8));
      expect(res.timeOfDayStr, equals('08:00'));
    });

    test('Multi-turn reminder: parseTitle extracts title cleanly', () {
      expect(
        ReminderVoiceParser.parseTitle('Take blood pressure medicine'),
        equals('Take blood pressure medicine'),
      );
      expect(
        ReminderVoiceParser.parseTitle('మందులు వేసుకోవాలి'),
        contains('మందులు'),
      );
      expect(
        ReminderVoiceParser.parseTitle('दवा लेनी है'),
        contains('दवा'),
      );
    });

    test('Multi-turn reminder: parseDateTime extracts follow-up date and time', () {
      final enTime = parser.parseDateTime('Tomorrow at 5 PM', now: fixedNow);
      expect(enTime, isNotNull);
      expect(enTime!.$1.day, equals(6));
      expect(enTime.$1.hour, equals(17));
      expect(enTime.$2, equals('17:00'));

      final teTime = parser.parseDateTime('రేపు సాయంత్రం 5 గంటలకు', now: fixedNow);
      expect(teTime, isNotNull);
      expect(teTime!.$1.day, equals(6));
      expect(teTime.$1.hour, equals(17));

      final hiTime = parser.parseDateTime('कल शाम 5 बजे', now: fixedNow);
      expect(hiTime, isNotNull);
      expect(hiTime!.$1.day, equals(6));
      expect(hiTime.$1.hour, equals(17));
    });

    test('Voice confirmation: affirmative keywords in English, Telugu, Hindi', () {
      // English
      expect(ReminderVoiceParser.isAffirmative('yes'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('sure'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('ok'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('save it'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('confirm'), isTrue);

      // Telugu
      expect(ReminderVoiceParser.isAffirmative('అవును'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('సరే'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('సేవ్ చేయి'), isTrue);

      // Hindi
      expect(ReminderVoiceParser.isAffirmative('हाँ'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('हां'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('ठीक है'), isTrue);
      expect(ReminderVoiceParser.isAffirmative('सेव करो'), isTrue);
    });

    test('Voice confirmation: negative / cancellation keywords in English, Telugu, Hindi', () {
      // English
      expect(ReminderVoiceParser.isNegative('no'), isTrue);
      expect(ReminderVoiceParser.isNegative('cancel'), isTrue);
      expect(ReminderVoiceParser.isNegative('stop'), isTrue);
      expect(ReminderVoiceParser.isNegative('never mind'), isTrue);

      // Telugu
      expect(ReminderVoiceParser.isNegative('వద్దు'), isTrue);
      expect(ReminderVoiceParser.isNegative('కాదు'), isTrue);
      expect(ReminderVoiceParser.isNegative('రద్దు చేయి'), isTrue);
      expect(ReminderVoiceParser.isNegative('అవసరం లేదు'), isTrue);

      // Hindi
      expect(ReminderVoiceParser.isNegative('नहीं'), isTrue);
      expect(ReminderVoiceParser.isNegative('ना'), isTrue);
      expect(ReminderVoiceParser.isNegative('रद्द करो'), isTrue);
      expect(ReminderVoiceParser.isNegative('मत करो'), isTrue);
    });

    test('VoicePrompts.formatConfirmationPrompt formats localized prompt correctly', () {
      final promptEn = VoicePrompts.formatConfirmationPrompt(
        title: 'take medicine',
        dateStr: 'tomorrow',
        timeStr: '8 AM',
        languageCode: 'en',
      );
      expect(promptEn, contains('I will remind you tomorrow at 8 AM to take medicine'));
      expect(promptEn, contains('Should I save this reminder?'));

      final promptTe = VoicePrompts.formatConfirmationPrompt(
        title: 'మందులు',
        dateStr: 'రేపు',
        timeStr: 'ఉదయం 8 గంటలకు',
        languageCode: 'te',
      );
      expect(promptTe, contains('రేపు'));
      expect(promptTe, contains('ఉదయం 8 గంటలకు'));
      expect(promptTe, contains('మందులు'));
      expect(promptTe, contains('సేవ్ చేయమంటారా?'));

      final promptHi = VoicePrompts.formatConfirmationPrompt(
        title: 'दवा',
        dateStr: 'कल',
        timeStr: 'सुबह 8 बजे',
        languageCode: 'hi',
      );
      expect(promptHi, contains('कल'));
      expect(promptHi, contains('सुबह 8 बजे'));
      expect(promptHi, contains('दवा'));
      expect(promptHi, contains('सहेज लूँ?'));
    });
  });
}
