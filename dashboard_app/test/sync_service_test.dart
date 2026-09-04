import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:dashboard_app/core/database/app_database.dart';
import 'package:dashboard_app/core/database/repositories/outbox_repository.dart';
import 'package:dashboard_app/core/sync/http_client.dart';
import 'package:dashboard_app/core/sync/sync_service.dart';

/// In-memory fake HttpClient that records requests and returns controlled responses.
class FakeHttpClient implements HttpClient {
  final List<RecordedRequest> requests = [];

  Response? Function(String uri)? responseBuilderForGet;
  Response? Function(String uri, Object? data)? responseBuilderForPost;

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
    requests.add(RecordedRequest('POST', path, data, options));
    final resp = responseBuilderForPost?.call(path, data);
    if (resp != null) return resp as Response<T>;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: <String, dynamic>{},
    ) as Response<T>;
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
    requests.add(RecordedRequest('GET', path, data, options));
    final resp = responseBuilderForGet?.call(path);
    if (resp != null) return resp as Response<T>;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: <String, dynamic>{},
    ) as Response<T>;
  }

  @override
  void close() {}
}

class RecordedRequest {
  final String method;
  final String uri;
  final Object? data;
  final Options? options;

  RecordedRequest(this.method, this.uri, this.data, this.options);
}

/// Fake FirebaseService that always returns a fixed token.
class FakeFirebaseService {
  Future<String?> getIdToken() async => 'fake-token';
  dynamic get currentUser => null;
  String? get uid => 'fake-uid';
  String? get email => 'fake@test.com';
  String? get displayName => 'Fake User';
}

/// Helper to open the sqlite3 DLL on Windows for tests.
void _initSqliteDll() {
  if (!Platform.isWindows) return;
  final dir = Directory.systemTemp;
  final sqliteDir = Directory('${dir.path}/sqlite');
  if (!sqliteDir.existsSync()) sqliteDir.createSync(recursive: true);
  final dllPath = '${sqliteDir.path}/sqlite3.dll';
  if (!File(dllPath).existsSync()) return;
  DynamicLibrary.open(dllPath);
}

