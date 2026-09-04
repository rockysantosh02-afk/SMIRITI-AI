import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';

/// Repository for managing family members stored locally for personal memory games.
/// All write operations enqueue sync events to the Outbox.
class FamilyRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  FamilyRepository(this._db);

  /// Retrieves all family members ordered by creation date.
  Future<List<FamilyMember>> getAllMembers() async {
    final query = _db.select(_db.familyMembers)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.get();
  }

  /// Watches all family members as a stream.
  Stream<List<FamilyMember>> watchMembers() {
    final query = _db.select(_db.familyMembers)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Gets a specific member by ID.
  Future<FamilyMember?> getMemberById(String id) {
    return _db.getFamilyMemberById(id);
  }

  /// Adds a new family member, saving locally and queuing to outbox.
  Future<String> addMember({
    required String name,
    required String relation,
    String? photoPath,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.batch((batch) {
      batch.insert(
        _db.familyMembers,
        FamilyMembersCompanion(
          id: Value(id),
          name: Value(name),
          relation: Value(relation),
          photoPath: Value(photoPath),
          notes: Value(notes),
          createdAt: Value(now),
          synced: const Value(false),
        ),
      );

      final payload = jsonEncode({
        'id': id,
        'name': name,
        'relation': relation,
        'photoPath': photoPath,
        'notes': notes,
        'createdAt': now.toIso8601String(),
      });

      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('family_member'),
          entityId: Value(id),
          operation: const Value('create'),
          payload: Value(payload),
          createdAt: Value(now),
        ),
      );
    });

    return id;
  }

  /// Deletes a family member locally and queues deletion to outbox.
  Future<void> deleteMember(String id) async {
    final now = DateTime.now();

    await _db.batch((batch) {
      batch.deleteWhere(_db.familyMembers, (t) => t.id.equals(id));

      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('family_member'),
          entityId: Value(id),
          operation: const Value('delete'),
          payload: Value('{"id":"$id"}'),
          createdAt: Value(now),
        ),
      );
    });
  }
}
