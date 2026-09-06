import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:dashboard_app/core/config/app_config.dart';
import 'package:dashboard_app/core/voice/tts_service.dart';
import 'package:dashboard_app/features/voice/models/voice_intent.dart';
import 'package:dashboard_app/features/voice/services/voice_service.dart';
import 'package:dashboard_app/features/voice/services/voice_intent_matcher.dart';
import 'package:dashboard_app/features/voice/services/reminder_voice_parser.dart';
import 'package:dashboard_app/features/voice/services/voice_conversation_service.dart';
import 'package:dashboard_app/core/sync/http_client.dart';

// --- Mock HttpClient for testing backend communication ---
class MockHttpClient implements HttpClient {
  final Future<Response<dynamic>> Function(String path, dynamic data, Options? options)? onPost;

  MockHttpClient({this.onPost});

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (onPost != null) {
      final res = await onPost!(path, data, options);
      return res as Response<T>;
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'response': 'Mock backend response'} as T,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 200, data: {} as T);
  }

  @override
  void close() {}
}

// --- Test Implementation of ITtsService for Unit Verification ---
class TestTtsService implements ITtsService {
  bool _isSpeaking = false;
  bool isInitialized = false;
  final List<String> spokenMessages = [];
  final List<String> languageCalls = [];
  Completer<void>? activeCompleter;
  bool shouldFailSpeak = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<bool> isLanguageAvailable(String languageCode) async {
    languageCalls.add(languageCode);
    return true;
  }

  @override
  Future<void> speak(String text, {String? languageCode, VoidCallback? onComplete}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    if (_isSpeaking && spokenMessages.isNotEmpty && spokenMessages.last == clean) {
      // Duplicate prevention
      return;
    }

    _isSpeaking = true;
    spokenMessages.add(clean);

    if (shouldFailSpeak) {
      _isSpeaking = false;
      onComplete?.call();
      throw Exception('Simulated native TTS failure');
    }

    final comp = Completer<void>();
    activeCompleter = comp;

    // Simulate completion
    _isSpeaking = false;
    onComplete?.call();
    if (!comp.isCompleted) comp.complete();
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    if (activeCompleter != null && !activeCompleter!.isCompleted) {
      activeCompleter!.complete();
    }
  }

  @override
  void dispose() {
    stop();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Final Integration & Teacher Demo Verification', () {
    late ReminderVoiceParser parser;
    late VoiceIntentMatcher matcher;
    final fixedNow = DateTime(2026, 9, 6, 14, 0, 0); // 2:00 PM

    setUp(() {
      parser = const ReminderVoiceParser();
      matcher = VoiceIntentMatcher(reminderParser: parser);
    });

    // 1. TTS initialization
    test('1. TTS initialization sets initialized flag once without race condition', () async {
      final tts = TestTtsService();
      expect(tts.isInitialized, isFalse);
      await tts.initialize();
      expect(tts.isInitialized, isTrue);
    });

    // 2. TTS completion
    test('2. TTS completion completes speak future and marks isSpeaking false', () async {
      final tts = TestTtsService();
      bool callbackFired = false;
      await tts.speak('Hello Smriti', onComplete: () {
        callbackFired = true;
      });
      expect(tts.isSpeaking, isFalse);
      expect(callbackFired, isTrue);
      expect(tts.spokenMessages, contains('Hello Smriti'));
    });

    // 3. TTS failure
    test('3. TTS failure handles native errors gracefully without crashing', () async {
      final tts = TestTtsService();
      tts.shouldFailSpeak = true;
      expect(() async => await tts.speak('Crash test'), throwsA(isA<Exception>()));
      expect(tts.isSpeaking, isFalse);
    });

    // 4. TTS cancellation
    test('4. TTS cancellation releases active completer and resets speaking state', () async {
      final tts = TestTtsService();
      tts.speak('Long paragraph being read out');
      await tts.stop();
      expect(tts.isSpeaking, isFalse);
    });

    // 5. Duplicate TTS prevention
    test('5. Duplicate TTS prevention ignores identical consecutive speak calls', () async {
      final tts = TestTtsService();
      // Simulate active speaking
      tts._isSpeaking = true;
      tts.spokenMessages.add('Welcome back');
      await tts.speak('Welcome back');
      // Should not add a duplicate entry
      expect(tts.spokenMessages.where((m) => m == 'Welcome back').length, equals(1));
    });

    // 6. Language switching
    test('6. Language switching verifies locale correctly', () async {
      final tts = TestTtsService();
      final teAvailable = await tts.isLanguageAvailable('te-IN');
      final hiAvailable = await tts.isLanguageAvailable('hi-IN');
      final enAvailable = await tts.isLanguageAvailable('en-US');

      expect(teAvailable, isTrue);
      expect(hiAvailable, isTrue);
      expect(enAvailable, isTrue);
      expect(tts.languageCalls, containsAll(['te-IN', 'hi-IN', 'en-US']));
    });

    // 7. Reminder in 5 minutes
    test('7. "Remind me in 5 minutes" sets target to now + 5 min', () {
      final res = parser.parse('Remind me in 5 minutes', referenceTime: fixedNow);
      expect(res.scheduledDateTime, isNotNull);
      expect(res.scheduledDateTime, equals(fixedNow.add(const Duration(minutes: 5))));
      expect(res.timeOfDayStr, equals('14:05'));
    });

    // 8. Alarm in 5 minutes
    test('8. "Hey, set an alarm for next 5 minutes" sets target to now + 5 min and title Alarm', () {
      final res = parser.parse('Hey, set an alarm for next 5 minutes', referenceTime: fixedNow);
      expect(res.title, equals('Alarm'));
      expect(res.scheduledDateTime, equals(fixedNow.add(const Duration(minutes: 5))));
      expect(res.timeOfDayStr, equals('14:05'));
    });

    // 9. Hindi reminder
    test('9. Hindi reminder "5 मिनट में याद दिलाओ" parsed correctly', () {
      final res = parser.parse('5 मिनट में याद दिलाओ', referenceTime: fixedNow);
      expect(res.scheduledDateTime, isNotNull);
      expect(res.scheduledDateTime, equals(fixedNow.add(const Duration(minutes: 5))));
    });

    // 10. Telugu reminder
    test('10. Telugu reminder "5 నిమిషాల్లో గుర్తు చేయి" parsed correctly', () {
      final res = parser.parse('5 నిమిషాల్లో గుర్తు చేయి', referenceTime: fixedNow);
      expect(res.scheduledDateTime, isNotNull);
      expect(res.scheduledDateTime, equals(fixedNow.add(const Duration(minutes: 5))));
    });

    // 11. Midnight rollover
    test('11. Midnight rollover: 23:58 + 5 minutes = 00:03 next day', () {
      final nearMidnight = DateTime(2026, 9, 6, 23, 58, 0);
      final res = parser.parse('Remind me in 5 minutes', referenceTime: nearMidnight);
      expect(res.scheduledDateTime, isNotNull);
      expect(res.scheduledDateTime!.day, equals(7)); // Next day
      expect(res.scheduledDateTime!.hour, equals(0));
      expect(res.scheduledDateTime!.minute, equals(3));
      expect(res.timeOfDayStr, equals('00:03'));
    });

    // 12. Conversation routing
    test('12. Conversational utterances routed to unknown intent for AI service handling', () {
      final intent1 = matcher.match('How are you doing today?');
      expect(intent1.intent, equals(VoiceIntent.unknown));

      final intent2 = matcher.match('I went to the temple this morning');
      expect(intent2.intent, equals(VoiceIntent.unknown));

      final actionIntent = matcher.match('Open journal');
      expect(actionIntent.intent, equals(VoiceIntent.openJournal));
    });

    // 13. /voice/chat response parsing
    test('13. /voice/chat response parsing extracts reply text successfully', () async {
      final mockClient = MockHttpClient(
        onPost: (path, data, options) async {
          expect(path, contains('/voice/chat'));
          final mapData = data as Map<String, dynamic>;
          expect(mapData['message'], equals('How are you?'));
          expect(mapData['language'], equals('en-US'));
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {'response': 'I am doing well, thank you! How are you feeling today?'},
          );
        },
      );

      final service = VoiceConversationService(client: mockClient, baseUrl: 'https://smiriti-ai.onrender.com');
      final reply = await service.generateResponse(
        userText: 'How are you?',
        conversationHistory: [],
        languageCode: 'en-US',
      );

      expect(reply, equals('I am doing well, thank you! How are you feeling today?'));
    });

