import 'package:flutter/foundation.dart';
import '../../../core/database/repositories/game_repository.dart';
import '../models/game_item.dart';
import '../models/game_result.dart';
import '../services/content_pack_service.dart';
import 'adaptive_difficulty_stub.dart';

/// Controller managing an active 5-round game session.
class GameSessionController extends ChangeNotifier {
  final String gameId;
  final GameRepository gameRepository;
  final ContentPackService contentPackService;

  int difficultyLevel = 1;
  String? sessionId;
  List<GameItem> rounds = [];
  int currentRoundIndex = 0;
  int correctCount = 0;
  int accumulatedResponseTimeMs = 0;
  DateTime _roundStartTime = DateTime.now();
  bool _isInitialized = false;

  final int? _initialDifficulty;

  GameSessionController({
    required this.gameId,
    required this.gameRepository,
    ContentPackService? contentPackService,
    int? initialDifficulty,
  })  : contentPackService = contentPackService ?? ContentPackService.instance,
        _initialDifficulty = initialDifficulty,
        difficultyLevel = initialDifficulty ?? 1;

  bool get isInitialized => _isInitialized;
  int get currentRoundNumber => currentRoundIndex + 1;
  int get totalRounds => rounds.isEmpty ? 5 : rounds.length;
  bool get isSessionComplete => _isInitialized && currentRoundIndex >= rounds.length;
  double get currentAccuracy => rounds.isEmpty ? 0.0 : (correctCount / totalRounds);

  GameItem? get currentItem {
    if (rounds.isNotEmpty && currentRoundIndex < rounds.length) {
      return rounds[currentRoundIndex];
    }
    return null;
  }

  /// Initializes the session: creates a session record in DB and prepares 5 rounds.
  Future<void> initialize({List<GameItem>? customRounds}) async {
    // If difficulty was not passed explicitly, load from saved preference
    if (_initialDifficulty == null) {
      difficultyLevel = await AdaptiveDifficultyStub.getDifficulty(gameId);
    }

    sessionId = await gameRepository.startSession(
      gameId: gameId,
      difficultyLevel: difficultyLevel,
    );

    if (customRounds != null && customRounds.isNotEmpty) {
      rounds = customRounds;
    } else {
      rounds = contentPackService.generateRounds(gameId, difficultyLevel, count: 5);
      // Fallback if empty
      if (rounds.isEmpty) {
        final fallback = contentPackService.getItems(gameId, 1);
        rounds = fallback.isNotEmpty ? fallback.take(5).toList() : [];
      }
    }

    currentRoundIndex = 0;
    correctCount = 0;
    accumulatedResponseTimeMs = 0;
    _roundStartTime = DateTime.now();
    _isInitialized = true;
    notifyListeners();
  }

  /// Records an attempt for the current round and advances to next.
  Future<bool> recordAttempt({required bool correct}) async {
    if (sessionId == null || isSessionComplete) return false;

    final responseTime = DateTime.now().difference(_roundStartTime).inMilliseconds;
    accumulatedResponseTimeMs += responseTime;

    if (correct) {
      correctCount++;
    }

    await gameRepository.recordAttempt(
      sessionId: sessionId!,
      gameId: gameId,
      roundNumber: currentRoundNumber,
      correct: correct,
      responseTimeMs: responseTime,
      difficultyLevel: difficultyLevel,
    );

    currentRoundIndex++;
    _roundStartTime = DateTime.now();
    notifyListeners();
    return isSessionComplete;
  }

  /// Completes the session, saves stats to DB, runs adaptive difficulty stub, and returns GameResult.
  Future<GameResult> completeSession({String domain = 'COGNITIVE'}) async {
    final accuracy = totalRounds > 0 ? (correctCount / totalRounds) : 0.0;
    final avgResponseTime = totalRounds > 0 ? (accumulatedResponseTimeMs ~/ totalRounds) : 0;

    if (sessionId != null) {
      await gameRepository.completeSession(
        sessionId: sessionId!,
        roundsPlayed: totalRounds,
        accuracy: accuracy,
      );
    }

    final newLevel = await AdaptiveDifficultyStub.evaluateAndSave(
      gameId: gameId,
      currentLevel: difficultyLevel,
      accuracy: accuracy,
      score: correctCount,
    );

    int stars = 1;
    if (accuracy >= 0.8) {
      stars = 3;
    } else if (accuracy >= 0.5) {
      stars = 2;
    }

    return GameResult(
      sessionId: sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      gameId: gameId,
      domain: domain,
      accuracy: accuracy,
      responseTimeMs: avgResponseTime,
      difficultyLevel: difficultyLevel,
      newDifficultyLevel: newLevel,
      roundsPlayed: totalRounds,
      correctRounds: correctCount,
      stars: stars,
      playedAt: DateTime.now(),
    );
  }
}

