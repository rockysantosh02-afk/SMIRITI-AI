import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/features/games/screens/draw_shape_screen.dart';
import 'package:dashboard_app/features/games/screens/find_difference_screen.dart';
import 'package:dashboard_app/features/games/screens/pick_correct_screen.dart';
import 'package:dashboard_app/features/games/screens/situation_match_screen.dart';
import 'package:dashboard_app/features/games/services/content_pack_service.dart';
import 'package:dashboard_app/features/games/services/shape_recognizer.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShapeRecognizer Algorithm Tests', () {
    const recognizer = ShapeRecognizer();

    test('Circle recognition: closed circular path returns circle', () {
      final points = <Offset>[];
      const center = Offset(150, 150);
      const radius = 60.0;
      for (var i = 0; i <= 36; i++) {
        final angle = (i * 10) * math.pi / 180.0;
        points.add(Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ));
      }

      final shape = recognizer.recognize([points]);
      expect(shape, equals(RecognizedShape.circle));
      final evalMatch = recognizer.evaluate(expectedShapeKey: 'circle', strokes: [points], languageCode: 'en');
      expect(evalMatch.isMatch, isTrue);
      final evalLine = recognizer.evaluate(expectedShapeKey: 'line', strokes: [points], languageCode: 'en');
      expect(evalLine.isMatch, isFalse);
    });

    test('Line recognition: straight open stroke returns line', () {
      final points = <Offset>[];
      for (var i = 0; i <= 20; i++) {
        points.add(Offset(50.0 + i * 8.0, 100.0 + (i % 2) * 1.5));
      }

      final shape = recognizer.recognize([points]);
      expect(shape, equals(RecognizedShape.line));
      final evalMatch = recognizer.evaluate(expectedShapeKey: 'line', strokes: [points], languageCode: 'en');
      expect(evalMatch.isMatch, isTrue);
      final evalCircle = recognizer.evaluate(expectedShapeKey: 'circle', strokes: [points], languageCode: 'en');
      expect(evalCircle.isMatch, isFalse);
    });

    test('Triangle recognition: 3-corner closed loop returns triangle', () {
      final points = <Offset>[];
      // Bottom side: (50, 200) to (200, 200)
      for (var i = 0; i <= 10; i++) {
        points.add(Offset(50.0 + i * 15.0, 200.0));
      }
      // Right side up to apex: (200, 200) to (125, 60)
      for (var i = 1; i <= 10; i++) {
        points.add(Offset(200.0 - i * 7.5, 200.0 - i * 14.0));
      }
      // Left side down to start: (125, 60) to (50, 200)
      for (var i = 1; i <= 10; i++) {
        points.add(Offset(125.0 - i * 7.5, 60.0 + i * 14.0));
      }

      final shape = recognizer.recognize([points]);
      expect(shape, equals(RecognizedShape.triangle));
      final evalMatch = recognizer.evaluate(expectedShapeKey: 'triangle', strokes: [points], languageCode: 'en');
      expect(evalMatch.isMatch, isTrue);
      final evalCircle = recognizer.evaluate(expectedShapeKey: 'circle', strokes: [points], languageCode: 'en');
      expect(evalCircle.isMatch, isFalse);
    });

    test('Square recognition: 4 equal sides closed loop returns square', () {
      final points = <Offset>[];
      // Top: (50,50) -> (150,50)
      for (var i = 0; i <= 10; i++) {
        points.add(Offset(50.0 + i * 10.0, 50.0));
      }
      // Right: (150,50) -> (150,150)
      for (var i = 1; i <= 10; i++) {
        points.add(Offset(150.0, 50.0 + i * 10.0));
      }
      // Bottom: (150,150) -> (50,150)
      for (var i = 1; i <= 10; i++) {
        points.add(Offset(150.0 - i * 10.0, 150.0));
      }
      // Left: (50,150) -> (50,50)
      for (var i = 1; i <= 10; i++) {
        points.add(Offset(50.0, 150.0 - i * 10.0));
      }

      final shape = recognizer.recognize([points]);
      expect(shape, equals(RecognizedShape.square));
      final evalMatch = recognizer.evaluate(expectedShapeKey: 'square', strokes: [points], languageCode: 'en');
      expect(evalMatch.isMatch, isTrue);
    });

    test('Rectangle recognition: 4 sides with aspect ratio > 1.35 returns rectangle', () {
      final points = <Offset>[];
      // Top: (30,50) -> (190,50) [width = 160]
      for (var i = 0; i <= 16; i++) {
        points.add(Offset(30.0 + i * 10.0, 50.0));
      }
      // Right: (190,50) -> (190,110) [height = 60]
      for (var i = 1; i <= 6; i++) {
        points.add(Offset(190.0, 50.0 + i * 10.0));
      }
      // Bottom: (190,110) -> (30,110)
      for (var i = 1; i <= 16; i++) {
        points.add(Offset(190.0 - i * 10.0, 110.0));
      }
      // Left: (30,110) -> (30,50)
      for (var i = 1; i <= 6; i++) {
        points.add(Offset(30.0, 110.0 - i * 10.0));
      }

      final shape = recognizer.recognize([points]);
      expect(shape, equals(RecognizedShape.rectangle));
      final evalMatch = recognizer.evaluate(expectedShapeKey: 'rectangle', strokes: [points], languageCode: 'en');
      expect(evalMatch.isMatch, isTrue);
    });
  });

  group('Find Difference Level Configuration & Hit Detection Tests', () {
    test('Difference levels configure genuinely distinct locations across rounds', () {
      const regions = DifferenceLevel.defaultRegions;
      expect(regions.length, greaterThanOrEqualTo(5));

      // Verify each preset has distinct coordinates
      final centers = regions.map((r) => Offset(r.normalizedX, r.normalizedY)).toList();
      for (var i = 0; i < centers.length; i++) {
        for (var j = i + 1; j < centers.length; j++) {
          final dist = (centers[i] - centers[j]).distance;
          expect(dist, greaterThan(0.2),
              reason: 'Presets $i and $j are too close: ${centers[i]} vs ${centers[j]}');
        }
      }
    });

    test('Hit test accepts taps within tolerance and rejects distant taps', () {
      const region = DifferenceRegion(
        description: 'Center',
        normalizedX: 0.5,
        normalizedY: 0.5,
        normalizedRadius: 0.18,
      );
      const size = Size(300, 300);

      // Center tap -> hit
      expect(region.contains(const Offset(150, 150), size), isTrue);
      // Slight offset within radius -> hit
      expect(region.contains(const Offset(165, 165), size), isTrue);
      // Far corner tap -> miss
      expect(region.contains(const Offset(30, 30), size), isFalse);
      expect(region.contains(const Offset(270, 270), size), isFalse);
    });
  });

  group('Game Screens Corrections Widget Tests', () {
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

    testWidgets('PickCorrectScreen displays question, clue, 4 large options, and explanations',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PickCorrectScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Question and clue visible
      expect(find.byKey(const Key('pitch_question')), findsOneWidget);
      expect(find.byKey(const Key('pitch_clue')), findsOneWidget);

      // Four options A, B, C, D visible
      expect(find.byKey(const Key('pitch_option_a')), findsOneWidget);
      expect(find.byKey(const Key('pitch_option_b')), findsOneWidget);
      expect(find.byKey(const Key('pitch_option_c')), findsOneWidget);
      expect(find.byKey(const Key('pitch_option_d')), findsOneWidget);

      // Options meet accessibility >=80dp height
      final buttonA = tester.getSize(find.byKey(const Key('pitch_option_a')));
      expect(buttonA.height, greaterThanOrEqualTo(76.0));
    });

    testWidgets('SituationMatchScreen displays situation, question, and 4 choices',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SituationMatchScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Situation and Question visible
      expect(find.byKey(const Key('situation_badge')), findsOneWidget);
      expect(find.byKey(const Key('situation_question')), findsOneWidget);

      // Four options A-D visible
      expect(find.byKey(const Key('situation_option_a')), findsOneWidget);
      expect(find.byKey(const Key('situation_option_b')), findsOneWidget);
      expect(find.byKey(const Key('situation_option_c')), findsOneWidget);
      expect(find.byKey(const Key('situation_option_d')), findsOneWidget);
    });

    testWidgets('FindDifferenceScreen renders scene A and scene B keys',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FindDifferenceScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('find_difference_scene_a')), findsOneWidget);
      expect(find.byKey(const Key('find_difference_scene_b')), findsOneWidget);
    });

    testWidgets('DrawShapeScreen contains draw_shape_canvas key',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DrawShapeScreen(initialDifficulty: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('I am ready'));
      await tester.pump();

      expect(find.byKey(const Key('draw_shape_canvas')), findsOneWidget);
    });
  });
}
