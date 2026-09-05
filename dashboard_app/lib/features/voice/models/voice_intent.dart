/// Supported deterministic voice intents for Smriti AI.
enum VoiceIntent {
  /// Navigate to personal memory journal
  openJournal,

  /// Open new journal memory creation screen
  createMemory,

  /// Navigate back to dashboard / home
  openDashboard,

  /// Navigate to games hub
  openGames,

  /// Navigate to reminders screen
  openReminders,

  /// Create or schedule a new reminder
  setReminder,

  /// Cancel current ongoing multi-turn conversation
  cancel,

  /// Spoken text was empty or not matched to any deterministic intent
  unknown,
}

/// The result of evaluating spoken text against local deterministic intents.
class VoiceIntentResult {
  /// The detected intent
  final VoiceIntent intent;

  /// The raw recognized speech text
  final String rawText;

  /// Elderly-calm feedback message to display to the user
  final String feedbackMessage;

  /// The destination route to navigate to (if any)
  final String? targetRoute;

  /// Parsed reminder title (if any)
  final String? reminderTitle;

  /// Parsed reminder date and time (if any)
  final DateTime? reminderDateTime;

  /// Time of day formatted as "HH:mm" (if any)
  final String? reminderTimeOfDay;

  const VoiceIntentResult({
    required this.intent,
    required this.rawText,
    required this.feedbackMessage,
    this.targetRoute,
    this.reminderTitle,
    this.reminderDateTime,
    this.reminderTimeOfDay,
  });

  @override
  String toString() =>
      'VoiceIntentResult(intent: $intent, rawText: "$rawText", route: $targetRoute, title: "$reminderTitle")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceIntentResult &&
          runtimeType == other.runtimeType &&
          intent == other.intent &&
          rawText == other.rawText &&
          feedbackMessage == other.feedbackMessage &&
          targetRoute == other.targetRoute &&
          reminderTitle == other.reminderTitle &&
          reminderDateTime == other.reminderDateTime &&
          reminderTimeOfDay == other.reminderTimeOfDay;

  @override
  int get hashCode => Object.hash(
        intent,
        rawText,
        feedbackMessage,
        targetRoute,
        reminderTitle,
        reminderDateTime,
        reminderTimeOfDay,
      );
}
