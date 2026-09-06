import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/sync/http_client.dart';
import 'conversational_intent_engine.dart';

/// Representation of a message turn in a conversational voice session.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Abstract contract for Voice Assistant conversational AI.
abstract class IVoiceConversationService {
  Future<String> generateResponse({
    required String userText,
    required List<ChatMessage> conversationHistory,
    required String languageCode,
  });
}

/// Production conversational AI service for Smriti AI Voice Assistant.
///
/// Communicates with backend AI when available; provides empathetic, elderly-calm
/// on-device conversational responses honoring session context in English, Telugu, and Hindi.
class VoiceConversationService implements IVoiceConversationService {
  final HttpClient _client;
  final String _baseUrl;

  VoiceConversationService({
    HttpClient? client,
    String? baseUrl,
  })  : _client = client ?? DioHttpClient(Dio()),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  @override
  Future<String> generateResponse({
    required String userText,
    required List<ChatMessage> conversationHistory,
    required String languageCode,
  }) async {
    final cleanInput = userText.trim();
    if (cleanInput.isEmpty) {
      return _getEmptyFallback(languageCode);
    }

    debugPrint('[AI] Processing user utterance: "$cleanInput" [lang: $languageCode]');

    // 1. Attempt to query backend AI endpoint if configured and accessible
    try {
      final response = await _client.post(
        '$_baseUrl/voice/chat',
        data: {
          'message': cleanInput,
          'language': languageCode,
          'history': conversationHistory.map((m) => m.toJson()).toList(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final reply = response.data['response'] as String?;
        if (reply != null && reply.trim().isNotEmpty) {
          debugPrint('[AI] Received backend response: "$reply"');
          return reply.trim();
        }
      }
    } catch (e) {
      debugPrint('[AI] Backend AI chat endpoint unavailable: $e. Using elderly-tailored contextual response.');
    }

    // 2. Elderly-tailored contextual conversational response engine
    return _generateContextualResponse(
      userText: cleanInput,
      history: conversationHistory,
      lang: languageCode,
    );
  }

  String _getEmptyFallback(String lang) {
    switch (lang) {
      case 'te':
        return 'నేను వినలేకపోయాను. దయచేసి మళ్ళీ చెప్పండి.';
      case 'hi':
        return 'मैं सुन नहीं पाया। कृपया दोबारा बोलें।';
      case 'en':
      default:
        return 'I could not hear you clearly. Please try speaking again.';
    }
  }

  /// Generates a warm, empathetic response taking into account the user's utterance and conversation history.
  String _generateContextualResponse({
    required String userText,
    required List<ChatMessage> history,
    required String lang,
  }) {
    final lower = userText.toLowerCase();

    // 1. Check for History Recall questions ("What did I tell you?", "What did I say earlier?")
    final isAskingHistory = lower.contains('what did i say') ||
        lower.contains('what did i tell') ||
        lower.contains('do you remember what i said') ||
        lower.contains('నేను ఏమి చెప్పాను') ||
        lower.contains('నేను ఏం చెప్పాను') ||
        lower.contains('मैंने क्या कहा') ||
        lower.contains('मैंने क्या बताया');

    if (isAskingHistory && history.isNotEmpty) {
      final lastUserMessages = history.where((m) => m.role == 'user').toList();
      if (lastUserMessages.isNotEmpty) {
        // Find previous user message before the current one
        final previous = lastUserMessages.length > 1
            ? lastUserMessages[lastUserMessages.length - 2].content
            : lastUserMessages.last.content;

        switch (lang) {
          case 'te':
            return 'మీరు ఇంతకుముందు: "$previous" అని చెప్పారు. నాకు గుర్తుంది.';
          case 'hi':
            return 'आपने पहले कहा था: "$previous"। मुझे याद है।';
          case 'en':
          default:
            return 'Earlier, you mentioned: "$previous". I remember.';
        }
      }
    }

    // 2. Delegate to context-aware elderly conversational engine
    const engine = ConversationalIntentEngine();
    final analysis = engine.detect(userText);
    return engine.generateResponse(
      analysis: analysis,
      userText: userText,
      languageCode: lang,
    );
  }
}
