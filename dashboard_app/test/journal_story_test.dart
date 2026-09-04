import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/journal_repository.dart';
import 'package:dashboard_app/core/sync/http_client.dart';
import 'package:dashboard_app/features/journal/journal_story_service.dart';
import 'package:dashboard_app/features/journal/journal_entry_screen.dart';
import 'package:dashboard_app/features/journal/journal_screen.dart';

final _sqlite3DllPath = '${Directory.systemTemp.path}/sqlite/sqlite3.dll';

/// Test FakeHttpClient for mocking backend responses.
class FakeHttpClient implements HttpClient {
  FutureOr<Response> Function(String path, Object? data)? onPost;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (onPost != null) {
      final res = await onPost!(path, data);
      return res as Response<T>;
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'story': 'A lovely generated story.'} as T,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    throw UnimplementedError();
  }

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3.2: AI Story Generator Tests', () {
    late AppDatabase database;
    late JournalRepository repository;
    late FakeHttpClient fakeHttpClient;
    late JournalStoryService storyService;

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
      fakeHttpClient = FakeHttpClient();
      storyService = JournalStoryService(
        client: fakeHttpClient,
        baseUrl: 'http://localhost:8000',
      );
    });

    tearDown(() async {
      DatabaseProvider.resetInstance();
    });

    // ==========================================
    // 1. Database & Outbox Tests
    // ==========================================
    test('JournalRepository.saveGeneratedStory updates SQLite and queues Outbox UPDATE', () async {
      final id = await repository.create(
        title: 'Morning Walk',
        body: 'Walking by the river mist.',
      );

      const storyText = 'I cherish this peaceful morning walking by the river.';
      await repository.saveGeneratedStory(id: id, story: storyText);

      // Verify SQLite record updated
      final entry = await database.getJournalEntryById(id);
      expect(entry, isNotNull);
      expect(entry!.generatedStory, equals(storyText));
      expect(entry.synced, isFalse);

      // Verify Outbox update mutation
      final outboxItems = await database.select(database.outbox).get();
      expect(outboxItems.length, equals(2));
      expect(outboxItems[1].operation, equals('update'));
      expect(outboxItems[1].entityType, equals('journal_entry'));
      expect(outboxItems[1].entityId, equals(id));
      expect(outboxItems[1].payload.contains(storyText), isTrue);
    });

    test('Drift schema migration to version 2 preserves existing entries', () async {
      // Create an entry in current database
      final id = await repository.create(
        title: 'Pre-migration Memory',
        body: 'This entry should survive schema migration.',
      );

      // Verify entry exists and generatedStory is null
      final entryBefore = await database.getJournalEntryById(id);
      expect(entryBefore, isNotNull);
      expect(entryBefore!.generatedStory, isNull);

      // Verify schema version is 2
      expect(database.schemaVersion, equals(2));

      // Verify can now write generatedStory without error
      await repository.saveGeneratedStory(id: id, story: 'Survives and gets story.');
      final entryAfter = await database.getJournalEntryById(id);
      expect(entryAfter!.generatedStory, equals('Survives and gets story.'));
      expect(entryAfter.title, equals('Pre-migration Memory'));
    });

    // ==========================================
    // 2. JournalStoryService Tests
    // ==========================================
    test('JournalStoryService returns StoryResult.ok on 200 response', () async {
      fakeHttpClient.onPost = (path, data) => Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {'story': 'Walking in the fresh tea garden filled my heart with calm.'},
          );

      final result = await storyService.generateStory(
        title: 'Tea Garden',
        content: 'Fresh leaves everywhere.',
      );

      expect(result.success, isTrue);
      expect(result.story, equals('Walking in the fresh tea garden filled my heart with calm.'));
    });

    test('JournalStoryService handles connection error gracefully with isOffline=true', () async {
      fakeHttpClient.onPost = (path, data) => throw DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.connectionTimeout,
            error: const SocketException('No route to host'),
          );

      final result = await storyService.generateStory(
        title: 'Tea Garden',
        content: 'Fresh leaves everywhere.',
      );

      expect(result.success, isFalse);
      expect(result.isOffline, isTrue);
      expect(result.errorMessage, contains('when you are connected'));
    });

    // ==========================================
    // 3. UI Widget Tests (JournalEntryScreen)
    // ==========================================
    testWidgets('JournalEntryScreen shows "Create a Story" button for existing entry and displays generated story',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final id = await repository.create(
        title: 'Majuli Island Sunset',
        body: 'Watching the red sky reflection over the water.',
      );
      final entry = await database.getJournalEntryById(id);

      fakeHttpClient.onPost = (path, data) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {'story': 'The sunset over Majuli Island remains a comforting glow in my heart.'},
        );
      };

      await tester.pumpWidget(
        MaterialApp(
          home: JournalEntryScreen(
            repository: repository,
            storyService: storyService,
            existingEntry: entry,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify "Create a Story" button is visible
      final generateBtn = find.byKey(const Key('generate_story_button'));
      expect(generateBtn, findsOneWidget);
      expect(find.textContaining('Create a Story'), findsOneWidget);

      // Tap generate story
      await tester.tap(generateBtn);
      await tester.pump(); // Start generating, enters loading state

      // Verify loading state is shown
      expect(find.textContaining('Creating your story'), findsOneWidget);

      // Complete async generation
      await tester.pump(const Duration(milliseconds: 200));

      // Verify generated story is now displayed in the ✨ Your Story section
      expect(find.byKey(const Key('generated_story_text')), findsOneWidget);
      expect(
        find.text('The sunset over Majuli Island remains a comforting glow in my heart.'),
        findsOneWidget,
      );

      // Verify it was automatically saved in SQLite
      final updatedEntry = await database.getJournalEntryById(id);
      expect(
        updatedEntry!.generatedStory,
        equals('The sunset over Majuli Island remains a comforting glow in my heart.'),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Offline/network failure displays gentle feedback and does not delete or corrupt entry',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final id = await repository.create(
        title: 'Special Family Meal',
        body: 'Ate delicious khar and pitika together.',
      );
      final entry = await database.getJournalEntryById(id);

      // Simulate network failure
      fakeHttpClient.onPost = (path, data) => throw DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.connectionError,
          );

      await tester.pumpWidget(
        MaterialApp(
          home: JournalEntryScreen(
            repository: repository,
            storyService: storyService,
            existingEntry: entry,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final generateBtn = find.byKey(const Key('generate_story_button'));
      await tester.tap(generateBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify gentle reassurance appears
      expect(find.textContaining('Your memory is safely saved'), findsOneWidget);

      // Verify the SQLite entry is untouched and safe
      final savedEntry = await database.getJournalEntryById(id);
      expect(savedEntry, isNotNull);
      expect(savedEntry!.title, equals('Special Family Meal'));
      expect(savedEntry.body, equals('Ate delicious khar and pitika together.'));

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    // ==========================================
    // 4. UI Widget Tests (JournalScreen card display)
    // ==========================================
    testWidgets('JournalScreen renders generated story card section when story exists',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await repository.create(
        title: 'Grandchildren Visit',
        body: 'They played in the courtyard all afternoon.',
        generatedStory: 'The sound of laughter in the courtyard warmed my soul.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: JournalScreen(repository: repository),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify title, body, and story box
      expect(find.text('Grandchildren Visit'), findsOneWidget);
      expect(find.textContaining('Your Story'), findsOneWidget);
      expect(
        find.text('The sound of laughter in the courtyard warmed my soul.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
