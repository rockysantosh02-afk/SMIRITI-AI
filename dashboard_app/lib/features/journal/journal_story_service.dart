import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/sync/http_client.dart';

/// Result wrapper for AI story generation.
class StoryResult {
  final bool success;
  final String? story;
  final String? errorMessage;
  final bool isOffline;
  final String source;

  const StoryResult.ok(this.story, {this.source = 'ai'})
      : success = true,
        errorMessage = null,
        isOffline = false;

  const StoryResult.fail(this.errorMessage, {this.isOffline = false})
      : success = false,
        story = null,
        source = 'none';
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
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _getIdToken = getIdToken,
        _connectivity = connectivity;

  Future<String?> _resolveToken() async {
    if (_getIdToken != null) {
      return await _getIdToken!();
    }
    try {
      return await FirebaseService.instance.getIdToken();
    } catch (_) {
      return null;
    }
  }

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
            'Your memory is safely saved. We can create a story when you are connected.',
            isOffline: true,
          );
        }
      } catch (_) {
        // Proceed to network call
      }
    }

    // 2. Call backend
    try {
      final token = await _resolveToken();
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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
        final source = (data is Map && data['source'] is String)
            ? data['source'] as String
            : 'ai';
        if (story != null && story.trim().isNotEmpty) {
          return StoryResult.ok(story.trim(), source: source);
        }
      }

      return const StoryResult.fail(
        'We could not create a story right now. Your memory is safely saved.',
      );
    } on DioException catch (e) {
      debugPrint('[JournalStoryService] DioException: $e');
      if (e.response?.statusCode == 401) {
        return const StoryResult.fail(
          'Please sign in to create a story from your memory.',
        );
      }

      final isConnectionIssue = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.error is SocketException;

      if (isConnectionIssue) {
        return const StoryResult.fail(
          'Your memory is safely saved. We can create a story when you are connected.',
          isOffline: true,
        );
      }

      return const StoryResult.fail(
        'We could not create a story right now. Your memory is safely saved.',
      );
    } catch (e) {
      debugPrint('[JournalStoryService] Unexpected error: $e');
      return const StoryResult.fail(
        'We could not create a story right now. Your memory is safely saved.',
      );
    }
  }
}
