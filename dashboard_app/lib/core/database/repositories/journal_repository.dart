import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';

/// Repository for journal entry operations.
/// All write operations (create/update/delete) enqueue sync events to the Outbox.
class JournalRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  JournalRepository(this._db);

  /// Creates a new journal entry and enqueues a sync event.
  Future<String> create({
    required String title,
    required String body,
    String? mood,
    String? photoPath,
    String? generatedStory,
  }) async {
    final now = DateTime.now();
    final id = 'journal_${now.millisecondsSinceEpoch}_${_uuid.v4()}';

    await _db.batch((batch) {
      batch.insert(
        _db.journalEntries,
        JournalEntriesCompanion(
          id: Value(id),
          title: Value(title),
          body: Value(body),
          mood: Value(mood),
          photoPath: Value(photoPath),
          generatedStory: Value(generatedStory),
          createdAt: Value(now),
          updatedAt: Value(now),
          synced: const Value(false),
          deleted: const Value(false),
        ),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('journal_entry'),
          entityId: Value(id),
          operation: const Value('create'),
          payload: Value(jsonEncode({
            'title': title,
            'body': body,
            if (mood != null) 'mood': mood,
            if (photoPath != null) 'photoPath': photoPath,
            if (generatedStory != null) 'generatedStory': generatedStory,
          })),
          createdAt: Value(now),
        ),
      );
    });

    return id;
  }

  /// Updates an existing journal entry and enqueues a sync event.
  Future<void> update({
    required String id,
    required String title,
    required String body,
    String? mood,
    String? photoPath,
    String? generatedStory,
  }) async {
    final existing = await _db.getJournalEntryById(id);
    if (existing == null) return;

    final now = DateTime.now();

    await _db.batch((batch) {
      batch.update(
        _db.journalEntries,
        JournalEntriesCompanion(
          title: Value(title),
          body: Value(body),
          mood: Value(mood),
          photoPath: Value(photoPath),
          generatedStory: Value(generatedStory ?? existing.generatedStory),
          updatedAt: Value(now),
          synced: const Value(false),
        ),
        where: (t) => t.id.equals(id),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('journal_entry'),
          entityId: Value(id),
          operation: const Value('update'),
          payload: Value(jsonEncode({
            'title': title,
            'body': body,
            if (mood != null) 'mood': mood,
            if (photoPath != null) 'photoPath': photoPath,
            if ((generatedStory ?? existing.generatedStory) != null)
              'generatedStory': generatedStory ?? existing.generatedStory,
          })),
          createdAt: Value(now),
        ),
      );
    });
  }

  /// Saves or updates the AI-generated story for an existing journal entry.
  Future<void> saveGeneratedStory({
    required String id,
    required String story,
  }) async {
    final existing = await _db.getJournalEntryById(id);
    if (existing == null) return;

    final now = DateTime.now();

    await _db.batch((batch) {
      batch.update(
        _db.journalEntries,
        JournalEntriesCompanion(
          generatedStory: Value(story),
          updatedAt: Value(now),
          synced: const Value(false),
        ),
        where: (t) => t.id.equals(id),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('journal_entry'),
          entityId: Value(id),
          operation: const Value('update'),
          payload: Value(jsonEncode({
            'title': existing.title,
            'body': existing.body,
            if (existing.mood != null) 'mood': existing.mood,
            if (existing.photoPath != null) 'photoPath': existing.photoPath,
            'generatedStory': story,
          })),
          createdAt: Value(now),
        ),
      );
    });
  }

  /// Soft-deletes a journal entry and enqueues a sync event.
  Future<void> softDelete(String id) async {
    final existing = await _db.getJournalEntryById(id);
    if (existing == null) return;

    final now = DateTime.now();

    await _db.batch((batch) {
      batch.update(
        _db.journalEntries,
        const JournalEntriesCompanion(deleted: Value(true)),
        where: (t) => t.id.equals(id),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('journal_entry'),
          entityId: Value(id),
          operation: const Value('delete'),
          payload: const Value('{}'),
          createdAt: Value(now),
        ),
      );
    });
  }

  /// Watches all non-deleted journal entries, ordered newest first.
  Stream<List<JournalEntry>> watchAll() {
    final query = _db.select(_db.journalEntries)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Gets all non-deleted entries, ordered newest first.
  Future<List<JournalEntry>> getAll() {
    final query = _db.select(_db.journalEntries)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Gets entries that haven't been synced yet.
  Future<List<JournalEntry>> getUnsynced() {
    return _db.getUnsyncedJournalEntries();
  }

  /// Marks an entry as synced after successful cloud sync.
  Future<void> markSynced(String id) async {
    final existing = await _db.getJournalEntryById(id);
    if (existing == null) return;

    await _db.update(_db.journalEntries).replace(JournalEntry(
      id: existing.id,
      title: existing.title,
      body: existing.body,
      mood: existing.mood,
      photoPath: existing.photoPath,
      generatedStory: existing.generatedStory,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      synced: true,
      deleted: existing.deleted,
    ));
  }
}
