import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../database/app_database.dart';
import '../database/repositories/outbox_repository.dart';
import 'http_client.dart';

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final String? error;

  const SyncResult({
    required this.success,
    this.pushed = 0,
    this.pulled = 0,
    this.error,
  });

  const SyncResult.ok({this.pushed = 0, this.pulled = 0})
      : success = true,
        error = null;

  const SyncResult.fail(String this.error)
      : success = false,
        pushed = 0,
        pulled = 0;
}

/// Service that synchronises local data with the backend.
///
/// Sync is fire-and-forget: failures are logged but never thrown,
/// ensuring the app UI is never blocked by sync errors.
class SyncService {
  static const int _maxRetries = 5;
  static const int _batchSize = 20;

  final AppDatabase _db;
  late final OutboxRepository _outbox;
  final Future<String?> Function() _getIdToken;
  final HttpClient _client;

  DateTime? _lastSyncTime;
  Timer? _periodicTimer;

  SyncService({
    required AppDatabase db,
    required Future<String?> Function() getIdToken,
    HttpClient? client,
  })  : _db = db,
        _getIdToken = getIdToken,
        _client = client ?? DioHttpClient(Dio()) {
    _outbox = OutboxRepository(_db);
  }

  /// Returns the last successful sync time, or null if never synced.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Returns the current pending outbox count.
  Future<int> get pendingCount => _outbox.getCount();

