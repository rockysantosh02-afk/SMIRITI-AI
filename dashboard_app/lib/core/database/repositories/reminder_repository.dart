import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';

/// Repository for reminder operations.
/// All write operations (create/update/complete/delete) enqueue sync events to the Outbox.
class ReminderRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ReminderRepository(this._db);

  /// Helper to check if a reminder is recurring daily.
  static bool isDaily(Reminder reminder) {
    return reminder.daysOfWeek == '1,2,3,4,5,6,7' ||
        reminder.daysOfWeek == 'daily';
  }

  /// Helper to check if a reminder has been marked completed.
  static bool isCompleted(Reminder reminder) {
    return !reminder.enabled && reminder.lastFiredAt != null;
  }

  /// Parses the next scheduled [DateTime] for a reminder.
  static DateTime? parseScheduledDateTime(Reminder reminder) {
    final timeParts = reminder.timeOfDay.split(':');
    if (timeParts.length != 2) return null;
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return null;

    final now = DateTime.now();

    if (reminder.daysOfWeek.startsWith('once:')) {
      final dateStr = reminder.daysOfWeek.substring(5);
      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return null;
      final year = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final day = int.tryParse(dateParts[2]);
      if (year == null || month == null || day == null) return null;
      return DateTime(year, month, day, hour, minute);
    } else {
      // Daily or repeating: schedule for today or tomorrow
      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }
  }

  /// Creates a new reminder and enqueues a sync event to the Outbox.
  Future<String> create({
    required String title,
    required String timeOfDay,
    required String daysOfWeek,
    bool enabled = true,
  }) async {
    final now = DateTime.now();
    final id =
        'reminder_${now.millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';

    // Calculate scheduled time for backend sync compatibility
    DateTime? scheduledTime;
    final timeParts = timeOfDay.split(':');
    if (timeParts.length == 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      if (daysOfWeek.startsWith('once:')) {
        final dateStr = daysOfWeek.substring(5);
        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          scheduledTime = DateTime(
            int.tryParse(dateParts[0]) ?? now.year,
            int.tryParse(dateParts[1]) ?? now.month,
            int.tryParse(dateParts[2]) ?? now.day,
            hour,
            minute,
          );
        }
      }
      scheduledTime ??= DateTime(now.year, now.month, now.day, hour, minute);
    }
    scheduledTime ??= now;

    final isOnce = daysOfWeek.startsWith('once:');

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
            'label': title,
            'timeOfDay': timeOfDay,
            'daysOfWeek': daysOfWeek,
            'enabled': enabled,
            'scheduled_time': scheduledTime!.toIso8601String(),
            'type': isOnce ? 'one_time' : 'daily',
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
    final isOnce = daysOfWeek.startsWith('once:');

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
            'id': id,
            'title': title,
            'label': title,
            'timeOfDay': timeOfDay,
            'daysOfWeek': daysOfWeek,
            'enabled': enabled,
            'last_fired_at': lastFiredAt?.toIso8601String(),
            'type': isOnce ? 'one_time' : 'daily',
          })),
          createdAt: Value(now),
        ),
      );
    });
  }

  /// Marks a reminder as complete. Disables the reminder and records the completion timestamp.
  Future<void> markComplete(String id) async {
    final existing = await _db.getReminderById(id);
    if (existing == null) return;

    final now = DateTime.now();

    await _db.batch((batch) {
      batch.update(
        _db.reminders,
        RemindersCompanion(
          enabled: const Value(false),
          lastFiredAt: Value(now),
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
            'id': id,
            'enabled': false,
            'last_fired_at': now.toIso8601String(),
            'status': 'acknowledged',
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
    final now = ReminderTimeOfDay.now();
    final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final todayStr =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final allEnabled = await _db.getEnabledReminders();
    return allEnabled.where((reminder) {
      // One-time reminder
      if (reminder.daysOfWeek.startsWith('once:')) {
        final reminderDate = reminder.daysOfWeek.substring(5);
        if (reminderDate != todayStr) return false;
      } else {
        // Daily or specific days of week
        final days = reminder.daysOfWeek.split(',');
        if (!days.contains(today.toString()) &&
            reminder.daysOfWeek != 'daily') {
          return false;
        }
      }

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

  /// Deletes a reminder locally and enqueues an Outbox deletion event.
  Future<void> delete(String id) async {
    final now = DateTime.now();

    await _db.batch((batch) {
      batch.deleteWhere(_db.reminders, (t) => t.id.equals(id));
      batch.insert(
        _db.outbox,
        OutboxCompanion(
          entityType: const Value('reminder'),
          entityId: Value(id),
          operation: const Value('delete'),
          payload: Value(jsonEncode({'id': id})),
          createdAt: Value(now),
        ),
      );
    });
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
class ReminderTimeOfDay {
  final int hour;
  final int minute;

  const ReminderTimeOfDay({required this.hour, required this.minute});

  factory ReminderTimeOfDay.now() {
    final now = DateTime.now();
    return ReminderTimeOfDay(hour: now.hour, minute: now.minute);
  }
}

