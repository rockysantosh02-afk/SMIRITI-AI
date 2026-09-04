import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';

// Location of sqlite3.dll downloaded for testing.
final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  group('AppDatabase Unit Tests', () {
    late AppDatabase database;

    setUpAll(() {
      // Override sqlite3 DLL location on Windows since it's not in PATH.
      // The DLL was downloaded to %TEMP%/sqlite/ by a setup step.
      if (Platform.isWindows) {
        open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
      }
    });

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('Database opens successfully', () async {
      // Verify we can query the database (table exists)
      final sessions = await database.getAllGameSessions();
      expect(sessions, isEmpty);
    });

    test('Can insert a GameSession and read it back', () async {
      // Create a game session companion
      const sessionId = 'test-session-123';
      final now = DateTime.now();

      final sessionCompanion = GameSessionsCompanion(
        id: const Value(sessionId),
        gameId: const Value('memory_match'),
        startedAt: Value(now),
        completedAt: Value(now.add(const Duration(minutes: 5))),
        difficultyLevel: const Value(2),
        roundsPlayed: const Value(10),
        accuracy: const Value(0.85),
        synced: const Value(false),
      );

      // Insert the session
      await database.insertGameSession(sessionCompanion);

      // Read it back
      final retrievedSession = await database.getGameSessionById(sessionId);

      // Verify the data
      expect(retrievedSession != null, isTrue);
      expect(retrievedSession!.id, equals(sessionId));
      expect(retrievedSession.gameId, equals('memory_match'));
      expect(retrievedSession.difficultyLevel, equals(2));
      expect(retrievedSession.roundsPlayed, equals(10));
      expect(retrievedSession.accuracy, equals(0.85));
      expect(retrievedSession.synced, isFalse);
    });

    test('Can insert multiple GameSessions and retrieve all', () async {
      final now = DateTime.now();

      // Insert multiple sessions
      for (var i = 0; i < 3; i++) {
        await database.insertGameSession(
          GameSessionsCompanion(
            id: Value('session-$i'),
            gameId: Value('game-$i'),
            startedAt: Value(now),
            difficultyLevel: Value(i + 1),
            roundsPlayed: Value(10 + i),
            accuracy: Value(0.7 + (i * 0.1)),
          ),
        );
      }

      // Retrieve all sessions
      final sessions = await database.getAllGameSessions();

      expect(sessions.length, equals(3));
    });

    test('Can update a GameSession', () async {
      const sessionId = 'update-test-session';
      final now = DateTime.now();

      // Insert a session
      await database.insertGameSession(
        GameSessionsCompanion(
          id: const Value(sessionId),
          gameId: const Value('memory_match'),
          startedAt: Value(now),
          difficultyLevel: const Value(1),
          roundsPlayed: const Value(5),
          accuracy: const Value(0.5),
        ),
      );

      // Update the session
      await database.updateGameSession(
        GameSessionsCompanion(
          id: const Value(sessionId),
          gameId: const Value('memory_match'),
          startedAt: Value(now),
          completedAt: Value(now.add(const Duration(minutes: 10))),
          difficultyLevel: const Value(2),
          roundsPlayed: const Value(10),
          accuracy: const Value(0.9),
          synced: const Value(true),
        ),
      );

      // Verify the update
      final updatedSession = await database.getGameSessionById(sessionId);
      expect(updatedSession!.accuracy, equals(0.9));
      expect(updatedSession.synced, isTrue);
    });

    test('Can delete a GameSession', () async {
      const sessionId = 'delete-test-session';
      final now = DateTime.now();

      // Insert a session
      await database.insertGameSession(
        GameSessionsCompanion(
          id: const Value(sessionId),
          gameId: const Value('memory_match'),
          startedAt: Value(now),
          difficultyLevel: const Value(1),
          roundsPlayed: const Value(5),
          accuracy: const Value(0.5),
        ),
      );

      // Verify it exists
      var sessions = await database.getAllGameSessions();
      expect(sessions.length, equals(1));

      // Delete it
      await database.deleteGameSession(sessionId);

      // Verify it's gone
      sessions = await database.getAllGameSessions();
      expect(sessions, isEmpty);
    });

    test('Can insert and query Attempts', () async {
      const sessionId = 'test-session-for-attempts';
      final now = DateTime.now();

      // First insert a session (to satisfy potential FK if needed)
      await database.insertGameSession(
        GameSessionsCompanion(
          id: const Value(sessionId),
          gameId: const Value('reaction_time'),
          startedAt: Value(now),
          difficultyLevel: const Value(1),
          roundsPlayed: const Value(0),
          accuracy: const Value(0.0),
        ),
      );

      // Insert an attempt
      await database.insertAttempt(
        AttemptsCompanion(
          id: const Value('attempt-1'),
          sessionId: const Value(sessionId),
          gameId: const Value('reaction_time'),
          roundNumber: const Value(1),
          correct: const Value(true),
          responseTimeMs: const Value(1500),
          difficultyLevel: const Value(1),
          createdAt: Value(now),
        ),
      );

      // Query attempts by session
      final attempts = await database.getAttemptsBySessionId(sessionId);
      expect(attempts.length, equals(1));
      expect(attempts.first.correct, isTrue);
      expect(attempts.first.responseTimeMs, equals(1500));
    });

    test('Can insert and query CognitiveScores', () async {
      final now = DateTime.now();

      // Insert a cognitive score
      await database.insertOrUpdateCognitiveScore(
        CognitiveScoresCompanion(
          id: const Value('memory'),
          domain: const Value('memory'),
          score: const Value(85.5),
          trend: const Value(2.3),
          updatedAt: Value(now),
        ),
      );

      // Query by domain
      final score = await database.getCognitiveScoreByDomain('memory');
      expect(score != null, isTrue);
      expect(score!.domain, equals('memory'));
      expect(score.score, equals(85.5));
    });

    test('Can insert and query JournalEntries', () async {
      final now = DateTime.now();

      // Insert a journal entry
      await database.insertJournalEntry(
        JournalEntriesCompanion(
          id: const Value('journal-1'),
          title: const Value('My First Entry'),
          body: const Value('Today was a great day!'),
          mood: const Value('happy'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Query all entries
      final entries = await database.getAllJournalEntries();
      expect(entries.length, equals(1));
      expect(entries.first.title, equals('My First Entry'));
    });

    test('Can soft-delete a JournalEntry', () async {
      final now = DateTime.now();

      // Insert a journal entry
      await database.insertJournalEntry(
        JournalEntriesCompanion(
          id: const Value('journal-delete-test'),
          title: const Value('To be deleted'),
          body: const Value('This will be soft deleted'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Soft delete
      await database.softDeleteJournalEntry('journal-delete-test');

      // Should not appear in normal queries
      final entries = await database.getAllJournalEntries();
      expect(entries, isEmpty);
    });

    test('Can insert and query Reminders', () async {
      final now = DateTime.now();

      // Insert a reminder
      await database.insertReminder(
        RemindersCompanion(
          id: const Value('reminder-1'),
          title: const Value('Take medication'),
          timeOfDay: const Value('09:00'),
          daysOfWeek: const Value('1,2,3,4,5,6,7'),
          enabled: const Value(true),
          createdAt: Value(now),
        ),
      );

      // Query all reminders
      final reminders = await database.getAllReminders();
      expect(reminders.length, equals(1));
      expect(reminders.first.title, equals('Take medication'));
    });

    test('Can insert and query Outbox items', () async {
      final now = DateTime.now();

      // Insert an outbox item
      await database.insertOutboxItem(
        OutboxCompanion(
          entityType: const Value('game_session'),
          entityId: const Value('session-123'),
          operation: const Value('create'),
          payload: const Value('{"test": "data"}'),
          createdAt: Value(now),
        ),
      );

      // Query all outbox items
      final items = await database.getAllOutboxItems();
      expect(items.length, equals(1));
      expect(items.first.entityType, equals('game_session'));
      expect(items.first.operation, equals('create'));
    });

    test('Outbox count works correctly', () async {
      final now = DateTime.now();

      // Insert multiple outbox items
      for (var i = 0; i < 5; i++) {
        await database.insertOutboxItem(
          OutboxCompanion(
            entityType: const Value('game_session'),
            entityId: Value('session-$i'),
            operation: const Value('create'),
            payload: Value('{"index": $i}'),
            createdAt: Value(now),
          ),
        );
      }

      // Get count
      final count = await database.getOutboxCount();
      expect(count, equals(5));
    });

    test('Can mark GameSession as synced', () async {
      const sessionId = 'sync-test-session';
      final now = DateTime.now();

      // Insert unsynced session
      await database.insertGameSession(
        GameSessionsCompanion(
          id: const Value(sessionId),
          gameId: const Value('memory_match'),
          startedAt: Value(now),
          difficultyLevel: const Value(1),
          roundsPlayed: const Value(5),
          accuracy: const Value(0.7),
          synced: const Value(false),
        ),
      );

      // Get unsynced sessions
      var unsynced = await database.getUnsyncedGameSessions();
      expect(unsynced.length, equals(1));

      // Mark as synced
      await database.updateGameSession(
        GameSessionsCompanion(
          id: const Value(sessionId),
          gameId: const Value('memory_match'),
          startedAt: Value(now),
          completedAt: Value(now),
          difficultyLevel: const Value(1),
          roundsPlayed: const Value(5),
          accuracy: const Value(0.7),
          synced: const Value(true),
        ),
      );

      // Verify no unsynced remain
      unsynced = await database.getUnsyncedGameSessions();
      expect(unsynced, isEmpty);
    });

    test('DatabaseProvider singleton works', () {
      // Reset the singleton first
      DatabaseProvider.resetInstance();

      // Get instance
      final db1 = DatabaseProvider.instance;
      final db2 = DatabaseProvider.instance;

      // Should be the same instance
      expect(identical(db1, db2), isTrue);

      // Reset for cleanup
      DatabaseProvider.resetInstance();
    });
  });
}
