import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sqlite3/open.dart';
import 'package:dashboard_app/features/journal/journal_entry_screen.dart';
import 'package:dashboard_app/features/voice/models/voice_intent.dart';
import 'package:dashboard_app/features/voice/services/voice_service.dart';
import 'package:dashboard_app/core/database/repositories/journal_repository.dart';
import 'package:dashboard_app/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

/// Fake VoiceService for testing dictation without native audio hardware.
class FakeVoiceService with ChangeNotifier implements IVoiceService {
  VoiceAssistantStatus _status = VoiceAssistantStatus.idle;
  String _words = '';
  ValueChanged<String>? _onResult;
  VoidCallback? _onComplete;

  int startListeningCallCount = 0;

  @override
  VoiceAssistantStatus get status => _status;

  @override
  bool get isListening => _status == VoiceAssistantStatus.listening;

  @override
  String get lastRecognizedWords => _words;

  @override
  VoiceIntentResult? get lastIntentResult => null;

  @override
  List<stt.LocaleName> get availableLocales => [];

  @override
  bool isLanguageSupported(String langCode) => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required ValueChanged<String> onResult,
    VoidCallback? onComplete,
    String? languageCode,
  }) async {
    startListeningCallCount++;
    _status = VoiceAssistantStatus.listening;
    _onResult = onResult;
    _onComplete = onComplete;
    notifyListeners();
  }

  void simulateSpeech(String text) {
    _words = text;
    _onResult?.call(text);
  }

  void simulateCompletion() {
    _status = VoiceAssistantStatus.idle;
    notifyListeners();
    _onComplete?.call();
  }

  @override
  Future<void> stopListening() async {
    simulateCompletion();
  }

  @override
  Future<void> cancelListening() async {
    _status = VoiceAssistantStatus.idle;
    _words = '';
    notifyListeners();
  }
}

void main() {
  group('Phase 3.3: Journal Voice Dictation Tests', () {
    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      if (Platform.isWindows) {
        open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
      }
    });

    // --- 1. Pure Unit Tests for appendDictatedText ---
    test('Dictation into completely empty body sets body to dictated text', () {
      final result = JournalEntryScreen.appendDictatedText('', 'First thought dictated');
      expect(result, equals('First thought dictated'));
    });

    test('Dictation appends safely to existing body with newline separator', () {
      const existing = 'Yesterday I went to the temple.';
      const dictated = 'I met my old friend.';
      final result = JournalEntryScreen.appendDictatedText(existing, dictated);

      expect(result, equals('Yesterday I went to the temple.\nI met my old friend.'));
    });

    test('Multiple sequential dictations append line by line without overwriting', () {
      var body = '';
      body = JournalEntryScreen.appendDictatedText(body, 'Line one');
      expect(body, equals('Line one'));

      body = JournalEntryScreen.appendDictatedText(body, 'Line two');
      expect(body, equals('Line one\nLine two'));

      body = JournalEntryScreen.appendDictatedText(body, 'Line three');
      expect(body, equals('Line one\nLine two\nLine three'));
    });

    test('Cancelled or empty dictation result does NOT alter existing text', () {
      const existing = 'Existing preserved memory';
      expect(JournalEntryScreen.appendDictatedText(existing, ''), equals(existing));
      expect(JournalEntryScreen.appendDictatedText(existing, '   '), equals(existing));
    });

    test('Dictated text trims extra leading and trailing whitespace cleanly', () {
      const existing = '  Clean start  ';
      const dictated = '   Added thought   ';
      expect(
        JournalEntryScreen.appendDictatedText(existing, dictated),
        equals('Clean start\nAdded thought'),
      );
    });

    // --- 2. Widget Integration Tests for Journal Entry Dictation ---
    testWidgets('Voice Dictation button activates listening and appends text to body without auto-saving',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      DatabaseProvider.setInstance(db);
      addTearDown(() {
        DatabaseProvider.resetInstance();
        db.close();
      });
      final repo = JournalRepository(db);
      final fakeVoice = FakeVoiceService();

      await tester.pumpWidget(
        MaterialApp(
          home: JournalEntryScreen(
            repository: repo,
            voiceService: fakeVoice,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial state: Body is empty
      final bodyFieldFinder = find.byKey(const Key('journal_body_input'));
      expect(tester.widget<TextField>(bodyFieldFinder).controller?.text, isEmpty);

      // Verify Voice Dictation button exists
      final micButtonFinder = find.byKey(const Key('voice_dictation_button'));
      expect(micButtonFinder, findsOneWidget);

      // Privacy verify: Voice was NOT automatically started on screen mount
      expect(fakeVoice.startListeningCallCount, equals(0));

      // Tap microphone to start dictation
      await tester.tap(micButtonFinder);
      await tester.pump();

      expect(fakeVoice.startListeningCallCount, equals(1));
      expect(find.textContaining('Listening'), findsOneWidget);

      // Simulate spoken words
      fakeVoice.simulateSpeech('Drinking morning tea in Assam');
      await tester.pump();

      expect(find.textContaining('Drinking morning tea in Assam...'), findsOneWidget);

      // Complete speech
      fakeVoice.simulateCompletion();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify text is now in body controller
      expect(
        tester.widget<TextField>(bodyFieldFinder).controller?.text,
        equals('Drinking morning tea in Assam'),
      );

      // CRITICAL: Verify dictation did NOT automatically save to SQLite!
      final entriesInDb = await repo.getAll();
      expect(entriesInDb, isEmpty); // Must still be empty until explicit Save tap!
    });
  });
}
