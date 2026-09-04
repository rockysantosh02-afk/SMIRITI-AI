import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';

/// Repository for game session and attempt operations.
/// All write operations enqueue sync events to the Outbox.
class GameRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  GameRepository(this._db);

  /// Starts a new game session and returns the session ID.
  Future<String> startSession({
    required String gameId,
    required int difficultyLevel,
  }) async {
    final now = DateTime.now();
    final id = '${gameId}_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';

    await _db.batch((batch) {
      batch.insert(
        _db.gameSessions,
        GameSessionsCompanion(
          id: Value(id),
          gameId: Value(gameId),
          startedAt: Value(now),
          difficultyLevel: Value(difficultyLevel),
          roundsPlayed: const Value(0),
          accuracy: const Value(0.0),
          synced: const Value(false),
        ),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('game_session'),
          entityId: Value(id),
          operation: const Value('create'),
          payload: Value(jsonEncode({
            'gameId': gameId,
            'game_id': gameId,
            'game_code': gameId,
            'difficultyLevel': difficultyLevel,
            'difficulty_level': difficultyLevel,
            'difficulty': difficultyLevel,
            'started_at': now.toIso8601String(),
          })),
          createdAt: Value(now),
        ),
      );
    });

    return id;
  }

  /// Records an individual attempt within a session.
  Future<void> recordAttempt({
    required String sessionId,
    required String gameId,
    required int roundNumber,
    required bool correct,
    required int responseTimeMs,
    required int difficultyLevel,
  }) async {
    final now = DateTime.now();
    final id = 'attempt_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';

    await _db.batch((batch) {
      batch.insert(
        _db.attempts,
        AttemptsCompanion(
          id: Value(id),
          sessionId: Value(sessionId),
          gameId: Value(gameId),
          roundNumber: Value(roundNumber),
          correct: Value(correct),
          responseTimeMs: Value(responseTimeMs),
          difficultyLevel: Value(difficultyLevel),
          createdAt: Value(now),
          synced: const Value(false),
        ),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('attempt'),
          entityId: Value(id),
          operation: const Value('create'),
          payload: Value(jsonEncode({
            'sessionId': sessionId,
            'session_id': sessionId,
            'gameId': gameId,
            'game_id': gameId,
            'roundNumber': roundNumber,
            'round_number': roundNumber,
            'correct': correct,
            'responseTimeMs': responseTimeMs,
            'response_time_ms': responseTimeMs,
            'difficultyLevel': difficultyLevel,
            'difficulty_level': difficultyLevel,
            'created_at': now.toIso8601String(),
          })),
          createdAt: Value(now),
        ),
      );
    });
  }

  /// Completes a session with final stats and enqueues sync.
  Future<void> completeSession({
    required String sessionId,
    required int roundsPlayed,
    required double accuracy,
  }) async {
    final now = DateTime.now();

    // Get current session to preserve data
    final session = await _db.getGameSessionById(sessionId);
    if (session == null) return;

    await _db.batch((batch) {
      batch.update(
        _db.gameSessions,
        GameSessionsCompanion(
          id: Value(sessionId),
          gameId: Value(session.gameId),
          startedAt: Value(session.startedAt),
          completedAt: Value(now),
          difficultyLevel: Value(session.difficultyLevel),
          roundsPlayed: Value(roundsPlayed),
          accuracy: Value(accuracy),
          synced: const Value(false),
        ),
        where: (t) => t.id.equals(sessionId),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('game_session'),
          entityId: Value(sessionId),
          operation: const Value('update'),
          payload: Value(jsonEncode({
            'completedAt': now.toIso8601String(),
            'completed_at': now.toIso8601String(),
            'roundsPlayed': roundsPlayed,
            'rounds_played': roundsPlayed,
            'accuracy': accuracy,
            'game_id': session.gameId,
            'gameId': session.gameId,
            'difficulty_level': session.difficultyLevel,
          })),
          createdAt: Value(now),
        ),
      );
    });
  }

  /// Gets all sessions since the given date, ordered newest first.
  Future<List<GameSession>> getSessionsSince(DateTime date) async {
    final query = _db.select(_db.gameSessions)
      ..where((t) => t.startedAt.isBiggerOrEqualValue(date))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    return query.get();
  }

  /// Watches all sessions, ordered by most recent first.
  Stream<List<GameSession>> watchRecentSessions({int limit = 20}) {
    final query = _db.select(_db.gameSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);
    return query.watch();
  }

  /// Gets unsynced sessions for background sync.
  Future<List<GameSession>> getUnsyncedSessions() {
    return _db.getUnsyncedGameSessions();
  }

  /// Marks a session as synced after successful cloud sync.
  Future<void> markSessionSynced(String sessionId) async {
    final session = await _db.getGameSessionById(sessionId);
    if (session == null) return;

    await _db.update(_db.gameSessions).replace(GameSession(
      id: session.id,
      gameId: session.gameId,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      difficultyLevel: session.difficultyLevel,
      roundsPlayed: session.roundsPlayed,
      accuracy: session.accuracy,
      synced: true,
    ));
  }
}
