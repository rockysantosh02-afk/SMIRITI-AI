import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/sync/http_client.dart';

/// Result wrapper for AI story generation.
class StoryResult {
  final bool success;
  final String? story;
  final String? errorMessage;
  final bool isOffline;

  const StoryResult.ok(this.story)
      : success = true,
        errorMessage = null,
        isOffline = false;

  const StoryResult.fail(this.errorMessage, {this.isOffline = false})
      : success = false,
        story = null;
}

/// Service for generating warm, encouraging AI stories from journal entries.
///
/// Communicates with backend POST /journal/generate-story.
/// Never blocks saving local entries; provides calm, soothing offline & error fallbacks.
class JournalStoryService {
  final HttpClient _client;
  final String _baseUrl;
  final Future<String?> Function()? _getIdToken;
  final Connectivity? _connectivity;

  JournalStoryService({
    HttpClient? client,
    String? baseUrl,
    Future<String?> Function()? getIdToken,
    Connectivity? connectivity,
  })  : _client = client ?? DioHttpClient(Dio()),
        _baseUrl = baseUrl ??
            (dotenv.isInitialized
                ? (dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000')
                : 'http://localhost:8000'),
        _getIdToken = getIdToken,
        _connectivity = connectivity;

  /// Generates a warm, short story from memory title and content.
  Future<StoryResult> generateStory({
    required String title,
    required String content,
    String language = 'English',
  }) async {
    // 1. Optional explicit connectivity check (if provided)
    final connectivity = _connectivity;
    if (connectivity != null) {
      try {
        final connectivityResult = await connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          return const StoryResult.fail(
            'আপোনাৰ স্মৃতি সুৰক্ষিতভাৱে সাঁচি ৰখা হৈছে। ইণ্টাৰনেট সংযোগ হ\'লে আমি গল্প তৈয়াৰ কৰিব পাৰিম।\n(Your memory is safely saved. We can create a story when you are connected.)',
            isOffline: true,
          );
        }
      } catch (_) {
        // Proceed to network call
      }
    }

    // 2. Call backend
    try {
      final getIdToken = _getIdToken;
      final token = getIdToken != null ? await getIdToken() : null;
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await _client.post(
        '$_baseUrl/journal/generate-story',
        data: {
          'title': title,
          'content': content,
          'language': language,
        },
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final story = data is Map ? data['story'] as String? : null;
        if (story != null && story.trim().isNotEmpty) {
          return StoryResult.ok(story.trim());
        }
      }

      return const StoryResult.fail(
        'আমি এই মুহূৰ্তত কাহিনী সৃষ্টি কৰিব নোৱাৰিলোঁ। আপোনাৰ স্মৃতি সুৰক্ষিত হৈ আছে।\n(We could not create a story right now. Your memory is safely saved.)',
      );
    } on DioException catch (e) {
      debugPrint('[JournalStoryService] DioException: $e');
      final isConnectionIssue = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.error is SocketException;

      if (isConnectionIssue) {
        return const StoryResult.fail(
          'আপোনাৰ স্মৃতি সুৰক্ষিতভাৱে সাঁচি ৰখা হৈছে। ইণ্টাৰনেট সংযোগ হ\'লে আমি গল্প তৈয়াৰ কৰিব পাৰিম।\n(Your memory is safely saved. We can create a story when you are connected.)',
          isOffline: true,
        );
      }

      return const StoryResult.fail(
        'আমি এই মুহূৰ্তত কাহিনী সৃষ্টি কৰিব নোৱাৰিলোঁ। আপোনাৰ স্মৃতি সুৰক্ষিত হৈ আছে।\n(We could not create a story right now. Your memory is safely saved.)',
      );
    } catch (e) {
      debugPrint('[JournalStoryService] Unexpected error: $e');
      return const StoryResult.fail(
        'আমি এই মুহূৰ্তত কাহিনী সৃষ্টি কৰিব নোৱাৰিলোঁ। আপোনাৰ স্মৃতি সুৰক্ষিত হৈ আছে।\n(We could not create a story right now. Your memory is safely saved.)',
      );
    }
  }
}
