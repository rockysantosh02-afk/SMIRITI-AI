/// Result of parsing voice reminder instructions.
class ReminderParseResult {
  final String? title;
  final DateTime? scheduledDateTime;
  final String? timeOfDayStr; // "HH:mm"
  final bool isCancel;

  const ReminderParseResult({
    this.title,
    this.scheduledDateTime,
    this.timeOfDayStr,
    this.isCancel = false,
  });

  bool get hasTitle => title != null && title!.trim().isNotEmpty;
  bool get hasDateTime => scheduledDateTime != null && timeOfDayStr != null;
  bool get isComplete => hasTitle && hasDateTime;
}

/// Local NLP parser for extracting reminder title, date, and time from spoken text
/// across English, Telugu, and Hindi.
class ReminderVoiceParser {
  const ReminderVoiceParser();

  static const List<String> _affirmativeKeywords = [
    'yes',
    'yeah',
    'yep',
    'sure',
    'ok',
    'okay',
    'save',
    'save it',
    'confirm',
    'అవును',
    'సరే',
    'సేవ్ చేయి',
    'ఖరారు చేయి',
    'ఉంచండి',
    'हाँ',
    'हां',
    'ठीक है',
    'सही है',
    'सेव करो',
    'अवश्य',
  ];

  static const List<String> _negativeKeywords = [
    'no',
    'nope',
    'don\'t',
    'do not',
    'never',
    'stop',
    'cancel',
    'never mind',
    'వద్దు',
    'కాదు',
    'అవసరం లేదు',
    'రద్దు చేయి',
    'రద్దు',
    'ఆపు',
    'క్యాన్సిల్',
    'नहीं',
    'ना',
    'मत करो',
    'रद्द करो',
    'रद्द',
    'कैंसल',
    'रहने दो',
  ];

  /// Check if the user response is affirmative (Yes / Confirm / Save).
  static bool isAffirmative(String input) {
    final clean = input.toLowerCase().trim();
    for (final kw in _affirmativeKeywords) {
      if (clean == kw || clean.startsWith(kw) || clean.endsWith(kw)) {
        return true;
      }
    }
    return false;
  }

  /// Check if the user response is negative (No / Cancel / Stop).
  static bool isNegative(String input) {
    final clean = input.toLowerCase().trim();
    for (final kw in _negativeKeywords) {
      if (clean == kw || clean.startsWith(kw) || clean.endsWith(kw)) {
        return true;
      }
    }
    return false;
  }

  /// Check if the user spoken phrase is a cancellation command.
  static bool isCancelCommand(String input) => isNegative(input);

  /// Extract title from input text or fallback to trimmed input.
  static String? parseTitle(String input) {
    const parser = ReminderVoiceParser();
    final res = parser.parse(input);
    if (res.hasTitle) return res.title;
    final clean = input.trim();
    return clean.isNotEmpty ? clean : null;
  }

  /// Parse user input into [ReminderParseResult].
  ReminderParseResult parse(String input, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final clean = input.toLowerCase().trim();

    if (isCancelCommand(clean)) {
      return const ReminderParseResult(isCancel: true);
    }

    // 1. Parse Date & Time
    final dateTimeResult = parseDateTime(clean, now: now);

    // 2. Parse Title
    final title = _extractTitle(clean);

    return ReminderParseResult(
      title: title,
      scheduledDateTime: dateTimeResult?.$1,
      timeOfDayStr: dateTimeResult?.$2,
    );
  }

