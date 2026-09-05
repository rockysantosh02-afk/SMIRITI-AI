import '../models/voice_intent.dart';
import '../voice_prompts.dart';
import 'reminder_voice_parser.dart';

/// Pure, local deterministic voice intent matcher for Smriti AI.
///
/// Converts recognized spoken text into actionable app navigation and reminder intents
/// using case-insensitive phrase matching across English, Telugu, and Hindi.
///
/// This runs entirely on-device and does NOT require internet, Gemini, or backend APIs.
class VoiceIntentMatcher {
  final ReminderVoiceParser _reminderParser;

  const VoiceIntentMatcher({ReminderVoiceParser? reminderParser})
      : _reminderParser = reminderParser ?? const ReminderVoiceParser();

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
  /// [languageCode] is a language code ('en', 'te', 'hi') used to
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

    // 1. Check for Cancellation Intent
    if (ReminderVoiceParser.isCancelCommand(clean)) {
      return VoiceIntentResult(
        intent: VoiceIntent.cancel,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.reminderCancelled, languageCode),
      );
    }

    // 2. Set / Create Reminder Intent (Check before generic reminders screen navigation)
    if (_matchesAny(clean, _setReminderKeywords)) {
      final parsed = _reminderParser.parse(rawText);
      return VoiceIntentResult(
        intent: VoiceIntent.setReminder,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.creatingReminder, languageCode),
        reminderTitle: parsed.title,
        reminderDateTime: parsed.scheduledDateTime,
        reminderTimeOfDay: parsed.timeOfDayStr,
      );
    }

    // 3. Create / Add New Memory Intent (Check before generic journal navigation)
    if (_matchesAny(clean, _createMemoryKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.createMemory,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.creatingMemory, languageCode),
        targetRoute: '/journal',
      );
    }

    // 4. Open Journal / View Memories Intent
    if (_matchesAny(clean, _openJournalKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openJournal,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.openingJournal, languageCode),
        targetRoute: '/journal',
      );
    }

    // 5. Open Games Intent
    if (_matchesAny(clean, _openGamesKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openGames,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.openingGames, languageCode),
        targetRoute: '/games',
      );
    }

    // 6. Return to Dashboard / Home Intent
    if (_matchesAny(clean, _dashboardKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openDashboard,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.openingDashboard, languageCode),
        targetRoute: '/dashboard',
      );
    }

    // 7. Open Reminders Screen Intent
    if (_matchesAny(clean, _openRemindersKeywords)) {
      return VoiceIntentResult(
        intent: VoiceIntent.openReminders,
        rawText: rawText,
        feedbackMessage: VoicePrompts.get(VoicePrompts.openingReminders, languageCode),
        targetRoute: '/reminders',
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

  static const List<String> _setReminderKeywords = [
    // English
    'set a reminder',
    'set reminder',
    'create a reminder',
    'create reminder',
    'remind me to',
    'remind me at',
    'remind me tomorrow',
    'remind me today',
    'remind me',
    'add a reminder',
    'add reminder',

    // Telugu
    'రిమైండర్ పెట్టు',
    'నాకు గుర్తు చేయి',
    'గుర్తు చేయి',
    'రిమైండర్ క్రియేట్ చేయి',
    'రిమైండర్ సెట్ చేయి',
    'గుర్తుచేయి',
    'రిమైండర్ ఉంచు',

    // Hindi
    'रिमाइंडर लगाओ',
    'मुझे याद दिलाओ',
    'याद दिलाना',
    'याद दिलाओ',
    'रिमाइंडर सेट करो',
    'रिमाइंडर जोड़ो',
    'अलार्म लगाओ',
  ];

  static const List<String> _openRemindersKeywords = [
    // English
    'open reminders',
    'show reminders',
    'view reminders',
    'my reminders',
    'reminders',
    'reminder screen',

    // Telugu
    'రిమైండర్లు తెరవండి',
    'రిమైండర్లు చూపించండి',
    'నా రిమైండర్లు',
    'రిమైండర్లు',
    'రిమైండర్ స్క్రీన్',

    // Hindi
    'रिमाइंडर खोलो',
    'रिमाइंडर दिखाओ',
    'मेरे रिमाइंडर',
    'रिमाइंडर',

    // Backwards compatibility
    'সোঁৱৰণী',
  ];

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

    // Telugu
    'కొత్త జ్ఞాపకం',
    'జ్ఞాపకం రాయండి',
    'కొత్త డైరీ',
    'జ్ఞాపకం జోడించండి',
    'కొత్త మెమరీ',
    'జ్ఞాపకం రాస్తాను',

    // Hindi
    'नई याद बनाओ',
    'नई याद',
    'याद लिखो',
    'याद जोड़ो',
    'याद जोड़ो',
    'नया संस्मरण',
    'याद बनाएं',

    // Backwards compatibility
    'নতুন স্মৃতি লিখক',
    'নতুন স্মৃতি যোগ করো',
    'নতুন স্মৃতি',
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

    // Telugu
    'నా డైరీ తెరవండి',
    'జర్నల్ తెరవండి',
    'డైరీ తెరవండి',
    'నా డైరీ',
    'నా జ్ఞాపకాలు',
    'జ్ఞాపకాలు చూపించండి',
    'జర్నల్',
    'డైరీ',
    'జ్ఞాపకాలు',

    // Hindi
    'मेरी डायरी खोलो',
    'डायरी खोलो',
    'जर्नल खोलो',
    'यादें दिखाओ',
    'मेरी यादें',
    'मेरी डायरी',
    'डायरी',
    'जर्नल',
    'यादें',

    // Backwards compatibility
    'মোৰ ডায়েরী খোলক',
    'আমার ডায়েরি খোলো',
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

    // Telugu
    'ఆటలు తెరవండి',
    'ఆట తెరవండి',
    'ఆట ఆడాలి',
    'ఆటలు',
    'ఆట',
    'గేమ్స్',
    'గేమ్',

    // Hindi
    'गेम खोलो',
    'खेल खोलो',
    'खेलना है',
    'खेल का पेज',
    'खेल',
    'गेम्स',
    'गेम',

    // Backwards compatibility
    'খেল খোলক',
    'খেলা খোলো',
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

    // Telugu
    'హోమ్ కి వెళ్లండి',
    'హోమ్ పేజీ',
    'డాష్‌బోర్డ్ తెరవండి',
    'డాష్‌బోర్డ్',
    'డాష్బోర్డ్',
    'హోమ్',

    // Hindi
    'घर जाओ',
    'होम खोलो',
    'डैशबोर्ड खोलो',
    'होम पेज',
    'मुख्य पृष्ठ',
    'डैशबोर्ड',
    'होम',

    // Backwards compatibility
    'ঘৰলৈ যাওক',
    'বাড়ি যাও',
  ];
}

