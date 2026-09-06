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
    final title = _extractTitle(clean, hasDateTime: dateTimeResult != null);

    return ReminderParseResult(
      title: title,
      scheduledDateTime: dateTimeResult?.$1,
      timeOfDayStr: dateTimeResult?.$2,
    );
  }

  static const Map<String, int> _numberWords = {
    // English
    'a': 1,
    'an': 1,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'twenty-five': 25,
    'twenty five': 25,
    'thirty': 30,
    'forty': 40,
    'forty-five': 45,
    'forty five': 45,
    'fifty': 50,
    'sixty': 60,
    // Hindi
    'एक': 1,
    'दो': 2,
    'तीन': 3,
    'चार': 4,
    'पाँच': 5,
    'पांच': 5,
    'छह': 6,
    'सात': 7,
    'आठ': 8,
    'नौ': 9,
    'दस': 10,
    'पंद्रह': 15,
    'बीस': 20,
    'पच्चीस': 25,
    'तीस': 30,
    'पैंतालीस': 45,
    'साठ': 60,
    // Telugu
    'ఒక': 1,
    'ఒకటి': 1,
    'రెండు': 2,
    'మూడు': 3,
    'నాలుగు': 4,
    'ఐదు': 5,
    'ఆరు': 6,
    'ఏడు': 7,
    'ఎనిమిది': 8,
    'తొమ్మిది': 9,
    'పది': 10,
    'పదిహేను': 15,
    'ఇరవై': 20,
    'ముప్పై': 30,
    'నలభై': 40,
    'అరవై': 60,
  };

  /// Parse only date & time from follow-up or direct speech.
  /// Supports both relative offsets ("in 5 minutes", "after 1 hour") and absolute times ("tomorrow at 8 PM").
  (DateTime, String)? parseDateTime(String input, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final clean = input.toLowerCase().trim();

    if (clean.isEmpty) return null;

    // 1. Try relative time parsing first
    final relativeResult = _parseRelativeDateTime(clean, ref);
    if (relativeResult != null) {
      return relativeResult;
    }

    // If input was clearly a relative duration phrase (e.g. "0 minutes", "0 hours") that is non-positive,
    // do not fall through and interpret the number as an absolute hour
    final isExplicitRelativeOnly = RegExp(
      r'^\s*(?:in|after|next|for next|for)?\s*\d+\s*(?:minutes?|mins?|hours?|hrs?|నిమిష|మినిట్స్?|मिनट)\s*$',
    ).hasMatch(clean);
    if (isExplicitRelativeOnly) {
      return null;
    }

    // 2. Absolute time parsing
    // Determine Day offset (0 for today, 1 for tomorrow)
    int dayOffset = 0;
    bool explicitTomorrow = false;
    bool explicitToday = false;
    if (clean.contains('tomorrow') ||
        clean.contains('రేపు') ||
        clean.contains('कल')) {
      dayOffset = 1;
      explicitTomorrow = true;
    } else if (clean.contains('today') ||
        clean.contains('ఈ రోజు') ||
        clean.contains('आज')) {
      explicitToday = true;
    }

    // Determine Period indicator
    bool isPm = false;
    bool isAm = false;

    if (clean.contains('pm') ||
        clean.contains('p.m.') ||
        clean.contains('సాయంత్రం') ||
        clean.contains('రాత్రి') ||
        clean.contains('మధ్యాహ్నం') ||
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
    final timeRegex = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\b');
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
    if (!explicitTomorrow && !explicitToday && scheduled.isBefore(ref)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    if (scheduled.isBefore(ref) || scheduled.isAtSameMomentAs(ref)) {
      return null;
    }

    final timeOfDayStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return (scheduled, timeOfDayStr);
  }

  /// Parses relative time expressions ("in 5 minutes", "after 1 hour", "5 నిమిషాల్లో", "5 मिनट में").
  (DateTime, String)? _parseRelativeDateTime(String clean, DateTime ref) {
    int? minutesToAdd;

    // Special natural half hour / one hour phrases
    if (clean.contains('half an hour') ||
        clean.contains('half hour') ||
        clean.contains('ఆధే ఘంటే') ||
        clean.contains('आधे घंटे') ||
        clean.contains('అరగంట')) {
      minutesToAdd = 30;
    } else if (clean.contains('an hour') ||
        clean.contains('one hour') ||
        clean.contains('ఒక గంట') ||
        clean.contains('एक घंटा') ||
        clean.contains('एक घंटे')) {
      minutesToAdd = 60;
    }

    // English patterns: (in|after|next|for next|for) X (minutes|mins|hours|hrs)
    if (minutesToAdd == null) {
      final enMatch = RegExp(
        r'(?:in|after|next|for next|for)\s+([a-z0-9\-]+)(?:\s*(minutes?|mins?|hours?|hrs?))?',
      ).firstMatch(clean);

      if (enMatch != null) {
        final rawVal = enMatch.group(1)!;
        final unit = enMatch.group(2) ?? 'minutes';
        final numVal = int.tryParse(rawVal) ?? _numberWords[rawVal];
        if (numVal != null && numVal > 0) {
          if (unit.startsWith('h')) {
            minutesToAdd = numVal * 60;
          } else {
            minutesToAdd = numVal;
          }
        }
      }
    }

    // English shorthand: "5 mins", "5 minutes", "10 min" following alarm/reminder
    if (minutesToAdd == null) {
      final shortMatch = RegExp(
        r'\b(\d+|one|two|three|four|five|six|seven|eight|nine|ten|fifteen|twenty|thirty|forty|fifty|sixty)\s*(minutes?|mins?|hours?|hrs?)\b',
      ).firstMatch(clean);

      if (shortMatch != null) {
        final rawVal = shortMatch.group(1)!;
        final unit = shortMatch.group(2)!;
        final numVal = int.tryParse(rawVal) ?? _numberWords[rawVal];
        if (numVal != null && numVal > 0) {
          if (unit.startsWith('h')) {
            minutesToAdd = numVal * 60;
          } else {
            minutesToAdd = numVal;
          }
        }
      }
    }

    // Hindi patterns: (\d+|word) मिनट (में|बाद)? or (\d+|word) घंटे (में|बाद)?
    if (minutesToAdd == null) {
      final hiMatch = RegExp(
        r'([^\s]+)\s*मिनट(?:\s*(?:में|बाद|के बाद))?',
      ).firstMatch(clean);

      if (hiMatch != null) {
        final rawVal = hiMatch.group(1)!;
        final numVal = int.tryParse(rawVal) ?? _numberWords[rawVal];
        if (numVal != null && numVal > 0) {
          minutesToAdd = numVal;
        }
      } else {
        final hiHourMatch = RegExp(
          r'([^\s]+)\s*घंटे?(?:\s*(?:में|बाद|के बाद))?',
        ).firstMatch(clean);
        if (hiHourMatch != null) {
          final rawVal = hiHourMatch.group(1)!;
          final numVal = int.tryParse(rawVal) ?? _numberWords[rawVal];
          if (numVal != null && numVal > 0) {
            minutesToAdd = numVal * 60;
          }
        }
      }
    }

    // Telugu patterns: (\d+|word) నిమిషాల... or (\d+|word) గంటల...
    if (minutesToAdd == null) {
      final teMatch = RegExp(
        r'([^\s]+)\s*నిమిషాల?(?:్లో| తర్వాత|కు|కి|ు)?',
      ).firstMatch(clean);

      if (teMatch != null) {
        final rawVal = teMatch.group(1)!;
        final numVal = int.tryParse(rawVal) ?? _numberWords[rawVal];
        if (numVal != null && numVal > 0) {
          minutesToAdd = numVal;
        }
      } else {
        final teHourMatch = RegExp(
          r'([^\s]+)\s*గంటల?(?:్లో|లలో|\s*తర్వాత|\s*తరువాత)',
        ).firstMatch(clean);
        if (teHourMatch != null) {
          final rawVal = teHourMatch.group(1)!;
          final numVal = int.tryParse(rawVal) ?? _numberWords[rawVal];
          if (numVal != null && numVal > 0) {
            minutesToAdd = numVal * 60;
          }
        }
      }
    }

    if (minutesToAdd == null || minutesToAdd <= 0) return null;

    // Accurate addition rolls over midnight, dates, and months seamlessly
    final scheduled = ref.add(Duration(minutes: minutesToAdd));

    // Must be strictly in the future
    if (scheduled.isBefore(ref) || scheduled.isAtSameMomentAs(ref)) {
      return null;
    }

    final timeOfDayStr =
        '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}';

    return (scheduled, timeOfDayStr);
  }

  /// Strip command keywords and time expressions to extract pure reminder title.
  String? _extractTitle(String cleanInput, {bool hasDateTime = false}) {
    var text = cleanInput;

    const triggerOnly = [
      'set a reminder',
      'set reminder',
      'create a reminder',
      'create reminder',
      'remind me',
      'set an alarm',
      'set alarm',
      'alarm',
      'రిమైండర్ పెట్టు',
      'రిమైండర్',
      'నాకు గుర్తు చేయి',
      'గుర్తు చేయి',
      'అలారం పెట్టు',
      'అలారం',
      'रिमाइंडर लगाओ',
      'मुझे याद दिलाओ',
      'याद दिलाना',
      'याद दिलाओ',
      'रिमाइंडर',
      'अलार्म लगाओ',
      'अलार्म सेट करो',
      'अलार्म',
    ];

    final trimmed = text.trim();
    if (triggerOnly.contains(trimmed)) {
      if (!hasDateTime) return null;
      return trimmed.contains('alarm') || trimmed.contains('अलार्म') || trimmed.contains('అలారం')
          ? 'Alarm'
          : 'Reminder';
    }

    // Strip common trigger prefixes
    final prefixes = [
      'hey smriti, set an alarm for next ',
      'hey smriti set an alarm for next ',
      'hey smriti, set an alarm for ',
      'hey smriti set an alarm for ',
      'hey smriti, set an alarm to ',
      'hey smriti set an alarm to ',
      'hey smriti, set an alarm ',
      'hey smriti set an alarm ',
      'hey smriti, set a reminder for ',
      'hey smriti set a reminder for ',
      'hey smriti, set a reminder to ',
      'hey smriti set a reminder to ',
      'hey smriti, set a reminder ',
      'hey smriti set a reminder ',
      'hey smriti, remind me in ',
      'hey smriti remind me in ',
      'hey smriti, remind me after ',
      'hey smriti remind me after ',
      'hey smriti, remind me to ',
      'hey smriti remind me to ',
      'hey smriti, remind me ',
      'hey smriti remind me ',
      'hey, set an alarm for next ',
      'hey set an alarm for next ',
      'hey, set an alarm for ',
      'hey set an alarm for ',
      'hey, set an alarm to ',
      'hey set an alarm to ',
      'hey, set an alarm ',
      'hey set an alarm ',
      'set an alarm for next ',
      'set an alarm for ',
      'set an alarm to ',
      'set an alarm in ',
      'set an alarm after ',
      'set an alarm ',
      'set alarm for next ',
      'set alarm for ',
      'set alarm to ',
      'set alarm in ',
      'set alarm after ',
      'set alarm ',
      'alarm for next ',
      'alarm for ',
      'alarm in ',
      'alarm after ',
      'alarm ',
      'can you set an alarm for ',
      'can you set an alarm ',
      'can you set a reminder for ',
      'can you set a reminder to ',
      'can you set a reminder ',
      'can you remind me to ',
      'can you remind me in ',
      'can you remind me after ',
      'can you remind me for ',
      'can you remind me ',
      'please set an alarm for ',
      'please set an alarm ',
      'please set a reminder for ',
      'please set a reminder to ',
      'please set a reminder ',
      'please remind me to ',
      'please remind me in ',
      'please remind me after ',
      'please remind me for ',
      'please remind me ',
      'set a reminder to ',
      'set reminder to ',
      'set a reminder for next ',
      'set reminder for next ',
      'set a reminder for ',
      'set reminder for ',
      'set a reminder in ',
      'set reminder in ',
      'set a reminder after ',
      'set reminder after ',
      'set a reminder ',
      'set reminder ',
      'create a reminder to ',
      'create reminder to ',
      'create a reminder for ',
      'create reminder for ',
      'create a reminder ',
      'create reminder ',
      'remind me to ',
      'remind me in ',
      'remind me after ',
      'remind me for ',
      'remind me ',
      'అలారం పెట్టు ',
      'అలారం ',
      'రిమైండర్ పెట్టు ',
      'నాకు గుర్తు చేయి ',
      'గుర్తు చేయి ',
      'రిమైండర్ ',
      'अलार्म लगाओ ',
      'अलार्म सेट करो ',
      'अलार्म ',
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
      return text.contains('alarm') || text.contains('अलार्म') || text.contains('అలారం')
          ? 'Alarm'
          : 'Reminder';
    }

    // Strip relative time patterns from remainder
    text = text.replaceAll(
      RegExp(r'\b(?:in|after|next|for next|for)\s+[a-z0-9\-]+\s*(?:minutes?|mins?|hours?|hrs?)\b'),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\b(?:half an hour|half hour|an hour|one hour)\b'),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'\b(?:\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|twenty-five|twenty five|thirty|forty|forty-five|forty five|fifty|sixty)\s*(?:minutes?|mins?|hours?|hrs?)\b',
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(r'[^\s]+\s*మినిట్స్?(?:్లో| తర్వాత|కు|కి)?'),
      '',
    );
    text = text.replaceAll(
      RegExp(r'[^\s]+\s*నిమిషాల?(?:్లో| తర్వాత|కు|కి|ు)?'),
      '',
    );
    text = text.replaceAll(
      RegExp(r'[^\s]+\s*గంటల?(?:్లో| తర్వాత|కు|కి)?'),
      '',
    );
    text = text.replaceAll(
      RegExp(r'[^\s]+\s*मिनट(?:\s*(?:में|बाद|के बाद))?'),
      '',
    );
    text = text.replaceAll(
      RegExp(r'[^\s]+\s*घंटे?(?:\s*(?:में|बाद|के बाद))?'),
      '',
    );

    // Strip time/date suffixes and words
    final cleanWords = [
      'tomorrow at',
      'today at',
      'tomorrow',
      'today',
      'from now',
      'at',
      'for',
      'in',
      'next',
      'after',
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

    final isOnlyNumber = int.tryParse(text) != null || _numberWords.containsKey(text.toLowerCase());
    if (text.isEmpty || isOnlyNumber || text == 'medicine' || text == 'water') {
      if (text.isEmpty || isOnlyNumber) {
        if (!hasDateTime) return null;
        return cleanInput.contains('alarm') ||
                cleanInput.contains('अलार्म') ||
                cleanInput.contains('అలారం')
            ? 'Alarm'
            : 'Reminder';
      }
      return '${text[0].toUpperCase()}${text.substring(1)}';
    }

    // Capitalize first letter of title
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