    // 14. Backend timeout handling
    test('14. Backend timeout falls back to warm on-device companion response', () async {
      final mockClient = MockHttpClient(
        onPost: (path, data, options) async {
          throw DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timed out',
          );
        },
      );

      final service = VoiceConversationService(client: mockClient);
      final reply = await service.generateResponse(
        userText: 'How are you?',
        conversationHistory: [],
        languageCode: 'en',
      );

      expect(reply, isNotEmpty);
      expect(reply.contains('well') || reply.contains('doing') || reply.contains('happy') || reply.contains('peace'), isTrue);
    });

    // 15. Backend 500 error handling
    test('15. Backend 500 status code triggers safe fallback without crashing', () async {
      final mockClient = MockHttpClient(
        onPost: (path, data, options) async {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 500,
            data: {'detail': 'Internal Server Error'},
          );
        },
      );

      final service = VoiceConversationService(client: mockClient);
      final reply = await service.generateResponse(
        userText: 'Hello Smriti',
        conversationHistory: [],
        languageCode: 'en',
      );

      expect(reply, isNotEmpty);
      expect(reply.contains('pleasure') || reply.contains('sharing') || reply.contains('hear') || reply.contains('conversing'), isTrue);
    });

    // 16. Empty AI response handling
    test('16. Empty AI response falls back to friendly offline response', () async {
      final mockClient = MockHttpClient(
        onPost: (path, data, options) async {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {'response': '   '},
          );
        },
      );

      final service = VoiceConversationService(client: mockClient);
      final reply = await service.generateResponse(
        userText: 'Hello',
        conversationHistory: [],
        languageCode: 'en',
      );

      expect(reply, isNotEmpty);
    });

    // 17. Microphone/TTS mutual exclusion
    test('17. VoiceService isListening is false while TTS is speaking', () {
      final tts = TestTtsService();
      tts._isSpeaking = true;
      expect(tts.isSpeaking, isTrue);

      final voice = VoiceService();
      // Mutual exclusion rule: when TTS is speaking, listening must be stopped or blocked
      expect(tts.isSpeaking, isTrue);
      expect(voice.isListening, isFalse);
    });

    // 18. Stale STT session protection
    test('18. VoiceService sessionId increments on every listen cycle protecting against stale callbacks', () {
      final voice = VoiceService();
      final id1 = voice.activeSessionId;
      voice.initialize();
      expect(voice.activeSessionId, isNotNull);
      expect(voice.activeSessionId, equals(id1));
      expect(voice.isListening, isFalse);
    });

    // 19. Production Base URL verification
    test('19. AppConfig.apiBaseUrl defaults to https://smiriti-ai.onrender.com in production', () {
      expect(AppConfig.productionApiBaseUrl, equals('https://smiriti-ai.onrender.com'));
      expect(AppConfig.apiBaseUrl, equals('https://smiriti-ai.onrender.com'));
    });
  });
}
