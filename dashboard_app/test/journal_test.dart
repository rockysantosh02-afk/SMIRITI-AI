import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/journal_repository.dart';
import 'package:dashboard_app/features/journal/journal_screen.dart';
import 'package:dashboard_app/features/journal/journal_entry_screen.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Personal Memory Journal Tests', () {
    late AppDatabase database;
    late JournalRepository repository;

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      if (Platform.isWindows) {
        open.overrideForAll(() => DynamicLibrary.open(_sqlite3DllPath));
      }
    });

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      DatabaseProvider.setInstance(database);
      repository = JournalRepository(database);
    });

    tearDown(() async {
      DatabaseProvider.resetInstance();
    });

    // ==========================================
    // 1. Journal Repository Tests
    // ==========================================
    test('JournalRepository creates entry in SQLite and enqueues Outbox mutation', () async {
      final id = await repository.create(
        title: 'Morning in Majuli',
        body: 'Walked near the river, birds singing in the mist.',
        mood: 'peaceful',
      );

      expect(id, isNotEmpty);

      // Verify retrieved entry
      final entries = await repository.getAll();
      expect(entries.length, equals(1));
      expect(entries.first.id, equals(id));
      expect(entries.first.title, equals('Morning in Majuli'));
      expect(entries.first.body, equals('Walked near the river, birds singing in the mist.'));
      expect(entries.first.synced, isFalse);
      expect(entries.first.deleted, isFalse);

      // Verify Outbox mutation is enqueued
      final outboxItems = await database.select(database.outbox).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('journal_entry'));
      expect(outboxItems.first.entityId, equals(id));
      expect(outboxItems.first.operation, equals('create'));
      expect(outboxItems.first.payload.contains('Morning in Majuli'), isTrue);
    });

    test('JournalRepository updates entry and soft-deletes with Outbox mutations', () async {
      final id = await repository.create(
        title: 'Original Title',
        body: 'Original Body',
      );

      // Update
      await repository.update(
        id: id,
        title: 'Updated Title',
        body: 'Updated Body',
      );

      final updated = await database.getJournalEntryById(id);
      expect(updated?.title, equals('Updated Title'));

      // Soft-delete
      await repository.softDelete(id);

      final nonDeleted = await repository.getAll();
      expect(nonDeleted, isEmpty);

      // Outbox should contain create, update, delete
      final outboxItems = await database.select(database.outbox).get();
      expect(outboxItems.length, equals(3));
      expect(outboxItems[1].operation, equals('update'));
      expect(outboxItems[2].operation, equals('delete'));
    });

    // ==========================================
    // 2. Journal Screen Widget Tests
    // ==========================================
    testWidgets('JournalScreen shows empty state when no memories exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JournalScreen(repository: repository),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Your memories will appear here'), findsOneWidget);
      expect(find.textContaining('Every memory is special'), findsOneWidget);
      expect(find.textContaining('Add Your First Memory'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('JournalScreen displays existing journal memory card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await repository.create(
        title: 'Bihu Celebration with Family',
        body: 'We made pitha and danced to the dhol rhythms.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JournalScreen(repository: repository),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Bihu Celebration with Family'), findsOneWidget);
      expect(find.textContaining('We made pitha'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('JournalScreen add button navigates to JournalEntryScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JournalScreen(repository: repository),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final addButton = find.byKey(const Key('add_memory_button'));
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.byType(JournalEntryScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // ==========================================
    // 3. Journal Entry Screen Widget Tests
    // ==========================================
    testWidgets('JournalEntryScreen allows entering title, memory, and saves to SQLite',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: JournalEntryScreen(repository: repository),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter Title
      final titleInput = find.byKey(const Key('journal_title_input'));
      expect(titleInput, findsOneWidget);
      await tester.enterText(titleInput, 'Afternoon in the Tea Garden');

      // Enter Memory Content
      final bodyInput = find.byKey(const Key('journal_body_input'));
      expect(bodyInput, findsOneWidget);
      await tester.enterText(bodyInput, 'The green leaves smelled fresh and peaceful.');

      // Tap Save Button
      final saveButton = find.byKey(const Key('save_memory_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify database record was saved to SQLite
      final entries = await repository.getAll();
      expect(entries.length, equals(1));
      expect(entries.first.title, equals('Afternoon in the Tea Garden'));
      expect(entries.first.body, equals('The green leaves smelled fresh and peaceful.'));

      // Verify Outbox mutation was created
      final outboxItems = await database.select(database.outbox).get();
      expect(outboxItems.length, equals(1));
      expect(outboxItems.first.entityType, equals('journal_entry'));
      expect(outboxItems.first.operation, equals('create'));

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
