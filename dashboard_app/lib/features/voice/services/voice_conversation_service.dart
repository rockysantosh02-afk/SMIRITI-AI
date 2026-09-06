import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/sync/http_client.dart';

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

    // 2. Greeting / Well-being queries ("How are you?", "How are you doing today?")
    final isGreeting = lower.contains('how are you') ||
        lower.contains('how do you do') ||
        lower.contains('how are you doing') ||
        lower.contains('how you feeling') ||
        lower.contains('ఎలా ఉన్నారు') ||
        lower.contains('బాగున్నారా') ||
        lower.contains('आप कैसे हैं') ||
        lower.contains('कैसी हो') ||
        lower.contains('कैसा चल रहा है');

    if (isGreeting) {
      switch (lang) {
        case 'te':
          return 'నేను చాలా బాగున్నాను, ధన్యవాదాలు! ఈ రోజు మీరు ఎలా ఉన్నారు? మీతో మాట్లాడటం నాకు చాలా సంతోషంగా ఉంది.';
        case 'hi':
          return 'मैं बहुत अच्छा हूँ, धन्यवाद! आज आप कैसा महसूस कर रहे हैं? आपसे बात करके मुझे बहुत खुशी हुई।';
        case 'en':
        default:
          return 'I am doing wonderful, thank you for asking! How are you feeling today? It is always lovely talking with you.';
      }
    }

    // 3. User sharing personal activities ("I went to the market", "I visited my village", "I had tea in the garden")
    final isPersonalActivity = lower.contains('market') ||
        lower.contains('village') ||
        lower.contains('garden') ||
        lower.contains('walk') ||
        lower.contains('temple') ||
        lower.contains('friend') ||
        lower.contains('family') ||
        lower.contains('tea') ||
        lower.contains('lunch') ||
        lower.contains('వెళ్లాను') ||
        lower.contains('తోట') ||
        lower.contains('గుడి') ||
        lower.contains('గ్రామం') ||
        lower.contains('టీ') ||
        lower.contains('बाजार') ||
        lower.contains('गाँव') ||
        lower.contains('गांव') ||
        lower.contains('बगीचे') ||
        lower.contains('मंदिर') ||
        lower.contains('चाय');

    if (isPersonalActivity) {
      switch (lang) {
        case 'te':
          return 'అది చాలా మంచి విషయం! ఆ విశేషాల గురించి ఇంకాస్త చెబుతారా? మీ అనుభవాలు వినడం నాకు చాలా ఇష్టం.';
        case 'hi':
          return 'यह तो बहुत अच्छी बात है! क्या आप इसके बारे में थोड़ा और बताएंगे? आपकी बातें सुनना मुझे बहुत अच्छा लगता है।';
        case 'en':
        default:
          return 'That sounds wonderful! Would you like to tell me more about it? I always enjoy listening to your experiences.';
      }
    }

    // 4. Positive Emotion / Happiness ("I feel good", "I am happy today")
    final isPositiveEmotion = lower.contains('happy') ||
        lower.contains('glad') ||
        lower.contains('good') ||
        lower.contains('peaceful') ||
        lower.contains('సంతోషం') ||
        lower.contains('ఆనందం') ||
        lower.contains('खुश') ||
        lower.contains('प्रसन्न') ||
        lower.contains('अच्छा');

    if (isPositiveEmotion) {
      switch (lang) {
        case 'te':
          return 'మీరు సంతోషంగా ఉన్నారని తెలిసి నాకు ఎంతో ఆనందంగా ఉంది! మీ రోజు మరింత ఆహ్లాదకరంగా గడవాలని కోరుకుంటున్నాను.';
        case 'hi':
          return 'यह जानकर मुझे बहुत प्रसन्नता हुई कि आप खुश हैं! आपका दिन और भी आनंदमय बीते, यही मेरी कामना है।';
        case 'en':
        default:
          return 'Hearing that brings joy to my heart! I hope the rest of your day is just as peaceful and bright.';
      }
    }

    // 5. General / Trivia / Stories ("Tell me something interesting", "Tell me a story", "Talk to me")
    final isStoryRequest = lower.contains('tell me something') ||
        lower.contains('tell me a story') ||
        lower.contains('talk to me') ||
        lower.contains('ఏదైనా చెప్పు') ||
        lower.contains('కథ చెప్పు') ||
        lower.contains('మాట్లాడు') ||
        lower.contains('कुछ बताओ') ||
        lower.contains('कहानी सुनाओ') ||
        lower.contains('बात करो');

    if (isStoryRequest) {
      switch (lang) {
        case 'te':
          return 'మన మనసును ప్రశాంతంగా ఉంచుకోవడానికి రోజూ కొద్దిసేపు పచ్చని తోటలో నడవడం ఎంతో మేలు చేస్తుంది. మీకు మొక్కలు అంటే ఇష్టమా?';
        case 'hi':
          return 'प्रकृति के बीच थोड़ा समय बिताना और गहरी साँस लेना मन को असीम शांति देता है। क्या आपको प्रकृति में टहलना पसंद है?';
        case 'en':
        default:
          return 'Did you know that taking a gentle stroll in a garden and listening to the birds can instantly refresh the mind? What is your favorite place to relax?';
      }
    }

    // 6. Natural warm conversational fallback
    switch (lang) {
      case 'te':
        return 'నేను విన్నాను. మీరు చెప్పిన విషయం చాలా ఆసక్తికరంగా ఉంది. మీతో మాట్లాడటం ఎల్లప్పుడూ సంతోషాన్నిస్తుంది.';
      case 'hi':
        return 'मैंने आपकी बात सुनी। यह बहुत अच्छी बात है। आपसे बात करना हमेशा सुखद लगता है।';
      case 'en':
      default:
        return 'I hear you. Thank you for sharing that with me. It is always a pleasure conversing with you.';
    }
  }
}
