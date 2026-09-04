import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/game_repository.dart';
import 'package:dashboard_app/features/games/controllers/game_session_controller.dart';
import 'package:dashboard_app/features/games/models/game_item.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameSessionController Unit Tests', () {
    late AppDatabase database;
    late GameRepository repository;

    setUpAll(() {
      if (Platform.isWindows) {
        open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
      }
    });

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      DatabaseProvider.setInstance(database);
      repository = GameRepository(database);
    });

    tearDown(() async {
      await database.close();
      DatabaseProvider.resetInstance();
    });

    test('Initializes session with custom rounds and creates DB record', () async {
      final controller = GameSessionController(
        gameId: 'matching_image',
        gameRepository: repository,
        initialDifficulty: 1,
      );

      final customRounds = [
        GameItem(
          id: 'test_1',
          image: 'japi',
          prompt: 'Find matching',
          options: ['japi', 'dhol'],
          correctIndex: 0,
        ),
        GameItem(
          id: 'test_2',
          image: 'gamosa',
          prompt: 'Find matching',
          options: ['dhol', 'gamosa'],
          correctIndex: 1,
        ),
      ];

      await controller.initialize(customRounds: customRounds);

      expect(controller.isInitialized, isTrue);
      expect(controller.sessionId, isNotNull);
      expect(controller.totalRounds, equals(2));
      expect(controller.currentRoundNumber, equals(1));
      expect(controller.currentItem?.id, equals('test_1'));

      final sessionInDb = await database.getGameSessionById(controller.sessionId!);
      expect(sessionInDb, isNotNull);
      expect(sessionInDb!.gameId, equals('matching_image'));
    });

    test('Records attempts with response time and completes session', () async {
      final controller = GameSessionController(
        gameId: 'pick_correct',
        gameRepository: repository,
        initialDifficulty: 2,
      );

      final customRounds = [
        GameItem(
          id: 'round_1',
          image: 'dhol',
          prompt: 'Pick instrument',
          options: ['dhol', 'tea'],
          correctIndex: 0,
        ),
      ];

      await controller.initialize(customRounds: customRounds);

      final isComplete = await controller.recordAttempt(correct: true);
      expect(isComplete, isTrue);
      expect(controller.correctCount, equals(1));

      // Verify attempt in DB
      final attempts = await database.getAttemptsBySessionId(controller.sessionId!);
      expect(attempts.length, equals(1));
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.gameId, equals('pick_correct'));

      // Complete session
      final result = await controller.completeSession(domain: 'RECALL');
      expect(result.accuracy, equals(1.0));
      expect(result.stars, equals(3));
      expect(result.newDifficultyLevel, equals(3)); // 2 -> 3 (promoted due to accuracy 1.0 >= 0.8)
    });
  });
}
