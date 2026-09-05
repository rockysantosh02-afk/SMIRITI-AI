import 'package:flutter_test/flutter_test.dart';

import 'package:dashboard_app/features/voice/services/language_detector.dart';

void main() {
  group('LanguageDetector & Voice Response Modes Tests', () {
    test('Detects Telugu speech via Unicode script range', () {
      expect(
        LanguageDetector.detectLanguageCode('నా డైరీ తెరవండి'),
        equals('te'),
      );
      expect(
        LanguageDetector.detectLanguageCode('రేపు ఉదయం 8 గంటలకు మందులు'),
        equals('te'),
      );
      expect(
        LanguageDetector.detectLanguageCode('రిమైండర్ పెట్టు'),
        equals('te'),
      );
    });

    test('Detects Hindi / Devanagari speech via Unicode script range', () {
      expect(
        LanguageDetector.detectLanguageCode('डायरी खोलो'),
        equals('hi'),
      );
      expect(
        LanguageDetector.detectLanguageCode('कल सुबह 8 बजे दवा लेने का रिमाइंडर लगाओ'),
        equals('hi'),
      );
      expect(
        LanguageDetector.detectLanguageCode('खेल खोलो'),
        equals('hi'),
      );
    });

    test('Detects English speech via Latin script', () {
      expect(
        LanguageDetector.detectLanguageCode('Open my journal'),
        equals('en'),
      );
      expect(
        LanguageDetector.detectLanguageCode('Remind me to drink water tomorrow at 8 AM'),
        equals('en'),
      );
      expect(
        LanguageDetector.detectLanguageCode('Cancel reminder'),
        equals('en'),
      );
    });

    test('VoiceResponseLanguageMode.sameAsDetectedSpeech (default) responds in spoken language', () {
      // User app is English, but user speaks Telugu -> Assistant must respond in Telugu
      final responseTe = LanguageDetector.resolveResponseLanguage(
        spokenText: 'రేపు ఉదయం 8 గంటలకు మందులు',
        appLanguageCode: 'en',
        mode: VoiceResponseLanguageMode.sameAsDetectedSpeech,
      );
      expect(responseTe, equals('te'));

      // User app is English, but user speaks Hindi -> Assistant must respond in Hindi
      final responseHi = LanguageDetector.resolveResponseLanguage(
        spokenText: 'कल सुबह 8 बजे दवा',
        appLanguageCode: 'en',
        mode: VoiceResponseLanguageMode.sameAsDetectedSpeech,
      );
      expect(responseHi, equals('hi'));

      // User app is Telugu, but user speaks English -> Assistant must respond in English
      final responseEn = LanguageDetector.resolveResponseLanguage(
        spokenText: 'Set reminder for medicine',
        appLanguageCode: 'te',
        mode: VoiceResponseLanguageMode.sameAsDetectedSpeech,
      );
      expect(responseEn, equals('en'));
    });

    test('VoiceResponseLanguageMode.sameAsAppLanguage responds in app language', () {
      final response = LanguageDetector.resolveResponseLanguage(
        spokenText: 'రేపు ఉదయం 8 గంటలకు మందులు',
        appLanguageCode: 'hi',
        mode: VoiceResponseLanguageMode.sameAsAppLanguage,
      );
      expect(response, equals('hi'));
    });

    test('Fixed language override modes always return requested language', () {
      expect(
        LanguageDetector.resolveResponseLanguage(
          spokenText: 'రేపు ఉదయం 8 గంటలకు మందులు',
          appLanguageCode: 'te',
          mode: VoiceResponseLanguageMode.alwaysEnglish,
        ),
        equals('en'),
      );

      expect(
        LanguageDetector.resolveResponseLanguage(
          spokenText: 'Set reminder for medicine',
          appLanguageCode: 'en',
          mode: VoiceResponseLanguageMode.alwaysTelugu,
        ),
        equals('te'),
      );

      expect(
        LanguageDetector.resolveResponseLanguage(
          spokenText: 'Set reminder for medicine',
          appLanguageCode: 'en',
          mode: VoiceResponseLanguageMode.alwaysHindi,
        ),
        equals('hi'),
      );
    });

    test('Fallback hierarchy safely resolves to English on empty/unknown input', () {
      expect(
        LanguageDetector.resolveResponseLanguage(
          spokenText: '',
          appLanguageCode: 'invalid',
          mode: VoiceResponseLanguageMode.sameAsDetectedSpeech,
        ),
        equals('en'),
      );
    });
  });
}