void main() {
  late AppDatabase db;
  late OutboxRepository outboxRepo;
  late SyncService syncService;
  late FakeHttpClient fakeHttpClient;

  setUpAll(() {
    _initSqliteDll();
    dotenv.testLoad();
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outboxRepo = OutboxRepository(db);

    // Enqueue 3 test outbox items.
    await outboxRepo.enqueue(
      entityType: 'journal_entry',
      entityId: 'je-1',
      operation: 'create',
      payload: '{}',
    );
    await outboxRepo.enqueue(
      entityType: 'journal_entry',
      entityId: 'je-2',
      operation: 'update',
      payload: '{}',
    );
    await outboxRepo.enqueue(
      entityType: 'journal_entry',
      entityId: 'je-3',
      operation: 'delete',
      payload: '{}',
    );

    fakeHttpClient = FakeHttpClient();

    final fakeFirebase = FakeFirebaseService();
    // ignore: avoid_print
    syncService = SyncService(
      db: db,
      getIdToken: fakeFirebase.getIdToken,
      client: fakeHttpClient,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('pushOutbox', () {
    test('marks all three items as synced when server accepts all', () async {
      fakeHttpClient.responseBuilderForPost = (_, __) => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'results': [
                {'entity_id': 'je-1', 'status': 'accepted'},
                {'entity_id': 'je-2', 'status': 'accepted'},
                {'entity_id': 'je-3', 'status': 'accepted'},
              ],
            },
          );

      final pushed = await syncService.pushOutbox();

      expect(pushed, 3);
      expect(await outboxRepo.getCount(), 0);
    });

    test('marks only accepted items as synced when one is rejected', () async {
      fakeHttpClient.responseBuilderForPost = (_, __) => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'results': [
                {'entity_id': 'je-1', 'status': 'accepted'},
                {'entity_id': 'je-2', 'status': 'rejected', 'error': 'not found'},
                {'entity_id': 'je-3', 'status': 'accepted'},
              ],
            },
          );

      final pushed = await syncService.pushOutbox();

      expect(pushed, 2);
      expect(await outboxRepo.getCount(), 1);
    });

    test('increments retry count on server error response', () async {
      fakeHttpClient.responseBuilderForPost = (_, __) => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {},
          );

      final pushed = await syncService.pushOutbox();

      expect(pushed, 0);
      final pending = await outboxRepo.getPending(limit: 10);
      expect(pending.length, 3);
      for (final item in pending) {
        expect(item.retryCount, 1);
      }
    });
  });

  group('syncNow', () {
    test('returns success when push succeeds', () async {
      fakeHttpClient.responseBuilderForPost = (_, __) => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'results': [
                {'entity_id': 'je-1', 'status': 'accepted'},
              ],
            },
          );
      // GET for pull collections returns empty
      fakeHttpClient.responseBuilderForGet = (_) => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {'items': []},
          );

      final result = await syncService.syncNow();

      expect(result.success, true);
      expect(result.pushed, 1);
      expect(result.pulled, 0);
    });

    test('returns failure when an exception is thrown', () async {
      fakeHttpClient.responseBuilderForPost = (_, __) => throw Exception('simulated error');

      final result = await syncService.syncNow();

      expect(result.success, false);
      expect(result.error, contains('simulated error'));
    });
  });

  group('Token safety (Fix 3)', () {
    test('skips pushOutbox when token is null', () async {
      final service = SyncService(
        db: db,
        getIdToken: () async => null,
        client: fakeHttpClient,
      );
      final pushed = await service.pushOutbox();
      expect(pushed, 0);
      expect(fakeHttpClient.requests, isEmpty);
    });

    test('skips pushOutbox when token is empty string', () async {
      final service = SyncService(
        db: db,
        getIdToken: () async => '',
        client: fakeHttpClient,
      );
      final pushed = await service.pushOutbox();
      expect(pushed, 0);
      expect(fakeHttpClient.requests, isEmpty);
    });

    test('skips pushOutbox when token is whitespace-only', () async {
      final service = SyncService(
        db: db,
        getIdToken: () async => '   ',
        client: fakeHttpClient,
      );
      final pushed = await service.pushOutbox();
      expect(pushed, 0);
      expect(fakeHttpClient.requests, isEmpty);
    });

    test('attaches Authorization header when token is valid', () async {
      final service = SyncService(
        db: db,
        getIdToken: () async => 'valid-firebase-token',
        client: fakeHttpClient,
      );
      await service.pushOutbox();
      expect(fakeHttpClient.requests.isNotEmpty, true);
      final req = fakeHttpClient.requests.first;
      expect(req.options?.headers?['Authorization'], 'Bearer valid-firebase-token');
    });

    test('skips pullRemote when token is null, empty or whitespace', () async {
      for (final badToken in [null, '', '   ']) {
        fakeHttpClient.requests.clear();
        final service = SyncService(
          db: db,
          getIdToken: () async => badToken,
          client: fakeHttpClient,
        );
        final pulled = await service.pullRemote();
        expect(pulled, 0);
        expect(fakeHttpClient.requests, isEmpty);
      }
    });
  });

  group('Sync re-entrancy guard (Fix 2)', () {
    test('prevents concurrent syncNow executions and resets isSyncing', () async {
      final postCalled = Completer<void>();
      final responseCompleter = Completer<Response>();

      final blockService = SyncService(
        db: db,
        getIdToken: () async => 'test-token',
        client: CustomBlockingClient(
          onPost: () {
            if (!postCalled.isCompleted) postCalled.complete();
            return responseCompleter.future;
          },
        ),
      );

      final future1 = blockService.syncNow();
      await postCalled.future;

      expect(blockService.isSyncing, true);

      // Attempt concurrent syncNow while first is in flight
      final result2 = await blockService.syncNow();
      expect(result2.success, true);
      expect(result2.pushed, 0);
      expect(result2.pulled, 0);

      // Complete the first sync
      responseCompleter.complete(Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {
          'results': [
            {'entity_id': 'je-1', 'status': 'accepted'},
          ],
        },
      ));

      final result1 = await future1;
      expect(result1.success, true);
      expect(blockService.isSyncing, false);
    });

    test('isSyncing resets to false even if syncNow throws', () async {
      final errorService = SyncService(
        db: db,
        getIdToken: () async => throw Exception('fatal token error'),
        client: fakeHttpClient,
      );

      final result = await errorService.syncNow();
      expect(result.success, false);
      expect(errorService.isSyncing, false);
    });
  });

  group('Journal generatedStory pull sync safety (Fix 1)', () {
    test('remote generated_story updates local generatedStory', () async {
      final oldTime = DateTime.parse('2026-01-01T10:00:00.000Z');
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion(
              id: const drift.Value('sync-story-1'),
              title: const drift.Value('Local Memory'),
              body: const drift.Value('Local Body'),
              createdAt: drift.Value(oldTime),
              updatedAt: drift.Value(oldTime),
            ),
          );

      final newerTime = DateTime.parse('2026-01-02T10:00:00.000Z');
      fakeHttpClient.responseBuilderForGet = (path) {
        if (path.contains('journal-entries')) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'sync-story-1',
                  'title': 'Remote Title',
                  'body': 'Remote Body',
                  'generated_story': 'A beautiful remote generated story.',
                  'created_at': oldTime.toIso8601String(),
                  'updated_at': newerTime.toIso8601String(),
                  'deleted': false,
                }
              ],
            },
          );
        }
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {'items': []},
        );
      };

      final pulled = await syncService.pullRemote();
      expect(pulled, 1);

      final updated = await (db.select(db.journalEntries)
            ..where((t) => t.id.equals('sync-story-1')))
          .getSingle();

      expect(updated.generatedStory, 'A beautiful remote generated story.');
      expect(updated.title, 'Remote Title');
    });

    test('remote generatedStory (camelCase) updates local generatedStory', () async {
      final oldTime = DateTime.parse('2026-01-01T10:00:00.000Z');
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion(
              id: const drift.Value('sync-story-camel'),
              title: const drift.Value('Local Memory'),
              body: const drift.Value('Local Body'),
              createdAt: drift.Value(oldTime),
              updatedAt: drift.Value(oldTime),
            ),
          );

      final newerTime = DateTime.parse('2026-01-02T10:00:00.000Z');
      fakeHttpClient.responseBuilderForGet = (path) {
        if (path.contains('journal-entries')) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'sync-story-camel',
                  'title': 'Camel Title',
                  'body': 'Camel Body',
                  'generatedStory': 'CamelCase story update.',
                  'created_at': oldTime.toIso8601String(),
                  'updated_at': newerTime.toIso8601String(),
                  'deleted': false,
                }
              ],
            },
          );
        }
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {'items': []},
        );
      };

      await syncService.pullRemote();

      final updated = await (db.select(db.journalEntries)
            ..where((t) => t.id.equals('sync-story-camel')))
          .getSingle();

      expect(updated.generatedStory, 'CamelCase story update.');
    });

    test('missing generated_story field preserves existing local generatedStory', () async {
      final oldTime = DateTime.parse('2026-01-01T10:00:00.000Z');
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion(
              id: const drift.Value('sync-story-preserve'),
              title: const drift.Value('Local Memory'),
              body: const drift.Value('Local Body'),
              generatedStory: const drift.Value('Local existing story that must be preserved'),
              createdAt: drift.Value(oldTime),
              updatedAt: drift.Value(oldTime),
            ),
          );

      final newerTime = DateTime.parse('2026-01-02T10:00:00.000Z');
      fakeHttpClient.responseBuilderForGet = (path) {
        if (path.contains('journal-entries')) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'sync-story-preserve',
                  'title': 'Updated Title',
                  'body': 'Updated Body',
                  'created_at': oldTime.toIso8601String(),
                  'updated_at': newerTime.toIso8601String(),
                  'deleted': false,
                }
              ],
            },
          );
        }
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {'items': []},
        );
      };

      await syncService.pullRemote();

      final updated = await (db.select(db.journalEntries)
            ..where((t) => t.id.equals('sync-story-preserve')))
          .getSingle();

      expect(updated.title, 'Updated Title');
      expect(updated.generatedStory, 'Local existing story that must be preserved');
    });

    test('explicit null generated_story in remote payload updates local generatedStory to null', () async {
      final oldTime = DateTime.parse('2026-01-01T10:00:00.000Z');
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion(
              id: const drift.Value('sync-story-nullify'),
              title: const drift.Value('Local Memory'),
              body: const drift.Value('Local Body'),
              generatedStory: const drift.Value('Local story to be cleared'),
              createdAt: drift.Value(oldTime),
              updatedAt: drift.Value(oldTime),
            ),
          );

      final newerTime = DateTime.parse('2026-01-02T10:00:00.000Z');
      fakeHttpClient.responseBuilderForGet = (path) {
        if (path.contains('journal-entries')) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'sync-story-nullify',
                  'title': 'Updated Title',
                  'body': 'Updated Body',
                  'generated_story': null,
                  'created_at': oldTime.toIso8601String(),
                  'updated_at': newerTime.toIso8601String(),
                  'deleted': false,
                }
              ],
            },
          );
        }
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {'items': []},
        );
      };

      await syncService.pullRemote();

      final updated = await (db.select(db.journalEntries)
            ..where((t) => t.id.equals('sync-story-nullify')))
          .getSingle();

      expect(updated.title, 'Updated Title');
      expect(updated.generatedStory, isNull);
    });

    test('older remote updatedAt does not overwrite newer local generatedStory', () async {
      final newerLocalTime = DateTime.parse('2026-01-05T10:00:00.000Z');
      await db.into(db.journalEntries).insert(
            JournalEntriesCompanion(
              id: const drift.Value('sync-story-conflict'),
              title: const drift.Value('Newer Local Title'),
              body: const drift.Value('Newer Local Body'),
              generatedStory: const drift.Value('Newer local story'),
              createdAt: drift.Value(newerLocalTime),
              updatedAt: drift.Value(newerLocalTime),
            ),
          );

      final olderRemoteTime = DateTime.parse('2026-01-02T10:00:00.000Z');
      fakeHttpClient.responseBuilderForGet = (path) {
        if (path.contains('journal-entries')) {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'sync-story-conflict',
                  'title': 'Older Remote Title',
                  'body': 'Older Remote Body',
                  'generated_story': 'Older remote story',
                  'created_at': olderRemoteTime.toIso8601String(),
                  'updated_at': olderRemoteTime.toIso8601String(),
                  'deleted': false,
                }
              ],
            },
          );
        }
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: {'items': []},
        );
      };

      await syncService.pullRemote();

      final entry = await (db.select(db.journalEntries)
            ..where((t) => t.id.equals('sync-story-conflict')))
          .getSingle();

      expect(entry.title, 'Newer Local Title');
      expect(entry.generatedStory, 'Newer local story');
    });
  });
}

class CustomBlockingClient implements HttpClient {
  final Future<Response> Function() onPost;

  CustomBlockingClient({required this.onPost});

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
    final resp = await onPost();
    return resp as Response<T>;
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
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: <String, dynamic>{'items': []},
    ) as Response<T>;
  }

  @override
  void close() {}
}
