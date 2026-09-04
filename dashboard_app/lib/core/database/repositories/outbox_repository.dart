import 'package:drift/drift.dart';

import '../app_database.dart';

/// Repository for outbox operations.
/// The outbox pattern ensures reliable sync of entities to the cloud.
class OutboxRepository {
  final AppDatabase _db;

  OutboxRepository(this._db);

  /// Enqueues a new sync operation.
  Future<int> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) async {
    return _db.insertOutboxItem(OutboxCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      createdAt: Value(DateTime.now()),
    ));
  }

  /// Gets pending sync items up to the given limit.
  Future<List<OutboxData>> getPending({int limit = 50}) async {
    final query = _db.select(_db.outbox)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(limit);
    return query.get();
  }

  /// Marks items as synced by deleting them from the outbox.
  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.outbox)..where((t) => t.id.isIn(ids))).go();
  }

  /// Increments the retry count for a failed sync item.
  Future<void> incrementRetry(int id, String error) {
    return _db.incrementOutboxRetry(id, error);
  }

  /// Gets the current outbox count.
  Future<int> getCount() {
    return _db.getOutboxCount();
  }

  /// Watches the outbox count for reactive UI.
  Stream<int> watchCount() {
    return _db.select(_db.outbox).watch().map((items) => items.length);
  }
}
