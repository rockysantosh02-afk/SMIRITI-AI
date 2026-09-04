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

    test('saveGeneratedStory preserves all original entry fields and leaves unrelated entries untouched', () async {
      final id1 = await repository.create(
        title: 'Original Title',
        body: 'Original Body',
        photoPath: '/photos/photo1.jpg',
      );
      final id2 = await repository.create(
        title: 'Other Entry',
        body: 'Should remain untouched',
      );
      await repository.markSynced(id2);
      expect((await database.getJournalEntryById(id2))!.synced, isTrue);

      final entry1Before = await database.getJournalEntryById(id1);

      // Save generated story on entry 1
      await repository.saveGeneratedStory(id: id1, story: 'New Generated Story');

      final entry1After = await database.getJournalEntryById(id1);
      expect(entry1After!.title, equals(entry1Before!.title));
      expect(entry1After.body, equals(entry1Before.body));
      expect(entry1After.photoPath, equals(entry1Before.photoPath));
      expect(entry1After.createdAt, equals(entry1Before.createdAt));
      expect(entry1After.generatedStory, equals('New Generated Story'));
      expect(entry1After.synced, isFalse);

      // Unrelated entry 2 must remain untouched and still synced
      final entry2After = await database.getJournalEntryById(id2);
      expect(entry2After!.title, equals('Other Entry'));
      expect(entry2After.synced, isTrue);
    });

    test('Drift schema migration from real version 1 database upgrades to version 2 and preserves existing data', () async {
      // 1. Create a raw SQLite in-memory database with schema version 1 (no generated_story column)
      final v1Executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('''
            CREATE TABLE journal_entries (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              mood TEXT,
              photo_path TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0,
              deleted INTEGER NOT NULL DEFAULT 0
            );
            CREATE TABLE outbox (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              operation TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              retry_count INTEGER NOT NULL DEFAULT 0
            );
            PRAGMA user_version = 1;
            INSERT INTO journal_entries (id, title, body, created_at, updated_at, synced)
            VALUES ('v1-entry', 'Pre-migration Memory', 'Preserved across schema upgrade', 1700000000000, 1700000000000, 1);
          ''');
        },
      );

      // 2. Open AppDatabase on that executor - Drift detects user_version == 1 and triggers onUpgrade
      final upgradedDb = AppDatabase.forTesting(v1Executor);

      // 3. Query the pre-existing entry through Drift
      final entry = await upgradedDb.getJournalEntryById('v1-entry');
      expect(entry, isNotNull);
      expect(entry!.title, equals('Pre-migration Memory'));
      expect(entry.body, equals('Preserved across schema upgrade'));
      expect(entry.generatedStory, isNull);

      // 4. Verify the database now reports schemaVersion 2
      expect(upgradedDb.schemaVersion, equals(2));

      // 5. Verify we can save generatedStory without error
      final v2Repo = JournalRepository(upgradedDb);
      await v2Repo.saveGeneratedStory(id: 'v1-entry', story: 'Survives migration and gets story.');

      final entryAfter = await upgradedDb.getJournalEntryById('v1-entry');
      expect(entryAfter!.generatedStory, equals('Survives migration and gets story.'));
      expect(entryAfter.title, equals('Pre-migration Memory'));
      expect(entryAfter.body, equals('Preserved across schema upgrade'));

      await upgradedDb.close();
    });

    // ==========================================
    // 2. JournalStoryService Tests
    // ==========================================
    test('JournalStoryService returns StoryResult.ok on 200 response with source metadata', () async {
      fakeHttpClient.onPost = (path, data) => Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'story': 'Walking in the fresh tea garden filled my heart with calm.',
              'source': 'ai',
            },
          );

      final result = await storyService.generateStory(
        title: 'Tea Garden',
        content: 'Fresh leaves everywhere.',
      );

      expect(result.success, isTrue);
      expect(result.story, equals('Walking in the fresh tea garden filled my heart with calm.'));
      expect(result.source, equals('ai'));
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

    test('JournalStoryService handles 401 unauthorized with gentle sign-in prompt', () async {
      fakeHttpClient.onPost = (path, data) => throw DioException(
            requestOptions: RequestOptions(path: path),
            response: Response(requestOptions: RequestOptions(path: path), statusCode: 401),
          );

      final result = await storyService.generateStory(title: 'Tea', content: 'Tea time');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Please sign in'));
    });

    test('JournalStoryService handles missing or empty story safely', () async {
      fakeHttpClient.onPost = (path, data) => Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {'story': '   '},
          );

      final result = await storyService.generateStory(title: 'Tea', content: 'Tea time');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('safely saved'));
    });

    test('JournalStoryService parses fallback source metadata correctly', () async {
      fakeHttpClient.onPost = (path, data) => Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {'story': 'Gentle reflection', 'source': 'fallback'},
          );

      final result = await storyService.generateStory(title: 'Tea', content: 'Tea time');
      expect(result.success, isTrue);
      expect(result.story, equals('Gentle reflection'));
      expect(result.source, equals('fallback'));
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

    testWidgets('Rapid duplicate taps trigger only one story generation request',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int requestCount = 0;
      final completer = Completer<Response>();

      fakeHttpClient.onPost = (path, data) {
        requestCount++;
        return completer.future;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: JournalEntryScreen(
            repository: repository,
            storyService: storyService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('journal_title_input')), 'Morning Walk');
      await tester.enterText(find.byKey(const Key('journal_body_input')), 'Cold morning mist');

      final genButton = find.byKey(const Key('generate_story_button'));
      expect(genButton, findsOneWidget);

      // Rapidly tap twice
      await tester.tap(genButton);
      await tester.pump();
      await tester.tap(genButton);
      await tester.pump();

      // Only one network call must be initiated
      expect(requestCount, equals(1));

      // Complete the inflight request
      completer.complete(Response(
        requestOptions: RequestOptions(path: '/journal/generate-story'),
        statusCode: 200,
        data: {'story': 'A lovely morning walk in the mist.', 'source': 'ai'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('A lovely morning walk in the mist.'), findsOneWidget);

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
