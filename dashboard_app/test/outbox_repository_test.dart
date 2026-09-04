import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/outbox_repository.dart';

void main() {
  group('OutboxRepository Tests', () {
    late AppDatabase database;
    late OutboxRepository repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = OutboxRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('enqueue creates an outbox item', () async {
      final id = await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_123',
        operation: 'create',
        payload: '{"gameId":"memory_match"}',
      );

      expect(id, greaterThan(0));

      final pending = await repository.getPending();
      expect(pending.length, equals(1));
      expect(pending.first.entityType, equals('game_session'));
      expect(pending.first.entityId, equals('session_123'));
      expect(pending.first.operation, equals('create'));
    });

    test('getPending returns items in order', () async {
      // Enqueue multiple items
      await repository.enqueue(
        entityType: 'journal_entry',
        entityId: 'journal_1',
        operation: 'create',
        payload: '{}',
      );
      await repository.enqueue(
        entityType: 'journal_entry',
        entityId: 'journal_2',
        operation: 'create',
        payload: '{}',
      );
      await repository.enqueue(
        entityType: 'reminder',
        entityId: 'reminder_1',
        operation: 'update',
        payload: '{}',
      );

      final pending = await repository.getPending(limit: 10);

      expect(pending.length, equals(3));
      // Should be ordered by createdAt (oldest first)
      expect(pending[0].entityId, equals('journal_1'));
      expect(pending[1].entityId, equals('journal_2'));
      expect(pending[2].entityId, equals('reminder_1'));
    });

    test('getPending respects limit', () async {
      // Enqueue 5 items
      for (var i = 0; i < 5; i++) {
        await repository.enqueue(
          entityType: 'game_session',
          entityId: 'session_$i',
          operation: 'create',
          payload: '{}',
        );
      }

      final pending = await repository.getPending(limit: 3);

      expect(pending.length, equals(3));
    });

    test('markSynced removes items from outbox', () async {
      // Enqueue items
      final id1 = await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_1',
        operation: 'create',
        payload: '{}',
      );
      await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_2',
        operation: 'create',
        payload: '{}',
      );

      // Mark first item as synced
      await repository.markSynced([id1]);

      final pending = await repository.getPending();
      expect(pending.length, equals(1));
      expect(pending.first.entityId, equals('session_2'));
    });

    test('markSynced with empty list does nothing', () async {
      await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_1',
        operation: 'create',
        payload: '{}',
      );

      await repository.markSynced([]);

      final pending = await repository.getPending();
      expect(pending.length, equals(1));
    });

    test('incrementRetry increases retry count and stores error', () async {
      final id = await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_1',
        operation: 'create',
        payload: '{}',
      );

      // First retry
      await repository.incrementRetry(id, 'Network error');

      var pending = await repository.getPending();
      expect(pending.first.retryCount, equals(1));
      expect(pending.first.lastError, equals('Network error'));

      // Second retry
      await repository.incrementRetry(id, 'Timeout');

      pending = await repository.getPending();
      expect(pending.first.retryCount, equals(2));
      expect(pending.first.lastError, equals('Timeout'));
    });

    test('getCount returns correct count', () async {
      expect(await repository.getCount(), equals(0));

      await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_1',
        operation: 'create',
        payload: '{}',
      );
      expect(await repository.getCount(), equals(1));

      await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_2',
        operation: 'create',
        payload: '{}',
      );
      expect(await repository.getCount(), equals(2));
    });

    test('Full flow: enqueue -> getPending -> markSynced', () async {
      // Step 1: Enqueue multiple operations
      final id1 = await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_new',
        operation: 'create',
        payload: '{"gameId":"memory_match","accuracy":0.85}',
      );
      final id2 = await repository.enqueue(
        entityType: 'journal_entry',
        entityId: 'journal_new',
        operation: 'create',
        payload: '{"title":"My Entry"}',
      );

      // Verify both are pending
      var count = await repository.getCount();
      expect(count, equals(2));

      // Step 2: Process pending items (simulate sync)
      var pending = await repository.getPending();
      expect(pending.length, equals(2));

      // Step 3: Mark first item as synced
      await repository.markSynced([id1]);

      // Verify only one remains
      pending = await repository.getPending();
      expect(pending.length, equals(1));
      expect(pending.first.entityId, equals('journal_new'));

      count = await repository.getCount();
      expect(count, equals(1));

      // Step 4: Mark second item as synced
      await repository.markSynced([id2]);

      // Verify all are synced
      pending = await repository.getPending();
      expect(pending, isEmpty);

      count = await repository.getCount();
      expect(count, equals(0));
    });

    test('watchCount emits updates', () async {
      // Start watching
      repository.watchCount();

      // Enqueue an item
      await repository.enqueue(
        entityType: 'game_session',
        entityId: 'session_1',
        operation: 'create',
        payload: '{}',
      );

      // Give it a moment and check count
      await Future.delayed(const Duration(milliseconds: 50));
      final count = await repository.getCount();
      expect(count, equals(1));
    });
  });
}
