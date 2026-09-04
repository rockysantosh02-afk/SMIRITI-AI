import 'package:shared_preferences/shared_preferences.dart';

/// Adaptive difficulty controller stub.
/// Manages level (1 to 5) per game.
/// Updates tier based on accuracy:
/// - accuracy >= 0.8: +1 tier (max 5)
/// - accuracy <= 0.4: -1 tier (min 1)
/// - otherwise: stays unchanged
class AdaptiveDifficultyStub {
  static const int minLevel = 1;
  static const int maxLevel = 5;

  /// Retrieves current saved difficulty level for a game.
  static Future<int> getDifficulty(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('game_difficulty_$gameId') ?? 1;
    } catch (_) {
      return 1;
    }
  }

  /// Calculates new level based on accuracy (0.0 to 1.0).
  static int calculateNewLevel({required int currentLevel, required double accuracy}) {
    if (accuracy >= 0.8) {
      return (currentLevel + 1).clamp(minLevel, maxLevel);
    } else if (accuracy <= 0.4) {
      return (currentLevel - 1).clamp(minLevel, maxLevel);
    }
    return currentLevel.clamp(minLevel, maxLevel);
  }

  /// Evaluates accuracy, updates and persists the new difficulty level for the game.
  static Future<int> evaluateAndSave({
    required String gameId,
    required int currentLevel,
    required double accuracy,
  }) async {
    final newLevel = calculateNewLevel(
      currentLevel: currentLevel,
      accuracy: accuracy,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_difficulty_$gameId', newLevel);
    } catch (_) {}
    return newLevel;
  }
}
