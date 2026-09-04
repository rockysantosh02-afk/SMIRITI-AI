import 'dart:ffi';
import 'dart:io';

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
}
