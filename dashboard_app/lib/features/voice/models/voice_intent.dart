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

  /// Inquire about reminders (Phase 3.4 coming soon notice)
  openReminders,

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

  const VoiceIntentResult({
    required this.intent,
    required this.rawText,
    required this.feedbackMessage,
    this.targetRoute,
  });

  @override
  String toString() =>
      'VoiceIntentResult(intent: $intent, rawText: "$rawText", route: $targetRoute)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceIntentResult &&
          runtimeType == other.runtimeType &&
          intent == other.intent &&
          rawText == other.rawText &&
          feedbackMessage == other.feedbackMessage &&
          targetRoute == other.targetRoute;

  @override
  int get hashCode => Object.hash(intent, rawText, feedbackMessage, targetRoute);
}
