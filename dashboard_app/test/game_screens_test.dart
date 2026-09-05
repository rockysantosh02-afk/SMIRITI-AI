import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/features/games/screens/matching_image_screen.dart';
import 'package:dashboard_app/features/games/screens/pick_correct_screen.dart';
import 'package:dashboard_app/features/games/screens/number_game_screen.dart';
import 'package:dashboard_app/features/games/screens/family_quiz_screen.dart';
import 'package:dashboard_app/features/games/screens/recalling_memories_screen.dart';
import 'package:dashboard_app/features/games/screens/draw_shape_screen.dart';
import 'package:dashboard_app/features/games/services/content_pack_service.dart';
import 'package:dashboard_app/features/games/services/cultural_visual_helper.dart';

import 'package:shared_preferences/shared_preferences.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Game Screens Widget & Attempt Recording Tests', () {
    late AppDatabase database;

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      if (Platform.isWindows) {
        open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
      }
      final file = File('assets/games/content_pack.json');
      ContentPackService.instance.loadFromJsonString(file.readAsStringSync());
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      DatabaseProvider.setInstance(database);
    });

    tearDown(() async {
      DatabaseProvider.resetInstance();
    });

    testWidgets('MatchingImageScreen: correct tap records attempt with correct=true',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MatchingImageScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Look for the state and find current round item
      final state = tester.state(find.byType(MatchingImageScreen)) as dynamic;
      final currentItem = state.controller.currentItem;
      expect(currentItem, isNotNull);

      final correctKey = currentItem.options[currentItem.correctIndex];
      final correctMeta = CulturalVisualHelper.getMeta(correctKey);

      // Find the option widget with this text
      final correctOptionFinder = find.widgetWithText(ElevatedButton, correctMeta.nameEn);
      expect(correctOptionFinder, findsOneWidget);

      // Tap the correct option
      await tester.tap(correctOptionFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify attempt recorded in database with correct=true and gameId='matching_image'
      final attempts = await database.getAllAttempts();
      expect(attempts.length, equals(1));
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.gameId, equals('matching_image'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('PickCorrectScreen: correct tap records attempt with correct=true',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PickCorrectScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final state = tester.state(find.byType(PickCorrectScreen)) as dynamic;
      final currentItem = state.controller.currentItem;
      expect(currentItem, isNotNull);

      final correctKey = currentItem.options[currentItem.correctIndex];
      final correctMeta = CulturalVisualHelper.getMeta(correctKey);

      final correctOptionFinder = find.widgetWithText(ElevatedButton, correctMeta.nameEn);
      expect(correctOptionFinder, findsOneWidget);

      await tester.tap(correctOptionFinder);
      await tester.pump(const Duration(milliseconds: 100));

      final attempts = await database.getAllAttempts();
      expect(attempts.length, equals(1));
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.gameId, equals('pick_correct'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('NumberGameScreen: correct tap records attempt with correct=true',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: NumberGameScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final state = tester.state(find.byType(NumberGameScreen)) as dynamic;
      final currentItem = state.controller.currentItem;
      expect(currentItem, isNotNull);

      final correctText = currentItem.options[currentItem.correctIndex];
      final correctOptionFinder = find.widgetWithText(ElevatedButton, correctText);
      expect(correctOptionFinder, findsOneWidget);

      await tester.tap(correctOptionFinder);
      await tester.pump(const Duration(milliseconds: 100));

      final attempts = await database.getAllAttempts();
      expect(attempts.length, equals(1));
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.gameId, equals('number_game'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('FamilyQuizScreen: correct tap records attempt with correct=true',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FamilyQuizScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final state = tester.state(find.byType(FamilyQuizScreen)) as dynamic;
      final currentItem = state.controller.currentItem;
      expect(currentItem, isNotNull);

      final correctName = currentItem.options[currentItem.correctIndex];
      final correctOptionFinder = find.widgetWithText(ElevatedButton, correctName);
      expect(correctOptionFinder, findsOneWidget);

      await tester.tap(correctOptionFinder);
      await tester.pump(const Duration(milliseconds: 100));

      final attempts = await database.getAllAttempts();
      expect(attempts.length, equals(1));
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.gameId, equals('family_quiz'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('RecallingMemoriesScreen: user response records attempt with correct=true',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RecallingMemoriesScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final responseButtonFinder = find.widgetWithText(ElevatedButton, 'Yes, wonderful memories!');
      expect(responseButtonFinder, findsOneWidget);

      await tester.tap(responseButtonFinder);
      await tester.pump(const Duration(milliseconds: 100));

      final attempts = await database.getAllAttempts();
      expect(attempts.length, equals(1));
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.gameId, equals('recalling_memories'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('DrawShapeScreen: canvas gesture drawing, undo, clear, and submission works',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DrawShapeScreen(initialDifficulty: 1),
        ),
      );
      // Wait for target shape preview countdown to expire and canvas to appear
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Locate GestureDetector canvas
      final gestureDetectorFinder = find.byType(GestureDetector);
      expect(gestureDetectorFinder, findsWidgets);

      // Perform dragging gesture on the drawing canvas
      await tester.drag(gestureDetectorFinder.first, const Offset(60, 60));
      await tester.pump();

      // Verify Undo and Clear buttons exist
      expect(find.widgetWithText(ElevatedButton, 'Undo'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Clear Canvas'), findsOneWidget);

      // Test Undo button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Undo'));
      await tester.pump();

      // Draw another stroke
      await tester.drag(gestureDetectorFinder.first, const Offset(80, 80));
      await tester.pump();

      // Tap 'I am Done'
      final doneButton = find.widgetWithText(ElevatedButton, 'I am Done');
      expect(doneButton, findsOneWidget);
      await tester.tap(doneButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify attempt recorded
      final attempts = await database.getAllAttempts();
      expect(attempts.length, equals(1));
      expect(attempts.first.gameId, equals('draw_shape'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
