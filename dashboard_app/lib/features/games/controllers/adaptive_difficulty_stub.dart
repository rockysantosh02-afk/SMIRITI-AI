import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_level_config.dart';

/// Progress and adaptive difficulty controller for Smriti AI cognitive games.
///
/// Features:
/// - Manages structured levels (1 to 10)
/// - Tracks highest completed level
/// - Tracks high score
/// - Gradually increases difficulty without sudden spikes
class AdaptiveDifficultyStub {
  static const int minLevel = 1;
  static const int maxLevel = 5;

  /// Retrieves current saved level for a game. Defaults to 1.
  static Future<int> getDifficulty(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('game_difficulty_$gameId') ?? 1;
    } catch (_) {
      return 1;
    }
  }

  /// Retrieves the highest completed level for a game. Defaults to 0.
  static Future<int> getHighestCompletedLevel(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('game_highest_completed_$gameId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Retrieves high score for a game.
  static Future<int> getHighScore(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('game_high_score_$gameId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Calculates new level based on accuracy (0.0 to 1.0).
  /// - Promotion: accuracy >= 0.8
  /// - Demotion: accuracy <= 0.4
  /// - Unchanged: 0.4 < accuracy < 0.8
  static int calculateNewLevel({
    required int currentLevel,
    required double accuracy,
    int maxLevel = maxLevel,
  }) {
    if (accuracy >= 0.8) {
      return (currentLevel + 1).clamp(minLevel, maxLevel);
    } else if (accuracy <= 0.4) {
      return (currentLevel - 1).clamp(minLevel, maxLevel);
    }
    return currentLevel.clamp(minLevel, maxLevel);
  }

  /// Evaluates accuracy, updates and persists the new level, highest completed level,
  /// and high score for the game.
  static Future<int> evaluateAndSave({
    required String gameId,
    required int currentLevel,
    required double accuracy,
    int score = 0,
    int maxLevel = maxLevel,
  }) async {
    final isSuccess = accuracy >= 0.6;
    final newLevel = calculateNewLevel(
      currentLevel: currentLevel,
      accuracy: accuracy,
      maxLevel: maxLevel,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_difficulty_$gameId', newLevel);

      if (isSuccess) {
        final prevHighest = prefs.getInt('game_highest_completed_$gameId') ?? 0;
        if (currentLevel > prevHighest) {
          await prefs.setInt('game_highest_completed_$gameId', currentLevel);
        }
      }

      final prevHighScore = prefs.getInt('game_high_score_$gameId') ?? 0;
      if (score > prevHighScore) {
        await prefs.setInt('game_high_score_$gameId', score);
      }
    } catch (_) {}

    return newLevel;
  }

  /// Convenience getter to fetch [GameLevelConfig] for a game's active level.
  static Future<GameLevelConfig> getLevelConfig(String gameId) async {
    final level = await getDifficulty(gameId);
    return GameLevelConfig.forLevel(level);
  }
}
