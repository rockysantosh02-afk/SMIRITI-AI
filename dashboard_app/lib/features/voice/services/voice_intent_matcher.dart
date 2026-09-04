import '../models/voice_intent.dart';
import '../voice_prompts.dart';

/// Pure, local deterministic voice intent matcher for Smriti AI.
///
/// Converts recognized spoken text into actionable app navigation intents
/// using case-insensitive phrase matching across Assamese, Bengali, Hindi, and English.
///
/// This runs entirely on-device and does NOT require internet, Gemini, or backend APIs.
class VoiceIntentMatcher {
  const VoiceIntentMatcher();

  /// Clean input text: convert to lowercase, strip punctuation, normalize whitespace.
  static String normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'''[.,!?\u0964\u0965;:\-()[\]"'\\]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Match recognized speech [rawText] into a deterministic [VoiceIntentResult].
  ///
  /// [languageCode] is a 2-letter language code ('as', 'bn', 'hi', 'en') used to
  /// provide culturally tailored feedback messages.
  VoiceIntentResult match(String rawText, {String languageCode = 'en'}) {
    final clean = normalizeText(rawText);

    if (clean.isEmpty) {
      return VoiceIntentResult(
        intent: VoiceIntent.unknown,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.notUnderstood, languageCode),
      );
    }

    // 1. Create / Add New Memory Intent (Check before generic journal)
    if (_matchesAny(clean, _createMemoryKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.createMemory,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.creatingMemory, languageCode),
        targetRoute: '/journal', // Will open journal screen with new entry trigger
      );
    }

    // 2. Open Journal / View Memories Intent
    if (_matchesAny(clean, _openJournalKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openJournal,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.openingJournal, languageCode),
        targetRoute: '/journal',
      );
    }

    // 3. Open Games Intent
    if (_matchesAny(clean, _openGamesKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openGames,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.openingGames, languageCode),
        targetRoute: '/games',
      );
    }

    // 4. Return to Dashboard / Home Intent
    if (_matchesAny(clean, _dashboardKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openDashboard,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.openingDashboard, languageCode),
        targetRoute: '/dashboard',
      );
    }

    // 5. Reminders Notice (Phase 3.4 coming soon notice - no routing)
    if (_matchesAny(clean, _remindersKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openReminders,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.remindersNotice, languageCode),
        targetRoute: null,
      );
    }

    // Unknown Intent
    return VoiceIntentResult(
      intent: VoiceIntent.unknown,
      rawText: rawText,
      feedbackMessage: VoicePrompts.get(VoicePrompts.notUnderstood, languageCode),
    );
  }

  bool _matchesAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text == pattern || text.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  // --- Keyword Dictionaries (Multilingual) ---

  static const List<String> _createMemoryKeywords = [
    // English
    'create a memory',
    'create memory',
    'add a memory',
    'add memory',
    'new memory',
    'write a memory',
    'write memory',
    'new entry',
    'record a memory',
    'record memory',

    // Assamese
    'নতুন স্মৃতি',
    'স্মৃতি লিখক',
    'স্মৃতি যোগ কৰক',
    'স্মৃতি বনাওক',
    'নতুন কথা লিখিম',

    // Bengali
    'নতুন স্মৃতি',
    'স্মৃতি লেখো',
    'স্মৃতি যোগ করো',
    'স্মৃতি বানাও',
    'নতুন ডায়রি',

    // Hindi
    'नई याद',
    'याद लिखो',
    'याद जोड़ो',
    'नया संस्मरण',
    'याद बनाएं',
  ];

  static const List<String> _openJournalKeywords = [
    // English
    'open my journal',
    'open journal',
    'show my memories',
    'show memories',
    'view journal',
    'my journal',
    'my memories',
    'journal',
    'open diary',
    'my diary',
    'diary',
    'memories',

    // Assamese
    'মোৰ ডায়েরী',
    'ডায়েরী খোলক',
    'জার্নাল খোলক',
    'স্মৃতি চাওঁ',
    'মোৰ স্মৃতি',
    'জার্নাল',
    'ডায়েরী',
    'স্মৃতি',

    // Bengali
    'আমার ডায়েরি',
    'ডায়েরি খোলো',
    'জার্নাল খোলো',
    'স্মৃতি দেখাও',
    'আমার স্মৃতি',
    'ডায়েরি',
    'জার্নাল',

    // Hindi
    'मेरी डायरी',
    'डायरी खोलो',
    'जर्नल खोलो',
    'यादें दिखाओ',
    'मेरी यादें',
    'डायरी',
    'जर्नल',
    'यादें',
  ];

  static const List<String> _openGamesKeywords = [
    // English
    'play a game',
    'play game',
    'open games',
    'open game',
    'games hub',
    'games',
    'game',
    'play',

    // Assamese
    'খেল খোলক',
    'খেলিম',
    'খেলৰ পৃষ্ঠা',
    'খেল',
    'গেম',

    // Bengali
    'খেলা খোলো',
    'খেলব',
    'খেলার পাতা',
    'খেলা',
    'গেম',

    // Hindi
    'खेल खोलो',
    'खेलना है',
    'खेल का पेज',
    'खेल',
    'गेम्स',
    'गेम',
  ];

  static const List<String> _dashboardKeywords = [
    // English
    'go home',
    'open dashboard',
    'go to dashboard',
    'back to home',
    'dashboard',
    'home screen',
    'main screen',
    'home',

    // Assamese
    'ঘৰলৈ যাওক',
    'ঘৰলৈ',
    'মূল পৃষ্ঠা',
    'ডেশ্ববৰ্ড',

    // Bengali
    'বাড়ি যাও',
    'বাড়ি চলো',
    'মূল পাতা',
    'ড্যাশবোর্ড',

    // Hindi
    'घर जाओ',
    'होम पेज',
    'मुख्य पृष्ठ',
    'डैशबोर्ड',
    'होम',
  ];

  static const List<String> _remindersKeywords = [
    // English
    'show reminders',
    'open reminders',
    'my reminders',
    'reminders',
    'reminder',
    'medicine',
    'alarm',

    // Assamese
    'সোঁৱৰণী',
    'ৰিমাইণ্ডাৰ',
    'ঔষধ',

    // Bengali
    'অনুস্মারক',
    'রিমাইন্ডার',
    'ওষুধ',

    // Hindi
    'रिमाइंडर',
    'दवाई',
    'अलार्म',
  ];
}
