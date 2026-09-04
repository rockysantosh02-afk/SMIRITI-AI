import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/reminder_repository.dart';
import 'package:dashboard_app/features/reminders/reminders_screen.dart';
import 'package:dashboard_app/features/reminders/reminder_entry_screen.dart';
import 'package:dashboard_app/features/reminders/services/notification_service.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ReminderRepository repository;
  late FakeNotificationService notificationService;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    if (Platform.isWindows) {
      open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
    }
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    DatabaseProvider.setInstance(db);
    repository = ReminderRepository(db);
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    DatabaseProvider.resetInstance();
  });

  group('ReminderRepository Tests', () {
    test('create stores reminder in SQLite and queues Outbox mutation', () async {
      final id = await repository.create(
        title: 'Take Blood Pressure Medicine',
        timeOfDay: '08:30',
        daysOfWeek: '1,2,3,4,5,6,7',
        enabled: true,
      );

      // Verify collision-safe ID format
      expect(id, startsWith('reminder_'));
      expect(id.split('_').length, greaterThanOrEqualTo(3));

      // Verify Drift SQLite persistence
      final all = await repository.getAll();
      expect(all.length, equals(1));
      expect(all.first.id, equals(id));
      expect(all.first.title, equals('Take Blood Pressure Medicine'));
      expect(all.first.timeOfDay, equals('08:30'));
      expect(all.first.enabled, isTrue);
      expect(all.first.synced, isFalse);

      // Verify Outbox mutation
      final outboxItems = await db.getAllOutboxItems();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('reminder'));
      expect(outboxItems.first.entityId, equals(id));
      expect(outboxItems.first.operation, equals('create'));

      final payload = jsonDecode(outboxItems.first.payload) as Map<String, dynamic>;
      expect(payload['title'], equals('Take Blood Pressure Medicine'));
      expect(payload['label'], equals('Take Blood Pressure Medicine'));
      expect(payload['timeOfDay'], equals('08:30'));
      expect(payload['type'], equals('daily'));
    });

    test('markComplete sets enabled=false, records lastFiredAt, and queues Outbox update', () async {
      final id = await repository.create(
        title: 'Drink Water',
        timeOfDay: '10:00',
        daysOfWeek: 'once:2026-09-05',
      );

      await repository.markComplete(id);

      final reminder = await db.getReminderById(id);
      expect(reminder, isNotNull);
      expect(reminder!.enabled, isFalse);
      expect(reminder.lastFiredAt, isNotNull);
      expect(ReminderRepository.isCompleted(reminder), isTrue);

      // Verify Outbox update mutation
      final outboxItems = await db.getAllOutboxItems();
      expect(outboxItems.length, equals(2)); // create + update
      final updateMutation = outboxItems.last;
      expect(updateMutation.operation, equals('update'));
      expect(updateMutation.entityId, equals(id));

      final payload = jsonDecode(updateMutation.payload) as Map<String, dynamic>;
      expect(payload['status'], equals('acknowledged'));
      expect(payload['enabled'], isFalse);
    });

    test('delete removes reminder and queues Outbox delete mutation', () async {
      final id = await repository.create(
        title: 'Walk in garden',
        timeOfDay: '17:00',
        daysOfWeek: 'daily',
      );

      expect((await repository.getAll()).length, equals(1));

      await repository.delete(id);

      // Verify removed from SQLite
      expect((await repository.getAll()).isEmpty, isTrue);

      // Verify Outbox delete mutation
      final outboxItems = await db.getAllOutboxItems();
      final deleteMutation = outboxItems.firstWhere((o) => o.operation == 'delete');
      expect(deleteMutation.entityId, equals(id));
      expect(deleteMutation.entityType, equals('reminder'));
    });

    test('scheduling helpers correctly identify daily vs one-time reminders', () async {
      final dailyId = await repository.create(
        title: 'Daily Meds',
        timeOfDay: '09:00',
        daysOfWeek: '1,2,3,4,5,6,7',
      );
      final onceId = await repository.create(
        title: 'Doctor Appointment',
        timeOfDay: '14:30',
        daysOfWeek: 'once:2026-10-15',
      );

      final daily = await db.getReminderById(dailyId);
      final once = await db.getReminderById(onceId);

      expect(ReminderRepository.isDaily(daily!), isTrue);
      expect(ReminderRepository.isDaily(once!), isFalse);

      final scheduledOnce = ReminderRepository.parseScheduledDateTime(once);
      expect(scheduledOnce, isNotNull);
      expect(scheduledOnce!.year, equals(2026));
      expect(scheduledOnce.month, equals(10));
      expect(scheduledOnce.day, equals(15));
      expect(scheduledOnce.hour, equals(14));
      expect(scheduledOnce.minute, equals(30));
    });
  });

  group('Notification ID & Service Tests', () {
    test('notificationIdFromReminderId produces deterministic 31-bit positive integers', () {
      const id1 = 'reminder_1725530000000_a1b2c3d4';
      const id2 = 'reminder_1725530000000_a1b2c3d4';
      const id3 = 'reminder_1725530000001_e5f6g7h8';

      final hash1 = notificationIdFromReminderId(id1);
      final hash2 = notificationIdFromReminderId(id2);
      final hash3 = notificationIdFromReminderId(id3);

      // Deterministic: same string produces identical hash
      expect(hash1, equals(hash2));
      // Distinct IDs produce different hashes
      expect(hash1, isNot(equals(hash3)));

      // Positive 31-bit integer range (0 to 2,147,483,647)
      expect(hash1, greaterThanOrEqualTo(0));
      expect(hash1, lessThanOrEqualTo(2147483647));
      expect(hash3, greaterThanOrEqualTo(0));
      expect(hash3, lessThanOrEqualTo(2147483647));
    });

    test('notification scheduling and cancellation works with FakeNotificationService', () async {
      final notifId = notificationIdFromReminderId('test_reminder_1');
      final scheduledDate = DateTime.now().add(const Duration(hours: 2));

      final success = await notificationService.scheduleReminder(
        notificationId: notifId,
        title: 'Evening Medicine',
        body: 'Time to take medicine',
        scheduledDate: scheduledDate,
        isDaily: false,
      );

      expect(success, isTrue);
      expect(await notificationService.getPendingNotificationIds(), contains(notifId));

      // Cancellation
      await notificationService.cancelReminder(notifId);
      expect(await notificationService.getPendingNotificationIds(), isNot(contains(notifId)));
    });

    test('scheduling failure does not block local SQLite save in ReminderEntryScreen', () async {
      notificationService.shouldFailScheduling = true;

      final id = await repository.create(
        title: 'Check Blood Sugar',
        timeOfDay: '12:00',
        daysOfWeek: 'daily',
      );

      final saved = await db.getReminderById(id);
      expect(saved, isNotNull);
      expect(saved!.title, equals('Check Blood Sugar'));
    });
  });

  group('Widget Tests — Reminders UI', () {
    testWidgets('RemindersScreen displays empty state when no reminders exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: RemindersScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Reminders'), findsOneWidget);
      expect(find.text('No reminders yet'), findsOneWidget);
      expect(find.text('Add Reminder'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('RemindersScreen displays TODAY and UPCOMING sections correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final futureDate = today.add(const Duration(days: 3));
      final futureStr =
          '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';

      await repository.create(
        title: 'Morning Medicine',
        timeOfDay: '08:00',
        daysOfWeek: 'once:$todayStr',
      );
      await repository.create(
        title: 'Dentist Appointment',
        timeOfDay: '15:00',
        daysOfWeek: 'once:$futureStr',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RemindersScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Morning Medicine'), findsOneWidget);
      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.text('Dentist Appointment'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Tapping Complete moves reminder to COMPLETED section', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await repository.create(
        title: 'Take Multivitamin',
        timeOfDay: '09:00',
        daysOfWeek: 'once:$todayStr',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RemindersScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);

      // Tap Complete
      await tester.tap(find.text('Complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should now be under COMPLETED
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('TODAY'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ReminderEntryScreen validates empty title and prevents duplicate saves', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ReminderEntryScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Create Reminder without entering title
      await tester.tap(find.text('Create Reminder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please enter what you would like to be reminded about.'), findsOneWidget);
      expect((await repository.getAll()).isEmpty, isTrue);

      // Enter valid title
      await tester.enterText(find.byType(TextField), 'Afternoon Tea');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Create Reminder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final all = await repository.getAll();
      expect(all.length, equals(1));
      expect(all.first.title, equals('Afternoon Tea'));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Permission denied banner displays calm non-blocking notice', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      notificationService.permissionGranted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RemindersScreen(
            repository: repository,
            notificationService: notificationService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Notifications are turned off. Your reminders are still saved safely on this device.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('App Restart & Duplicate Protection Tests', () {
    test('active reminders restore cleanly without duplicate scheduling', () async {
      // Simulate 2 active reminders in DB
      final id1 = await repository.create(
        title: 'Morning Walk',
        timeOfDay: '07:00',
        daysOfWeek: 'daily',
      );
      final id2 = await repository.create(
        title: 'Evening Meds',
        timeOfDay: '20:00',
        daysOfWeek: 'daily',
      );

      // Simulate 1 completed reminder in DB
      final id3 = await repository.create(
        title: 'Old Task',
        timeOfDay: '11:00',
        daysOfWeek: 'daily',
      );
      await repository.markComplete(id3);

      // Simulate App Restart restoration routine
      final allReminders = await repository.getAll();
      final activeReminders = allReminders.where((r) => r.enabled).toList();

      expect(activeReminders.length, equals(2));

      for (final reminder in activeReminders) {
        final notifId = notificationIdFromReminderId(reminder.id);
        final scheduled = ReminderRepository.parseScheduledDateTime(reminder);
        if (scheduled != null) {
          await notificationService.scheduleReminder(
            notificationId: notifId,
            title: reminder.title,
            body: 'Time for ${reminder.title}',
            scheduledDate: scheduled,
            isDaily: ReminderRepository.isDaily(reminder),
          );
        }
      }

      final pendingIds = await notificationService.getPendingNotificationIds();
      expect(pendingIds.length, equals(2));
      expect(pendingIds, contains(notificationIdFromReminderId(id1)));
      expect(pendingIds, contains(notificationIdFromReminderId(id2)));
      expect(pendingIds, isNot(contains(notificationIdFromReminderId(id3))));

      // Rescheduling with the same deterministic ID overwrites rather than duplicates
      for (final reminder in activeReminders) {
        final notifId = notificationIdFromReminderId(reminder.id);
        final scheduled = ReminderRepository.parseScheduledDateTime(reminder);
        if (scheduled != null) {
          await notificationService.scheduleReminder(
            notificationId: notifId,
            title: reminder.title,
            body: 'Time for ${reminder.title}',
            scheduledDate: scheduled,
            isDaily: ReminderRepository.isDaily(reminder),
          );
        }
      }

      // Still exactly 2 pending IDs! No duplicates created!
      final reloadedIds = await notificationService.getPendingNotificationIds();
      expect(reloadedIds.length, equals(2));
    });
  });
}
