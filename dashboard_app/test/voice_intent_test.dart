import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_app/features/voice/models/voice_intent.dart';
import 'package:dashboard_app/features/voice/services/voice_intent_matcher.dart';

void main() {
  group('Phase 3.3: Voice Intent Matcher Tests', () {
    const matcher = VoiceIntentMatcher();

    // --- 1. Open Journal Tests across all 4 languages ---
    test('English Open Journal matching', () {
      final res1 = matcher.match('Open my journal', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.openJournal));
      expect(res1.targetRoute, equals('/journal'));

      final res2 = matcher.match('show memories', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openJournal));

      final res3 = matcher.match('view diary', languageCode: 'en');
      expect(res3.intent, equals(VoiceIntent.openJournal));
    });

    test('Assamese Open Journal matching', () {
      final res = matcher.match('মোৰ ডায়েরী খোলক', languageCode: 'as');
      expect(res.intent, equals(VoiceIntent.openJournal));
      expect(res.targetRoute, equals('/journal'));
      expect(res.feedbackMessage, contains('স্মৃতি'));
    });

    test('Bengali Open Journal matching', () {
      final res = matcher.match('আমার ডায়েরি খোলো', languageCode: 'bn');
      expect(res.intent, equals(VoiceIntent.openJournal));
      expect(res.targetRoute, equals('/journal'));
      expect(res.feedbackMessage, contains('স্মৃতি'));
    });

    test('Hindi Open Journal matching', () {
      final res = matcher.match('मेरी डायरी खोलो', languageCode: 'hi');
      expect(res.intent, equals(VoiceIntent.openJournal));
      expect(res.targetRoute, equals('/journal'));
      expect(res.feedbackMessage, contains('यादों'));
    });

    // --- 2. Create Memory Tests ---
    test('Create Memory matching across variations', () {
      final resEn = matcher.match('create a memory', languageCode: 'en');
      expect(resEn.intent, equals(VoiceIntent.createMemory));
      expect(resEn.targetRoute, equals('/journal'));

      final resAs = matcher.match('নতুন স্মৃতি লিখক', languageCode: 'as');
      expect(resAs.intent, equals(VoiceIntent.createMemory));

      final resBn = matcher.match('নতুন স্মৃতি যোগ করো', languageCode: 'bn');
      expect(resBn.intent, equals(VoiceIntent.createMemory));

      final resHi = matcher.match('नई याद लिखो', languageCode: 'hi');
      expect(resHi.intent, equals(VoiceIntent.createMemory));
    });

    // --- 3. Dashboard / Home Tests ---
    test('Dashboard / Home matching across languages', () {
      final resEn = matcher.match('go home', languageCode: 'en');
      expect(resEn.intent, equals(VoiceIntent.openDashboard));
      expect(resEn.targetRoute, equals('/dashboard'));

      final resAs = matcher.match('ঘৰলৈ যাওক', languageCode: 'as');
      expect(resAs.intent, equals(VoiceIntent.openDashboard));

      final resBn = matcher.match('বাড়ি যাও', languageCode: 'bn');
      expect(resBn.intent, equals(VoiceIntent.openDashboard));

      final resHi = matcher.match('घर जाओ', languageCode: 'hi');
      expect(resHi.intent, equals(VoiceIntent.openDashboard));
    });

    // --- 4. Games Tests ---
    test('Open Games matching across languages', () {
      final resEn = matcher.match('play a game', languageCode: 'en');
      expect(resEn.intent, equals(VoiceIntent.openGames));
      expect(resEn.targetRoute, equals('/games'));

      final resAs = matcher.match('খেল খোলক', languageCode: 'as');
      expect(resAs.intent, equals(VoiceIntent.openGames));

      final resBn = matcher.match('খেলা খোলো', languageCode: 'bn');
      expect(resBn.intent, equals(VoiceIntent.openGames));

      final resHi = matcher.match('खेल खोलो', languageCode: 'hi');
      expect(resHi.intent, equals(VoiceIntent.openGames));
    });

    // --- 5. Reminders Notice (Graceful, no Phase 3.4 trigger) ---
    test('Reminders inquiry returns graceful coming-soon notice without route', () {
      final resEn = matcher.match('show reminders', languageCode: 'en');
      expect(resEn.intent, equals(VoiceIntent.openReminders));
      expect(resEn.targetRoute, isNull);
      expect(resEn.feedbackMessage, contains('Reminders will be available soon'));

      final resAs = matcher.match('সোঁৱৰণী', languageCode: 'as');
      expect(resAs.intent, equals(VoiceIntent.openReminders));
      expect(resAs.targetRoute, isNull);
      expect(resAs.feedbackMessage, contains('ৰিমাইণ্ডাৰ'));
    });

    // --- 6. Unknown / Empty command handling ---
    test('Unknown command returns unknown intent and calm feedback', () {
      final res = matcher.match('what is the weather today in guwahati', languageCode: 'en');
      expect(res.intent, equals(VoiceIntent.unknown));
      expect(res.targetRoute, isNull);
      expect(res.feedbackMessage, contains('didn\'t understand'));
    });

    test('Empty or whitespace command returns unknown intent without crashing', () {
      final res1 = matcher.match('', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.unknown));

      final res2 = matcher.match('   \n  \t  ', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.unknown));
    });

    // --- 7. Resiliency: Mixed casing, Punctuation, Whitespace ---
    test('Mixed casing is normalized correctly', () {
      final res = matcher.match('OpEn My JoUrNaL', languageCode: 'en');
      expect(res.intent, equals(VoiceIntent.openJournal));
    });

    test('Punctuation is stripped and does not prevent matching', () {
      final res1 = matcher.match('Please, open my journal?!', languageCode: 'en');
      expect(res1.intent, equals(VoiceIntent.openJournal));

      final res2 = matcher.match('play a game.', languageCode: 'en');
      expect(res2.intent, equals(VoiceIntent.openGames));
    });

    test('Extra whitespace is collapsed safely', () {
      final res = matcher.match('   go       home   ', languageCode: 'en');
      expect(res.intent, equals(VoiceIntent.openDashboard));
    });
  });
}
