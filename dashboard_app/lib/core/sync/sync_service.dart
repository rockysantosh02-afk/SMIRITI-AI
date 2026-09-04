import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
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

  static const Map<String, String> _entityTypeToCollection = {
    'journal_entry': 'journal_entries',
    'journal_entries': 'journal_entries',
    'reminder': 'reminders',
    'reminders': 'reminders',
    'game_session': 'game_sessions',
    'game_sessions': 'game_sessions',
    'attempt': 'game_attempts',
    'game_attempt': 'game_attempts',
    'game_attempts': 'game_attempts',
    'cognitive_score': 'cognitive_scores',
    'cognitive_scores': 'cognitive_scores',
  };

  final AppDatabase _db;
  late final OutboxRepository _outbox;
  final Future<String?> Function() _getIdToken;
  final HttpClient _client;

  DateTime? _lastSyncTime;
  Timer? _periodicTimer;
  bool _isSyncing = false;

  /// Whether a synchronization operation is currently in progress.
  bool get isSyncing => _isSyncing;

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
    if (_isSyncing) {
      debugPrint('[SyncService] Sync already in progress, skipping concurrent call');
      return const SyncResult.ok(pushed: 0, pulled: 0);
    }
    _isSyncing = true;
    try {
      final pushed = await pushOutbox();
      final pulled = await pullRemote();
      _lastSyncTime = DateTime.now();
      return SyncResult.ok(pushed: pushed, pulled: pulled);
    } catch (e) {
      debugPrint('[SyncService] syncNow failed: $e');
      return SyncResult.fail(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Normalizes outbox payload to match backend schema expectations.
  Map<String, dynamic> _normalizePayload(
    String entityType,
    String operation,
    String rawPayload,
    DateTime createdAt,
  ) {
    Map<String, dynamic> data = {};
    try {
      if (rawPayload.isNotEmpty) {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map<String, dynamic>) {
          data = Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {
      data = {};
    }

    switch (entityType) {
      case 'journal_entry':
      case 'journal_entries':
        if (data.containsKey('photoPath') && !data.containsKey('photo_url')) {
          data['photo_url'] = data['photoPath'];
        }
        if (data.containsKey('photoPath') && !data.containsKey('photo_path')) {
          data['photo_path'] = data['photoPath'];
        }
        if (data.containsKey('generatedStory') && !data.containsKey('ai_story_text')) {
          data['ai_story_text'] = data['generatedStory'];
        }
        if (data.containsKey('generatedStory') && !data.containsKey('generated_story')) {
          data['generated_story'] = data['generatedStory'];
        }
        data.putIfAbsent('created_at', () => createdAt.toIso8601String());
        data.putIfAbsent('updated_at', () => createdAt.toIso8601String());
        break;

      case 'reminder':
      case 'reminders':
        if (data.containsKey('title') && !data.containsKey('label')) {
          data['label'] = data['title'];
        }
        if (data.containsKey('label') && !data.containsKey('title')) {
          data['title'] = data['label'];
        }
        if (data.containsKey('timeOfDay') && !data.containsKey('time_of_day')) {
          data['time_of_day'] = data['timeOfDay'];
        }
        if (data.containsKey('daysOfWeek') && !data.containsKey('days_of_week')) {
          data['days_of_week'] = data['daysOfWeek'];
        }
        if (data.containsKey('lastFiredAt') && !data.containsKey('last_fired_at')) {
          data['last_fired_at'] = data['lastFiredAt'];
        }
        if (data.containsKey('followUpCount') && !data.containsKey('follow_up_count')) {
          data['follow_up_count'] = data['followUpCount'];
        }
        data.putIfAbsent('type', () => 'daily');
        data.putIfAbsent('scheduled_time', () => createdAt.toIso8601String());
        data.putIfAbsent('created_at', () => createdAt.toIso8601String());
        break;

      case 'game_session':
      case 'game_sessions':
        if (data.containsKey('gameId') && !data.containsKey('game_id')) {
          data['game_id'] = data['gameId'];
        }
        if (data.containsKey('game_id') && !data.containsKey('game_code')) {
          data['game_code'] = data['game_id'];
        }
        if (data.containsKey('difficultyLevel') && !data.containsKey('difficulty_level')) {
          data['difficulty_level'] = data['difficultyLevel'];
        }
        if (data.containsKey('difficulty_level') && !data.containsKey('difficulty')) {
          data['difficulty'] = data['difficulty_level'];
        }
        if (data.containsKey('roundsPlayed') && !data.containsKey('rounds_played')) {
          data['rounds_played'] = data['roundsPlayed'];
        }
        if (data.containsKey('completedAt') && !data.containsKey('completed_at')) {
          data['completed_at'] = data['completedAt'];
        }
        data.putIfAbsent('created_at', () => createdAt.toIso8601String());
        break;

      case 'attempt':
      case 'game_attempt':
      case 'game_attempts':
        if (data.containsKey('sessionId') && !data.containsKey('session_id')) {
          data['session_id'] = data['sessionId'];
        }
        if (data.containsKey('gameId') && !data.containsKey('game_id')) {
          data['game_id'] = data['gameId'];
        }
        if (data.containsKey('roundNumber') && !data.containsKey('round_number')) {
          data['round_number'] = data['roundNumber'];
        }
        if (data.containsKey('responseTimeMs') && !data.containsKey('response_time_ms')) {
          data['response_time_ms'] = data['responseTimeMs'];
        }
        if (data.containsKey('difficultyLevel') && !data.containsKey('difficulty_level')) {
          data['difficulty_level'] = data['difficultyLevel'];
        }
        data.putIfAbsent('created_at', () => createdAt.toIso8601String());
        break;
    }

    if (operation == 'delete') {
      data['deleted'] = true;
    }

    return data;
  }

  /// Reads pending outbox items (up to 20), POSTs to /sync/batch,
  /// marks accepted items as synced, increments retry count on failure.
  Future<int> pushOutbox() async {
    final items = await _outbox.getPending(limit: _batchSize);
    if (items.isEmpty) return 0;

    final token = await _getIdToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('[SyncService] pushOutbox: no auth token, skipping');
      return 0;
    }

    final baseUrl = AppConfig.apiBaseUrl;
    final records = items.map((item) {
      final collection =
          _entityTypeToCollection[item.entityType] ?? item.entityType;
      final data = _normalizePayload(
        item.entityType,
        item.operation,
        item.payload,
        item.createdAt,
      );
      return {
        'collection': collection,
        'client_generated_id': item.entityId,
        'operation': item.operation,
        'data': data,
      };
    }).toList();

    List<int> acceptedIds = [];
    try {
      final response = await _client.post(
        '$baseUrl/sync/batch',
        data: {'records': records},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Server returned ${response.statusCode}',
        );
      }

      final successfulIds = (response.data['successful_record_ids'] as List?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};

      final results = response.data['results'] as List? ?? [];

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        bool isSuccess = successfulIds.contains(item.entityId);

        if (!isSuccess && i < results.length) {
          final res = results[i];
          final resId = res['client_generated_id'] ?? res['entity_id'];
          final status = res['status'];
          if (resId == item.entityId || resId == null) {
            if (status == 'success' ||
                status == 'duplicate' ||
                status == 'accepted' ||
                status == 'conflict') {
              isSuccess = true;
            }
          }
        }

        if (isSuccess) {
          acceptedIds.add(item.id);
        }
      }
    } on DioException catch (e) {
      debugPrint('[SyncService] pushOutbox network error: $e');
      for (final item in items) {
        final newRetry = item.retryCount + 1;
        if (newRetry >= _maxRetries) {
          debugPrint(
            '[SyncService] item ${item.id} reached max retries, discarding',
          );
          acceptedIds.add(item.id);
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

  /// Pulls journal entries, reminders, cognitive scores, and game sessions
  /// from the backend, upserting into the local DB when remote is newer.
  /// Never overwrites unsynced local records during pull.
  Future<int> pullRemote() async {
    final token = await _getIdToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('[SyncService] pullRemote: no auth token, skipping');
      return 0;
    }

    final baseUrl = AppConfig.apiBaseUrl;
    int totalPulled = 0;

    try {
      totalPulled += await _pullCollection(
        '$baseUrl/sync/journal-entries',
        'journal_entries',
        token,
        _upsertJournalEntry,
      );

      totalPulled += await _pullCollection(
        '$baseUrl/sync/reminders',
        'reminders',
        token,
        _upsertReminder,
      );

      totalPulled += await _pullCollection(
        '$baseUrl/sync/cognitive-scores',
        'cognitive_scores',
        token,
        _upsertCognitiveScore,
      );

      totalPulled += await _pullCollection(
        '$baseUrl/sync/game-sessions',
        'game_sessions',
        token,
        _upsertGameSession,
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
    final id = data['id'] as String? ?? data['client_generated_id'] as String?;
    if (id == null) return;
    final remoteUpdatedAt = DateTime.parse(data['updated_at'] as String);

    final existing = await (_db.select(_db.journalEntries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null) {
      final hasPendingOutbox = await (_db.select(_db.outbox)
            ..where((t) => t.entityId.equals(id)))
          .getSingleOrNull() != null;
      if (hasPendingOutbox) {
        // Local outbox record has priority until push completes.
        return;
      }
      if (!remoteUpdatedAt.isAfter(existing.updatedAt)) {
        return; // Local is newer or same, skip.
      }
    }

    final hasRemoteStory =
        data.containsKey('generated_story') || data.containsKey('generatedStory') || data.containsKey('ai_story_text');
    final remoteStory =
        (data['generated_story'] ?? data['generatedStory'] ?? data['ai_story_text']) as String?;

    await _db.into(_db.journalEntries).insertOnConflictUpdate(
          JournalEntriesCompanion(
            id: drift.Value(id),
            title: drift.Value(data['title'] as String? ?? ''),
            body: drift.Value(data['body'] as String? ?? ''),
            mood: drift.Value(data['mood'] as String?),
            photoPath: drift.Value((data['photo_path'] ?? data['photo_url']) as String?),
            generatedStory: drift.Value(
              hasRemoteStory ? remoteStory : existing?.generatedStory,
            ),
            createdAt: drift.Value(DateTime.parse(data['created_at'] as String)),
            updatedAt: drift.Value(remoteUpdatedAt),
            synced: const drift.Value(true),
            deleted: drift.Value(data['deleted'] as bool? ?? false),
          ),
        );
  }

  Future<void> _upsertReminder(Map<String, dynamic> data) async {
    final id = data['id'] as String? ?? data['client_generated_id'] as String?;
    if (id == null) return;
    final remoteCreatedAt = DateTime.parse(
        (data['created_at'] ?? data['scheduled_time'] ?? DateTime.now().toIso8601String()) as String);

    final existing = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null) {
      final hasPendingOutbox = await (_db.select(_db.outbox)
            ..where((t) => t.entityId.equals(id)))
          .getSingleOrNull() != null;
      if (hasPendingOutbox) {
        // Local outbox record has priority until push completes.
        return;
      }
      if (!remoteCreatedAt.isAfter(existing.createdAt)) {
        return;
      }
    }

    await _db.into(_db.reminders).insertOnConflictUpdate(
          RemindersCompanion(
            id: drift.Value(id),
            title: drift.Value(data['title'] as String? ?? data['label'] as String? ?? ''),
            timeOfDay: drift.Value(data['time_of_day'] as String? ?? data['timeOfDay'] as String? ?? ''),
            daysOfWeek: drift.Value(data['days_of_week'] as String? ?? data['daysOfWeek'] as String? ?? ''),
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
    final id = data['id'] as String? ?? data['score_id'] as String? ?? data['client_generated_id'] as String?;
    if (id == null) return;
    final remoteUpdatedAt = DateTime.parse(
        (data['updated_at'] ?? data['created_at'] ?? DateTime.now().toIso8601String()) as String);

    final existing = await (_db.select(_db.cognitiveScores)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null) {
      final hasPendingOutbox = await (_db.select(_db.outbox)
            ..where((t) => t.entityId.equals(id)))
          .getSingleOrNull() != null;
      if (hasPendingOutbox) {
        return;
      }
      if (!remoteUpdatedAt.isAfter(existing.updatedAt)) {
        return;
      }
    }

    await _db.into(_db.cognitiveScores).insertOnConflictUpdate(
          CognitiveScoresCompanion(
            id: drift.Value(id),
            domain: drift.Value(data['domain'] as String? ?? ''),
            score: drift.Value((data['score'] as num?)?.toDouble() ?? (data['composite_score'] as num?)?.toDouble() ?? 0.0),
            trend: drift.Value((data['trend'] as num?)?.toDouble() ?? 0.0),
            updatedAt: drift.Value(remoteUpdatedAt),
            synced: const drift.Value(true),
          ),
        );
  }

  Future<void> _upsertGameSession(Map<String, dynamic> data) async {
    final id = data['id'] as String? ?? data['session_id'] as String? ?? data['client_generated_id'] as String?;
    if (id == null) return;
    final remoteStartedAt = DateTime.parse(
        (data['started_at'] ?? data['created_at'] ?? DateTime.now().toIso8601String()) as String);

    final existing = await (_db.select(_db.gameSessions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (existing != null) {
      final hasPendingOutbox = await (_db.select(_db.outbox)
            ..where((t) => t.entityId.equals(id)))
          .getSingleOrNull() != null;
      if (hasPendingOutbox) {
        return;
      }
      if (!remoteStartedAt.isAfter(existing.startedAt)) {
        return;
      }
    }

    await _db.into(_db.gameSessions).insertOnConflictUpdate(
          GameSessionsCompanion(
            id: drift.Value(id),
            gameId: drift.Value(data['game_id'] as String? ?? data['game_code'] as String? ?? ''),
            startedAt: drift.Value(remoteStartedAt),
            completedAt: drift.Value(data['completed_at'] != null
                ? DateTime.parse(data['completed_at'] as String)
                : null),
            difficultyLevel: drift.Value(
                (data['difficulty_level'] as num?)?.toInt() ?? (data['difficulty'] as num?)?.toInt() ?? 1),
            roundsPlayed: drift.Value((data['rounds_played'] as num?)?.toInt() ?? 0),
            accuracy: drift.Value((data['accuracy'] as num?)?.toDouble() ?? 0.0),
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