  /// Starts a periodic sync every [interval].
  void startPeriodicSync([Duration interval = const Duration(minutes: 15)]) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) => syncNow());
  }

  /// Stops the periodic sync timer.
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Full sync: push outbox, then pull remote changes.
  ///
  /// Catches all exceptions so it never propagates to the UI.
  Future<SyncResult> syncNow() async {
    try {
      final pushed = await pushOutbox();
      final pulled = await pullRemote();
      _lastSyncTime = DateTime.now();
      return SyncResult.ok(pushed: pushed, pulled: pulled);
    } catch (e) {
      debugPrint('[SyncService] syncNow failed: $e');
      return SyncResult.fail(e.toString());
    }
  }

  /// Reads pending outbox items (up to 20), POSTs to /sync/batch,
  /// marks accepted items as synced, increments retry count on failure.
  ///
  /// Stops pushing after 5 consecutive retries on any single item.
  Future<int> pushOutbox() async {
    final items = await _outbox.getPending(limit: _batchSize);
    if (items.isEmpty) return 0;

    final token = await _getIdToken();
    if (token == null) {
      debugPrint('[SyncService] pushOutbox: no auth token, skipping');
      return 0;
    }

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final operations = items.map((item) => {
          'entity_type': item.entityType,
          'entity_id': item.entityId,
          'operation': item.operation,
          'payload': item.payload,
          'client_timestamp': item.createdAt.toIso8601String(),
        }).toList();

    List<int> acceptedIds = [];
    try {
      final response = await _client.post(
        '$baseUrl/sync/batch',
        data: {'operations': operations},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Server returned ${response.statusCode}',
        );
      }

      final results = response.data['results'] as List? ?? [];
      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        if (result['status'] == 'accepted') {
          acceptedIds.add(items[i].id);
        } else if (result['status'] == 'conflict') {
          // On conflict, treat as accepted (server wins, drop local).
          acceptedIds.add(items[i].id);
        }
      }
    } on DioException catch (e) {
      debugPrint('[SyncService] pushOutbox network error: $e');
      // Increment retry for all items and stop if max retries reached.
      for (final item in items) {
        final newRetry = item.retryCount + 1;
        if (newRetry >= _maxRetries) {
          debugPrint(
            '[SyncService] item ${item.id} reached max retries, discarding',
          );
          acceptedIds.add(item.id); // Drop it to avoid infinite retry.
        } else {
          await _outbox.incrementRetry(item.id, e.message ?? 'network error');
        }
      }
      return 0;
    }

    if (acceptedIds.isNotEmpty) {
      await _outbox.markSynced(acceptedIds);
    }
    return acceptedIds.length;
  }

  /// Pulls journal entries, reminders, and cognitive scores from the backend,
  /// upserting into the local DB when remote updatedAt > local updatedAt.
  Future<int> pullRemote() async {
    final token = await _getIdToken();
    if (token == null) {
      debugPrint('[SyncService] pullRemote: no auth token, skipping');
      return 0;
    }

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    int totalPulled = 0;

    try {
      // Pull journal entries.
      totalPulled += await _pullCollection(
        '$baseUrl/sync/journal-entries',
        'journal_entries',
        token,
        _upsertJournalEntry,
      );

      // Pull reminders.
      totalPulled += await _pullCollection(
        '$baseUrl/sync/reminders',
        'reminders',
        token,
        _upsertReminder,
      );

      // Pull cognitive scores.
      totalPulled += await _pullCollection(
        '$baseUrl/sync/cognitive-scores',
        'cognitive_scores',
        token,
        _upsertCognitiveScore,
      );
    } on DioException catch (e) {
      debugPrint('[SyncService] pullRemote network error: $e');
    }

    return totalPulled;
  }

  Future<int> _pullCollection<T>(
    String url,
    String entityType,
    String token,
    Future<void> Function(Map<String, dynamic>) upsert,
  ) async {
    try {
      final response = await _client.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) return 0;

      final List<dynamic> items = response.data['items'] ?? [];
      int count = 0;
      for (final item in items) {
        await upsert(item as Map<String, dynamic>);
        count++;
      }
      return count;
    } on DioException catch (e) {
      debugPrint('[SyncService] _pullCollection($entityType) error: $e');
      return 0;
    }
  }

  Future<void> _upsertJournalEntry(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);

    // Check if local exists and is newer.
    final existing = await (_db.select(_db.journalEntries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null && !remoteUpdatedAt.isAfter(existing.updatedAt)) {
      return; // Local is newer or same, skip.
    }

    await _db.into(_db.journalEntries).insertOnConflictUpdate(
          JournalEntriesCompanion(
            id: drift.Value(id),
            title: drift.Value(data['title'] as String? ?? ''),
            body: drift.Value(data['body'] as String? ?? ''),
            mood: drift.Value(data['mood'] as String?),
            photoPath: drift.Value(data['photo_path'] as String?),
            createdAt: drift.Value(DateTime.parse(data['created_at'] as String)),
            updatedAt: drift.Value(remoteUpdatedAt),
            synced: const drift.Value(true),
            deleted: drift.Value(data['deleted'] as bool? ?? false),
          ),
        );
  }

  Future<void> _upsertReminder(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    // Reminders table does not have updatedAt — use createdAt for comparison.
    final remoteCreatedAt = DateTime.parse(data['created_at'] as String);

    final existing = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null && !remoteCreatedAt.isAfter(existing.createdAt)) {
      return;
    }

    await _db.into(_db.reminders).insertOnConflictUpdate(
          RemindersCompanion(
            id: drift.Value(id),
            title: drift.Value(data['title'] as String? ?? ''),
            timeOfDay: drift.Value(data['time_of_day'] as String? ?? ''),
            daysOfWeek: drift.Value(data['days_of_week'] as String? ?? ''),
            enabled: drift.Value(data['enabled'] as bool? ?? true),
            lastFiredAt: drift.Value(data['last_fired_at'] != null
                ? DateTime.parse(data['last_fired_at'] as String)
                : null),
            followUpCount: drift.Value(data['follow_up_count'] as int? ?? 0),
            createdAt: drift.Value(remoteCreatedAt),
            synced: const drift.Value(true),
          ),
        );
  }

  Future<void> _upsertCognitiveScore(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);

    final existing = await (_db.select(_db.cognitiveScores)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null && !remoteUpdatedAt.isAfter(existing.updatedAt)) {
      return;
    }

    await _db.into(_db.cognitiveScores).insertOnConflictUpdate(
          CognitiveScoresCompanion(
            id: drift.Value(id),
            domain: drift.Value(data['domain'] as String? ?? ''),
            score: drift.Value((data['score'] as num?)?.toDouble() ?? 0.0),
            trend: drift.Value((data['trend'] as num?)?.toDouble() ?? 0.0),
            updatedAt: drift.Value(remoteUpdatedAt),
            synced: const drift.Value(true),
          ),
        );
  }

  /// Disposes resources.
  void dispose() {
    stopPeriodicSync();
    _client.close();
  }
}
