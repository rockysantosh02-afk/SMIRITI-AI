import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard_app/features/games/controllers/adaptive_difficulty_stub.dart';
import 'package:dashboard_app/features/games/models/game_level_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Game Level Progression & Difficulty Adaptation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('GameLevelConfig defines gradual difficulty and item count scaling', () {
      final l1 = GameLevelConfig.forLevel(1);
      final l2 = GameLevelConfig.forLevel(2);
      final l3 = GameLevelConfig.forLevel(3);
      final l4 = GameLevelConfig.forLevel(4);
      final l5 = GameLevelConfig.forLevel(5);

      // Level 1: Easy, 3 items, 45 seconds
      expect(l1.levelNumber, equals(1));
      expect(l1.difficulty, equals(GameDifficultyTier.easy));
      expect(l1.itemCount, equals(3));
      expect(l1.timeLimitSeconds, equals(45));

      // Level 2: Easy, 4 items, 40 seconds
      expect(l2.levelNumber, equals(2));
      expect(l2.difficulty, equals(GameDifficultyTier.easy));
      expect(l2.itemCount, equals(4));
      expect(l2.timeLimitSeconds, equals(40));

      // Level 3: Medium, 5 items, 35 seconds
      expect(l3.levelNumber, equals(3));
      expect(l3.difficulty, equals(GameDifficultyTier.medium));
      expect(l3.itemCount, equals(5));
      expect(l3.timeLimitSeconds, equals(35));

      // Level 4: Medium, 6 items, 30 seconds
      expect(l4.levelNumber, equals(4));
      expect(l4.difficulty, equals(GameDifficultyTier.medium));
      expect(l4.itemCount, equals(6));
      expect(l4.timeLimitSeconds, equals(30));

      // Level 5: Hard
      expect(l5.difficulty, equals(GameDifficultyTier.hard));
    });

    test('AdaptiveDifficultyStub.calculateNewLevel advances level when accuracy >= 0.8', () {
      expect(
        AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 1, accuracy: 0.8),
        equals(2),
      );
      expect(
        AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 2, accuracy: 0.85),
        equals(3),
      );
      // High score on max level does not exceed maxLevel
      expect(
        AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 5, accuracy: 1.0),
        equals(5),
      );
      expect(
        AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 10, accuracy: 1.0, maxLevel: 10),
        equals(10),
      );
    });

    test('AdaptiveDifficultyStub.evaluateAndSave persists level, highest completed level, and high score', () async {
      // Complete level 1 with 100% score
      final newLevel = await AdaptiveDifficultyStub.evaluateAndSave(
        gameId: 'matching_image',
        currentLevel: 1,
        accuracy: 1.0,
        score: 100,
      );

      expect(newLevel, equals(2));

      // Verify persistent values
      final savedLevel = await AdaptiveDifficultyStub.getDifficulty('matching_image');
      final highestLevel = await AdaptiveDifficultyStub.getHighestCompletedLevel('matching_image');
      final highScore = await AdaptiveDifficultyStub.getHighScore('matching_image');

      expect(savedLevel, equals(2));
      expect(highestLevel, equals(1));
      expect(highScore, equals(100));
    });

    test('AdaptiveDifficultyStub does not penalize heavily on lower accuracy', () {
      // Middle accuracy maintains current level
      expect(
        AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 2, accuracy: 0.5),
        equals(2),
      );

      // Never drops below minLevel 1
      expect(
        AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 1, accuracy: 0.0),
        equals(1),
      );
    });
  });
}
