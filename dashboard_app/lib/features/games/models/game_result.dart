/// Result data class produced upon game session completion.
class GameResult {
  final String sessionId;
  final String gameId;
  final String domain;
  final double accuracy;
  final int responseTimeMs;
  final int difficultyLevel;
  final int newDifficultyLevel;
  final int roundsPlayed;
  final int correctRounds;
  final int stars;
  final DateTime playedAt;

  GameResult({
    required this.sessionId,
    required this.gameId,
    required this.domain,
    required this.accuracy,
    required this.responseTimeMs,
    required this.difficultyLevel,
    required this.newDifficultyLevel,
    required this.roundsPlayed,
    required this.correctRounds,
    required this.stars,
    required this.playedAt,
  });
}
