import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dashboard_app/features/voice/models/voice_intent.dart';
import 'package:dashboard_app/features/voice/screens/voice_assistant_screen.dart';
import 'package:dashboard_app/features/voice/services/voice_service.dart';
import 'package:dashboard_app/features/voice/services/voice_intent_matcher.dart';

/// Test double for VoiceService allowing precise state and lifecycle inspection.
class MockVoiceService with ChangeNotifier implements IVoiceService {
  VoiceAssistantStatus _status = VoiceAssistantStatus.idle;
  String _words = '';
  VoiceIntentResult? _intent;
  final VoiceIntentMatcher _matcher = const VoiceIntentMatcher();

  int startListeningCount = 0;
  int stopListeningCount = 0;
  String? lastLanguageCode;
  ValueChanged<String>? _activeResultCallback;
  VoidCallback? _activeCompleteCallback;

  void setStatusForTesting(VoiceAssistantStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  @override
  VoiceAssistantStatus get status => _status;

  @override
  bool get isListening => _status == VoiceAssistantStatus.listening;

  @override
  String get lastRecognizedWords => _words;

  @override
  VoiceIntentResult? get lastIntentResult => _intent;

  @override
  List<stt.LocaleName> get availableLocales => [];

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required ValueChanged<String> onResult,
    VoidCallback? onComplete,
    String? languageCode,
  }) async {
    startListeningCount++;
    _status = VoiceAssistantStatus.listening;
    lastLanguageCode = languageCode;
    _activeResultCallback = onResult;
    _activeCompleteCallback = onComplete;
    notifyListeners();
  }

  void simulateSpeechInput(String text) {
    _words = text;
    _activeResultCallback?.call(text);
    notifyListeners();
  }

  void simulateSpeechFinish(String text) {
    _words = text;
    _intent = _matcher.match(text, languageCode: lastLanguageCode ?? 'en');
    _status = _intent?.intent == VoiceIntent.unknown
        ? VoiceAssistantStatus.notUnderstood
        : VoiceAssistantStatus.success;
    notifyListeners();
    _activeCompleteCallback?.call();
  }

  @override
  Future<void> stopListening() async {
    stopListeningCount++;
    simulateSpeechFinish(_words);
  }

  @override
  Future<void> cancelListening() async {
    _status = VoiceAssistantStatus.idle;
    _words = '';
    _intent = null;
    notifyListeners();
  }
}

void main() {
  group('Phase 3.3: VoiceAssistantScreen Widget & UI Tests', () {
    testWidgets('Privacy Verification: Microphone does NOT activate on screen load',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      // Absolute Privacy Rule: startListening must NEVER be called on mount
      expect(mockVoice.startListeningCount, equals(0));
      expect(mockVoice.isListening, isFalse);
      expect(find.textContaining('Tap to Speak'), findsOneWidget);
    });

    testWidgets('Microphone button exists with comfortable touch target >= 80dp',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      // Find the circular mic container
      final micFinder = find.bySemanticsLabel('Start listening');
      expect(micFinder, findsOneWidget);

      final Size buttonSize = tester.getSize(micFinder);
      expect(buttonSize.width, greaterThanOrEqualTo(80.0));
      expect(buttonSize.height, greaterThanOrEqualTo(80.0));
    });

    testWidgets('Explicit button tap transitions to listening state and shows Stop button',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      // Tap microphone
      await tester.tap(find.bySemanticsLabel('Start listening'));
      await tester.pump();

      expect(mockVoice.startListeningCount, equals(1));
      expect(mockVoice.isListening, isTrue);
      expect(find.bySemanticsLabel('Stop listening'), findsOneWidget);
      expect(find.textContaining('Listening'), findsOneWidget);
    });

    testWidgets('Live recognized speech displays in transcription container',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Start listening'));
      await tester.pump();

      // Simulate live incoming spoken words
      mockVoice.simulateSpeechInput('Open my journal');
      await tester.pump();

      expect(find.text('Open my journal'), findsOneWidget);
    });

    testWidgets('Recognized actionable intent displays success card and feedback',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Start listening'));
      await tester.pump();

      // Finish speech with known command
      mockVoice.simulateSpeechFinish('open my journal');
      await tester.pump();

      expect(find.textContaining('Opening your Journal'), findsOneWidget);
      expect(find.textContaining('Go Now'), findsOneWidget);
    });

    testWidgets('Unknown command displays calm, non-distressing feedback',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Start listening'));
      await tester.pump();

      // Finish speech with unknown phrase
      mockVoice.simulateSpeechFinish('fly to the moon');
      await tester.pump();

      expect(find.textContaining('didn\'t understand'), findsOneWidget);
    });

    testWidgets('Permission denied displays polite non-blocking explanation',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      mockVoice.setStatusForTesting(VoiceAssistantStatus.permissionDenied);
      await tester.pump();

      expect(find.textContaining('Microphone permission is needed'), findsOneWidget);
      expect(find.textContaining('You can still use Smriti AI without voice'), findsOneWidget);
    });

    testWidgets('Speech unavailable displays gentle fallback message',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      mockVoice.setStatusForTesting(VoiceAssistantStatus.unavailable);
      await tester.pump();

      expect(find.textContaining('Voice commands are not available right now'), findsOneWidget);
      expect(find.textContaining('You can continue using the buttons'), findsOneWidget);
    });

    testWidgets('Duplicate rapid button taps do not create multiple listening sessions',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      // Tap to start
      await tester.tap(find.bySemanticsLabel('Start listening'));
      await tester.pump();

      expect(mockVoice.startListeningCount, equals(1));

      // Tapping again while listening triggers stopListening, not a second start!
      await tester.tap(find.bySemanticsLabel('Stop listening'));
      await tester.pump();

      expect(mockVoice.startListeningCount, equals(1));
      expect(mockVoice.stopListeningCount, equals(1));
    });

    testWidgets('Displays accurate privacy statement clarifying app vs device speech service',
        (tester) async {
      final mockVoice = MockVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: VoiceAssistantScreen(voiceService: mockVoice),
        ),
      );
      await tester.pump();

      // Verify accurate privacy statement and device service clarification
      expect(
        find.textContaining('Smriti AI does not record, save, or upload your voice recordings'),
        findsOneWidget,
      );
      expect(
        find.textContaining("Speech recognition is handled by your device's speech service"),
        findsOneWidget,
      );
    });
  });
}