  /// Parse only date & time from follow-up speech (e.g., "Tomorrow at 8 PM", "రేపు ఉదయం 8 గంటలకు").
  (DateTime, String)? parseDateTime(String input, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final clean = input.toLowerCase().trim();

    if (clean.isEmpty) return null;

    // Determine Day offset (0 for today, 1 for tomorrow)
    int dayOffset = 0;
    bool explicitTomorrow = false;
    if (clean.contains('tomorrow') ||
        clean.contains('రేపు') ||
        clean.contains('कल')) {
      dayOffset = 1;
      explicitTomorrow = true;
    }

    // Determine Period indicator
    bool isPm = false;
    bool isAm = false;

    if (clean.contains('pm') ||
        clean.contains('p.m.') ||
        clean.contains('సాయంత్రం') ||
        clean.contains('రాత్రి') ||
        clean.contains('मధ్యాహ్నం') ||
        clean.contains('शाम') ||
        clean.contains('रात') ||
        clean.contains('दोपहर')) {
      isPm = true;
    } else if (clean.contains('am') ||
        clean.contains('a.m.') ||
        clean.contains('ఉదయం') ||
        clean.contains('सुबह')) {
      isAm = true;
    }

    // Attempt to extract numeric hour and optional minutes
    // Matches patterns like "8 pm", "8:30 pm", "8 గంటల", "8 बजे", "at 8"
    final timeRegex = RegExp(r'(\d{1,2})(?::(\d{2}))?');
    final match = timeRegex.firstMatch(clean);

    int hour = -1;
    int minute = 0;

    if (match != null) {
      hour = int.tryParse(match.group(1) ?? '') ?? -1;
      final minStr = match.group(2);
      if (minStr != null) {
        minute = int.tryParse(minStr) ?? 0;
      }

      if (hour >= 0 && hour <= 24) {
        if (isPm && hour < 12) {
          hour += 12;
        } else if (isAm && hour == 12) {
          hour = 0;
        }
      }
    } else {
      // General broad period defaults if no explicit hour given
      if (clean.contains('morning') ||
          clean.contains('ఉదయం') ||
          clean.contains('सुबह')) {
        hour = 9;
        minute = 0;
      } else if (clean.contains('afternoon') ||
          clean.contains('మధ్యాహ్నం') ||
          clean.contains('दोपहर')) {
        hour = 14;
        minute = 0;
      } else if (clean.contains('evening') ||
          clean.contains('సాయంత్రం') ||
          clean.contains('शाम')) {
        hour = 18;
        minute = 0;
      } else if (clean.contains('night') ||
          clean.contains('రాత్రి') ||
          clean.contains('रात')) {
        hour = 20;
        minute = 0;
      }
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    var targetDate = ref.add(Duration(days: dayOffset));
    var scheduled = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    // If scheduled time has already passed today and user didn't explicitly say "today",
    // roll forward to tomorrow for safety
    if (!explicitTomorrow && scheduled.isBefore(ref)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final timeOfDayStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return (scheduled, timeOfDayStr);
  }

  /// Strip command keywords and time expressions to extract pure reminder title.
  String? _extractTitle(String cleanInput) {
    var text = cleanInput;

    const triggerOnly = [
      'set a reminder',
      'set reminder',
      'create a reminder',
      'create reminder',
      'remind me',
      'రిమైండర్ పెట్టు',
      'రిమైండర్',
      'నాకు గుర్తు చేయి',
      'గుర్తు చేయి',
      'रिमाइंडर लगाओ',
      'मुझे याद दिलाओ',
      'याद दिलाना',
      'याद दिलाओ',
      'रिमाइंडर',
    ];
    if (triggerOnly.contains(text.trim())) {
      return null;
    }

    // Strip common trigger prefixes
    final prefixes = [
      'set a reminder to ',
      'set reminder to ',
      'set a reminder for ',
      'set reminder for ',
      'set a reminder ',
      'set reminder ',
      'create a reminder to ',
      'create reminder to ',
      'create a reminder ',
      'create reminder ',
      'remind me to ',
      'remind me for ',
      'remind me ',
      'రిమైండర్ పెట్టు ',
      'నాకు గుర్తు చేయి ',
      'గుర్తు చేయి ',
      'రిమైండర్ ',
      'रिमाइंडर लगाओ ',
      'मुझे याद दिलाओ ',
      'याद दिलाना ',
      'याद दिलाओ ',
      'रिमाइंडर ',
    ];

    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        break;
      }
    }

    if (triggerOnly.contains(text.trim())) {
      return null;
    }

    // Strip time/date suffixes and words
    final cleanWords = [
      'tomorrow at',
      'today at',
      'tomorrow',
      'today',
      'at',
      'రేపు',
      'ఈ రోజు',
      'గంటలకు',
      'గంటలకి',
      'ఉదయం',
      'సాయంత్రం',
      'మధ్యాహ్నం',
      'రాత్రి',
      'कल',
      'आज',
      'बजे',
      'सुबह',
      'शाम',
      'दोपहर',
      'रात',
    ];

    // Remove numbers with am/pm or time markers
    text = text.replaceAll(RegExp(r'\b\d{1,2}(?::\d{2})?\s*(am|pm|a\.m\.|p\.m\.)\b'), '');
    text = text.replaceAll(RegExp(r'\b\d{1,2}\s*(గంటలకు|గంటలకి|బజే|बजे)\b'), '');

    for (final w in cleanWords) {
      text = text.replaceAll(RegExp('\\b$w\\b'), '');
    }

    // Clean up punctuation and whitespace
    text = text
        .replaceAll(RegExp(r'''[.,!?\u0964\u0965;:\-()[\]"']'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty || text == 'medicine' || text == 'water') {
      // Capitalize first letter
      return text.isNotEmpty ? '${text[0].toUpperCase()}${text.substring(1)}' : null;
    }

    // Capitalize first letter of title
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
