/// Difficulty tiers for game levels.
enum GameDifficultyTier {
  easy,
  medium,
  hard,
  advanced,
}

extension GameDifficultyTierExtension on GameDifficultyTier {
  String get displayName {
    switch (this) {
      case GameDifficultyTier.easy:
        return 'Easy';
      case GameDifficultyTier.medium:
        return 'Medium';
      case GameDifficultyTier.hard:
        return 'Hard';
      case GameDifficultyTier.advanced:
        return 'Advanced';
    }
  }
}

/// Structured configuration for each game level.
///
/// Ensures gentle, progressive difficulty scaling for elders:
/// - Level 1: Easy, 3 items, 45 seconds
/// - Level 2: Easy, 4 items, 40 seconds
/// - Level 3: Medium, 5 items, 35 seconds
/// - Level 4: Medium, 6 items, 30 seconds
/// - Level 5+: Hard / Advanced with decreasing time limits and increased challenge
class GameLevelConfig {
  final int levelNumber;
  final GameDifficultyTier difficulty;
  final int itemCount;
  final int timeLimitSeconds;
  final double complexity; // 0.0 to 1.0

  const GameLevelConfig({
    required this.levelNumber,
    required this.difficulty,
    required this.itemCount,
    required this.timeLimitSeconds,
    required this.complexity,
  });

  /// Factory providing pre-configured progressive parameters for any given level (1 to 10+).
  factory GameLevelConfig.forLevel(int level) {
    final lvl = level < 1 ? 1 : level;

    switch (lvl) {
      case 1:
        return const GameLevelConfig(
          levelNumber: 1,
          difficulty: GameDifficultyTier.easy,
          itemCount: 3,
          timeLimitSeconds: 45,
          complexity: 0.1,
        );
      case 2:
        return const GameLevelConfig(
          levelNumber: 2,
          difficulty: GameDifficultyTier.easy,
          itemCount: 4,
          timeLimitSeconds: 40,
          complexity: 0.25,
        );
      case 3:
        return const GameLevelConfig(
          levelNumber: 3,
          difficulty: GameDifficultyTier.medium,
          itemCount: 5,
          timeLimitSeconds: 35,
          complexity: 0.45,
        );
      case 4:
        return const GameLevelConfig(
          levelNumber: 4,
          difficulty: GameDifficultyTier.medium,
          itemCount: 6,
          timeLimitSeconds: 30,
          complexity: 0.6,
        );
      case 5:
        return const GameLevelConfig(
          levelNumber: 5,
          difficulty: GameDifficultyTier.hard,
          itemCount: 7,
          timeLimitSeconds: 25,
          complexity: 0.75,
        );
      case 6:
        return const GameLevelConfig(
          levelNumber: 6,
          difficulty: GameDifficultyTier.hard,
          itemCount: 8,
          timeLimitSeconds: 20,
          complexity: 0.85,
        );
      default:
        // Level 7 to 10+
        return GameLevelConfig(
          levelNumber: lvl,
          difficulty: GameDifficultyTier.advanced,
          itemCount: (8 + (lvl - 6)).clamp(8, 12),
          timeLimitSeconds: (20 - (lvl - 6)).clamp(10, 20),
          complexity: (0.85 + (lvl - 6) * 0.03).clamp(0.85, 1.0),
        );
    }
  }
}
