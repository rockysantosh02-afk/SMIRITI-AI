import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

/// Repository for reminder operations.
/// All write operations (create/update) enqueue sync events to the Outbox.
class ReminderRepository {
  final AppDatabase _db;

  ReminderRepository(this._db);

  /// Creates a new reminder and enqueues a sync event.
  Future<String> create({
    required String title,
    required String timeOfDay,
    required String daysOfWeek,
    bool enabled = true,
  }) async {
    final id = 'reminder_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    await _db.batch((batch) {
      batch.insert(
        _db.reminders,
        RemindersCompanion(
          id: Value(id),
          title: Value(title),
          timeOfDay: Value(timeOfDay),
          daysOfWeek: Value(daysOfWeek),
          enabled: Value(enabled),
          createdAt: Value(now),
          synced: const Value(false),
        ),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('reminder'),
          entityId: Value(id),
          operation: const Value('create'),
          payload: Value(jsonEncode({
            'title': title,
            'timeOfDay': timeOfDay,
            'daysOfWeek': daysOfWeek,
            'enabled': enabled,
          })),
          createdAt: Value(now),
        ),
      );
    });

    return id;
  }

  /// Updates an existing reminder and enqueues a sync event.
  Future<void> update({
    required String id,
    required String title,
    required String timeOfDay,
    required String daysOfWeek,
    required bool enabled,
    DateTime? lastFiredAt,
    int followUpCount = 0,
  }) async {
    final existing = await _db.getReminderById(id);
    if (existing == null) return;

    final now = DateTime.now();

    await _db.batch((batch) {
      batch.update(
        _db.reminders,
        RemindersCompanion(
          title: Value(title),
          timeOfDay: Value(timeOfDay),
          daysOfWeek: Value(daysOfWeek),
          enabled: Value(enabled),
          lastFiredAt: Value(lastFiredAt),
          followUpCount: Value(followUpCount),
          synced: const Value(false),
        ),
        where: (t) => t.id.equals(id),
      );
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('reminder'),
          entityId: Value(id),
          operation: const Value('update'),
          payload: Value(jsonEncode({
            'title': title,
            'timeOfDay': timeOfDay,
            'daysOfWeek': daysOfWeek,
            'enabled': enabled,
          })),
          createdAt: Value(now),
        ),
      );
    });
  }

  /// Watches all reminders.
  Stream<List<Reminder>> watchAll() {
    return _db.watchAllReminders();
  }

  /// Gets all reminders.
  Future<List<Reminder>> getAll() {
    return _db.getAllReminders();
  }

  /// Gets reminders that are due right now based on time and day of week.
  Future<List<Reminder>> getDueReminders() async {
    final now = TimeOfDay.now();
    final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday

    final allEnabled = await _db.getEnabledReminders();
    return allEnabled.where((reminder) {
      // Parse days of week (e.g., "1,2,3,4,5" for weekdays)
      final days = reminder.daysOfWeek.split(',');
      if (!days.contains(today.toString())) return false;

      // Check if the reminder time matches current time (within 1 minute window)
      final reminderTime = reminder.timeOfDay.split(':');
      if (reminderTime.length != 2) return false;

      final reminderHour = int.tryParse(reminderTime[0]) ?? -1;
      final reminderMinute = int.tryParse(reminderTime[1]) ?? -1;

      // Allow 1 minute window
      return (now.hour == reminderHour) &&
          ((now.minute - reminderMinute).abs() <= 1);
    }).toList();
  }

  /// Deletes a reminder (does NOT enqueue - deletions are handled separately).
  Future<void> delete(String id) {
    return _db.deleteReminder(id);
  }

  /// Marks a reminder as synced after successful cloud sync.
  Future<void> markSynced(String id) async {
    final existing = await _db.getReminderById(id);
    if (existing == null) return;

    await _db.update(_db.reminders).replace(Reminder(
      id: existing.id,
      title: existing.title,
      timeOfDay: existing.timeOfDay,
      daysOfWeek: existing.daysOfWeek,
      enabled: existing.enabled,
      lastFiredAt: existing.lastFiredAt,
      followUpCount: existing.followUpCount,
      createdAt: existing.createdAt,
      synced: true,
    ));
  }
}

/// Simple time of day helper
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }
}
