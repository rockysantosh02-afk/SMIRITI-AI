import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized localization dictionary and helper for Smriti AI.
/// Provides typed getters and fallbacks across English, Telugu, and Hindi.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en', 'US'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get _code => locale.languageCode.toLowerCase();

  String _t(String key) {
    return _localizedValues[_code]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // --- COMMON & NAVIGATION ---
  String get appTitle => _t('appTitle');
  String get appName => appTitle;
  String get home => _t('home');
  String get journal => _t('journal');
  String get games => _t('games');
  String get voiceAssistant => _t('voiceAssistant');
  String get reminders => _t('reminders');
  String get settings => _t('settings');
  String get back => _t('back');
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get confirm => _t('confirm');
  String get close => _t('close');
  String get done => _t('done');
  String get retry => _t('retry');
  String get comingSoon => _t('comingSoon');

  // --- SETTINGS ---
  String get language => _t('language');
  String get languageDesc => _t('languageDesc');
  String get selectLanguage => _t('selectLanguage');
  String get textSize => _t('textSize');
  String get textSizeDesc => _t('textSizeDesc');
  String get reducedMotion => _t('reducedMotion');
  String get reducedMotionDesc => _t('reducedMotionDesc');
  String get signOut => _t('signOut');
  String get signOutConfirm => _t('signOutConfirm');

  // --- DASHBOARD ---
  String get greetingMorning => _t('greetingMorning');
  String get greetingAfternoon => _t('greetingAfternoon');
  String get greetingEvening => _t('greetingEvening');
  String get welcomeBack => _t('welcomeBack');
  String get howAreYouFeeling => _t('howAreYouFeeling');
  String get quickActions => _t('quickActions');
  String get cognitiveGames => _t('cognitiveGames');
  String get cognitiveGamesDesc => _t('cognitiveGamesDesc');
  String get memoryJournal => _t('memoryJournal');
  String get memoryJournalDesc => _t('memoryJournalDesc');
  String get voiceCompanion => _t('voiceCompanion');
  String get voiceCompanionDesc => _t('voiceCompanionDesc');
  String get dailyReminders => _t('dailyReminders');
  String get dailyRemindersDesc => _t('dailyRemindersDesc');
  String get familyMemories => _t('familyMemories');
  String get familyMemoriesDesc => _t('familyMemoriesDesc');

  // --- JOURNAL ---
  String get journalTitle => _t('journalTitle');
  String get newEntry => _t('newEntry');
  String get editEntry => _t('editEntry');
  String get saveEntry => _t('saveEntry');
  String get savingEntry => _t('savingEntry');
  String get deleteEntry => _t('deleteEntry');
  String get deleteMemoryConfirmTitle => _t('deleteMemoryConfirmTitle');
  String get deleteMemoryConfirmMessage => _t('deleteMemoryConfirmMessage');
  String get inspirationPrompts => _t('inspirationPrompts');
  String get memoryPrompt1 => _t('memoryPrompt1');
  String get memoryPrompt2 => _t('memoryPrompt2');
  String get memoryPrompt3 => _t('memoryPrompt3');
  String get memoryPrompt4 => _t('memoryPrompt4');
  String get memoryTitle => _t('memoryTitle');
  String get memoryTitleHint => _t('memoryTitleHint');
  String get yourMemory => _t('yourMemory');
  String get yourMemoryHint => _t('yourMemoryHint');
  String get addPhoto => _t('addPhoto');
  String get gallery => _t('gallery');
  String get camera => _t('camera');
  String get speakYourMemory => _t('speakYourMemory');
  String get listeningDictation => _t('listeningDictation');
  String get stopDictation => _t('stopDictation');
  String get dictateHint => _t('dictateHint');
  String get aiStory => _t('aiStory');
  String get createAiStory => _t('createAiStory');
  String get creatingStory => _t('creatingStory');
  String get storyReflection => _t('storyReflection');
  String get noMemoriesYet => _t('noMemoriesYet');
  String get emptyJournalDesc => _t('emptyJournalDesc');
  String get journalPrivacyNotice => _t('journalPrivacyNotice');
  String get writeFirstMemory => _t('writeFirstMemory');
  String get memorySavedSuccess => _t('memorySavedSuccess');
  String get memorySaveError => _t('memorySaveError');

  // --- GAMES ---
  String get gamesHubTitle => _t('gamesHubTitle');
  String get gamesHubSubtitle => _t('gamesHubSubtitle');
  String get playAgain => _t('playAgain');
  String get wellDone => _t('wellDone');
  String get congratulations => _t('congratulations');
  String get tryAgain => _t('tryAgain');
  String get score => _t('score');
  String get round => _t('round');

  // Individual Games
  String get gameMatchingImageTitle => _t('gameMatchingImageTitle');
  String get gameMatchingImageDesc => _t('gameMatchingImageDesc');
  String get gamePickCorrectTitle => _t('gamePickCorrectTitle');
  String get gamePickCorrectDesc => _t('gamePickCorrectDesc');
  String get gameNumberGameTitle => _t('gameNumberGameTitle');
  String get gameNumberGameDesc => _t('gameNumberGameDesc');
  String get gamePlaceCorrectlyTitle => _t('gamePlaceCorrectlyTitle');
  String get gamePlaceCorrectlyDesc => _t('gamePlaceCorrectlyDesc');
  String get gameFindDifferenceTitle => _t('gameFindDifferenceTitle');
  String get gameFindDifferenceDesc => _t('gameFindDifferenceDesc');
  String get gameDrawShapeTitle => _t('gameDrawShapeTitle');
  String get gameDrawShapeDesc => _t('gameDrawShapeDesc');
  String get gameSituationMatchTitle => _t('gameSituationMatchTitle');
  String get gameSituationMatchDesc => _t('gameSituationMatchDesc');
  String get gameFamilyQuizTitle => _t('gameFamilyQuizTitle');
  String get gameFamilyQuizDesc => _t('gameFamilyQuizDesc');
  String get gameRecallingMemoriesTitle => _t('gameRecallingMemoriesTitle');
  String get gameRecallingMemoriesDesc => _t('gameRecallingMemoriesDesc');

  // --- VOICE ASSISTANT ---
  String get tapToSpeak => _t('tapToSpeak');
  String get listening => _t('listening');
  String get processing => _t('processing');
  String get tapToStop => _t('tapToStop');
  String get heardPrefix => _t('heardPrefix');
  String get notUnderstood => _t('notUnderstood');
  String get openingJournal => _t('openingJournal');
  String get creatingMemory => _t('creatingMemory');
  String get openingDashboard => _t('openingDashboard');
  String get openingGames => _t('openingGames');
  String get openingReminders => _t('openingReminders');
  String get permissionDenied => _t('permissionDenied');
  String get speechUnavailable => _t('speechUnavailable');
  String get privacyStatement => _t('privacyStatement');
  String get offlineClarification => _t('offlineClarification');

  // Voice Reminder Prompts
  String get askReminderTitle => _t('askReminderTitle');
  String get askReminderTime => _t('askReminderTime');
  String get reminderCreated => _t('reminderCreated');
  String get reminderCancelled => _t('reminderCancelled');

  // --- REMINDERS ---
  String get remindersTitle => _t('remindersTitle');
  String get createReminder => _t('createReminder');
  String get addReminder => _t('addReminder');
  String get editReminder => _t('editReminder');
  String get reminderTitleLabel => _t('reminderTitleLabel');
  String get reminderTitleHint => _t('reminderTitleHint');
  String get reminderTimeLabel => _t('reminderTimeLabel');
  String get reminderDateLabel => _t('reminderDateLabel');
  String get dailyRepeat => _t('dailyRepeat');
  String get saveReminder => _t('saveReminder');
  String get deleteReminder => _t('deleteReminder');
  String get noReminders => _t('noReminders');
  String get noRemindersDesc => _t('noRemindersDesc');
  String get typeReminder => _t('typeReminder');
  String get speakReminder => _t('speakReminder');
  String get confirmReminder => _t('confirmReminder');
  String get confirmSavePrompt => _t('confirmSavePrompt');
  String get today => _t('today');
  String get upcoming => _t('upcoming');
  String get completed => _t('completed');
  String get notificationsDisabledWarning => _t('notificationsDisabledWarning');
  String get recallingMemoriesYes => _t('recallingMemoriesYes');
  String get recallingMemoriesTellMore => _t('recallingMemoriesTellMore');
  String get pleaseFillRequiredDetails => _t('pleaseFillRequiredDetails');
  String get speechUnavailableForLanguage => _t('speechUnavailableForLanguage');
  String get memorySavedNoStory => _t('memorySavedNoStory');
  String get changeTime => _t('changeTime');
  String get familyMemberAdded => _t('familyMemberAdded');
  String get noFamilyMembers => _t('noFamilyMembers');
  String get addFamilyMember => _t('addFamilyMember');
  String get fullName => _t('fullName');
  String get relation => _t('relation');
  String get notesOptional => _t('notesOptional');
  String get saveMember => _t('saveMember');
  String get pickPhoto => _t('pickPhoto');
  String get levelComplete => _t('levelComplete');
  String get nextLevel => _t('nextLevel');
  String get currentLevel => _t('currentLevel');
  String get encouragementPositive => _t('encouragementPositive');
  String get encouragementGentle => _t('encouragementGentle');

  // --- LOCALIZED STRINGS DICTIONARY ---
  static const Map<String, Map<String, String>> _localizedValues = {
    // ================= ENGLISH =================
    'en': {
      'appTitle': 'Smriti AI',
      'home': 'Home',
      'journal': 'Journal',
      'games': 'Games',
      'voiceAssistant': 'Voice Assistant',
      'reminders': 'Reminders',
      'settings': 'Settings',
      'back': 'Back',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'close': 'Close',
      'done': 'Done',
      'retry': 'Retry',
      'comingSoon': 'Coming Soon',

      // Settings
      'language': 'Language',
      'languageDesc': 'Choose your preferred language',
      'selectLanguage': 'Select Language',
      'textSize': 'Text Size',
      'textSizeDesc': 'Adjust text size for better readability',
      'reducedMotion': 'Reduced Motion',
      'reducedMotionDesc': 'Use simple fade animations',
      'signOut': 'Sign Out',
      'signOutConfirm': 'Are you sure you want to sign out?',

      // Dashboard
      'greetingMorning': 'Good Morning',
      'greetingAfternoon': 'Good Afternoon',
      'greetingEvening': 'Good Evening',
      'welcomeBack': 'Welcome back to Smriti AI',
      'howAreYouFeeling': 'How are you feeling today?',
      'quickActions': 'Quick Activities',
      'cognitiveGames': 'Brain Games',
      'cognitiveGamesDesc': 'Gentle games to keep your mind refreshed',
      'memoryJournal': 'Memory Journal',
      'memoryJournalDesc': 'Record and cherish your personal memories',
      'voiceCompanion': 'Voice Assistant',
      'voiceCompanionDesc': 'Speak naturally to navigate and set reminders',
      'dailyReminders': 'Reminders',
      'dailyRemindersDesc': 'Manage your daily routine and medicines',
      'familyMemories': 'Family Album',
      'familyMemoriesDesc': 'Photos and moments with loved ones',

      // Journal
      'journalTitle': 'Personal Memory Journal',
      'newEntry': 'New Memory',
      'editEntry': 'Edit Memory',
      'saveEntry': 'Save Memory',
      'savingEntry': 'Saving...',
      'deleteEntry': 'Delete Memory',
      'deleteMemoryConfirmTitle': 'Remove Memory?',
      'deleteMemoryConfirmMessage': 'Are you sure you want to remove this memory from your journal?',
      'inspirationPrompts': 'Inspiration Prompts:',
      'memoryPrompt1': 'Tell me about a happy memory',
      'memoryPrompt2': 'Tell me about this special day',
      'memoryPrompt3': 'What do you remember about this place?',
      'memoryPrompt4': 'A memory of family or friends',
      'memoryTitle': 'Memory Title:',
      'memoryTitleHint': 'e.g., Morning tea in the garden',
      'yourMemory': 'Your Memory:',
      'yourMemoryHint': 'Write what you remember about this time...',
      'addPhoto': 'Add Photo:',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'speakYourMemory': 'Speak Your Memory',
      'listeningDictation': 'Listening...',
      'stopDictation': 'Tap button to stop',
      'dictateHint': 'Spoken words will appear in your journal',
      'aiStory': 'AI Story Reflection:',
      'createAiStory': '✨ Create a Story',
      'creatingStory': 'Creating your story...',
      'storyReflection': '✨ Your Story',
      'noMemoriesYet': 'Your memories will appear here',
      'emptyJournalDesc': 'Every memory is special. Your journal is a private place to keep happy memories.',
      'journalPrivacyNotice': 'Your memory journal is completely private to you.',
      'writeFirstMemory': 'Add Your First Memory',
      'memorySavedSuccess': 'Your memory has been safely saved.',
      'memorySaveError': 'Could not save memory right now. Please try again.',

      // Games
      'gamesHubTitle': 'Daily Mind Exercises',
      'gamesHubSubtitle': 'Each game is designed to keep your mind active and joyful.',
      'playAgain': 'Play Again',
      'wellDone': 'Well Done!',
      'congratulations': 'Congratulations!',
      'tryAgain': 'Try Again',
      'score': 'Score',
      'round': 'Round',
      'gameMatchingImageTitle': 'Matching Image',
      'gameMatchingImageDesc': 'Find identical items or pair memory cards',
      'gamePickCorrectTitle': 'Pick the Correct One',
      'gamePickCorrectDesc': 'Recognize the right items and instruments',
      'gameNumberGameTitle': 'Number Game',
      'gameNumberGameDesc': 'Counting, sequences, and gentle math',
      'gamePlaceCorrectlyTitle': 'Place Correctly',
      'gamePlaceCorrectlyDesc': 'Position items in their right locations',
      'gameFindDifferenceTitle': 'Find the Difference',
      'gameFindDifferenceDesc': 'Spot subtle changes between two images',
      'gameDrawShapeTitle': 'Draw Shape',
      'gameDrawShapeDesc': 'Trace simple shapes and patterns',
      'gameSituationMatchTitle': 'Situation Match',
      'gameSituationMatchDesc': 'Match objects with everyday situations',
      'gameFamilyQuizTitle': 'Family Quiz',
      'gameFamilyQuizDesc': 'Gentle trivia about family members',
      'gameRecallingMemoriesTitle': 'Recalling Memories',
      'gameRecallingMemoriesDesc': 'Reminisce about fond past events',

      // Voice Assistant
      'tapToSpeak': 'Tap to Speak',
      'listening': 'Listening... Speak clearly',
      'processing': 'Understanding...',
      'tapToStop': 'Tap to Stop',
      'heardPrefix': 'I heard:',
      'notUnderstood': 'I didn\'t understand that. Please try speaking again.',
      'openingJournal': 'Opening your Journal...',
      'creatingMemory': 'Opening New Memory...',
      'openingDashboard': 'Going back Home...',
      'openingGames': 'Opening Games...',
      'openingReminders': 'Opening Reminders...',
      'permissionDenied': 'Microphone permission is needed for voice commands. You can still use the app with buttons.',
      'speechUnavailable': 'Voice commands are not available right now. You can continue using the buttons.',
      'privacyStatement': 'Smriti AI does not record, save, or upload your voice recordings. Speech recognition is handled by your device\'s speech service.',
      'offlineClarification': 'Whether speech recognition works offline depends on your device and installed language support.',
      'askReminderTitle': 'What would you like me to remind you about?',
      'askReminderTime': 'When should I remind you?',
      'reminderCreated': 'Okay, I have created your reminder.',
      'reminderCancelled': 'Reminder creation cancelled.',

      // Reminders
      'remindersTitle': 'My Reminders',
      'createReminder': 'Create Reminder',
      'addReminder': 'Add Reminder',
      'editReminder': 'Edit Reminder',
      'reminderTitleLabel': 'Reminder Title',
      'reminderTitleHint': 'e.g., Take evening medicine',
      'reminderTimeLabel': 'Time',
      'reminderDateLabel': 'Date',
      'dailyRepeat': 'Repeat every day',
      'saveReminder': 'Save Reminder',
      'deleteReminder': 'Delete Reminder',
      'noReminders': 'No reminders yet',
      'noRemindersDesc': 'Add reminders for your daily medicines or activities.',
      'typeReminder': 'Type Reminder',
      'speakReminder': 'Speak Reminder',
      'confirmReminder': 'Confirm Reminder',
      'confirmSavePrompt': 'Save this reminder?',
      'today': 'Today',
      'upcoming': 'Upcoming',
      'completed': 'Completed',
      'notificationsDisabledWarning': 'Notifications are turned off. Your reminders are still saved safely on this device.',
      'recallingMemoriesYes': 'Yes, wonderful memories!',
      'recallingMemoriesTellMore': 'Tell me more / Next picture',
      'pleaseFillRequiredDetails': 'Please fill in the required details.',
      'speechUnavailableForLanguage': 'Speech recognition is not available for this language on this device.',
      'memorySavedNoStory': 'Your memory has been saved. We could not create the story right now.',
      'changeTime': 'Change Time',
      'familyMemberAdded': 'Family member added successfully',
      'noFamilyMembers': 'No family members added yet',
      'addFamilyMember': 'Add Family Member',
      'fullName': 'Full Name',
      'relation': 'Relation',
      'notesOptional': 'Notes (optional)',
      'saveMember': 'Save Member',
      'pickPhoto': 'Pick photo',
      'levelComplete': 'Level Complete! You played wonderfully today!',
      'nextLevel': 'Next Level',
      'currentLevel': 'Current Level',
      'encouragementPositive': 'Well done! Excellent work!',
      'encouragementGentle': 'Good try. Take your time, let\'s try again!',
    },

    // ================= TELUGU =================
    'te': {
      'appTitle': 'స్మృతి AI',
      'home': 'హోమ్',
      'journal': 'డైరీ',
      'games': 'ఆటలు',
      'voiceAssistant': 'వాయిస్ అసిస్టెంట్',
      'reminders': 'రిమైండర్లు',
      'settings': 'సెట్టింగ్స్',
      'back': 'వెనుకకు',
      'save': 'సేవ్ చేయండి',
      'cancel': 'రద్దు చేయండి',
      'delete': 'తొలగించండి',
      'confirm': 'నిర్ధారించండి',
      'close': 'మూసివేయండి',
      'done': 'పూర్తయింది',
      'retry': 'మళ్ళీ ప్రయత్నించండి',
      'comingSoon': 'త్వరలో రాబోతోంది',

      // Settings
      'language': 'భాష',
      'languageDesc': 'మీకు నచ్చిన భాషను ఎంచుకోండి',
      'selectLanguage': 'భాషను ఎంచుకోండి',
      'textSize': 'అక్షరాల పరిమాణం',
      'textSizeDesc': 'చదవడానికి వీలుగా అక్షరాల పరిమాణాన్ని మార్చండి',
      'reducedMotion': 'తక్కువ కదలిక',
      'reducedMotionDesc': 'సులభమైన యానిమేషన్లను ఉపయోగించండి',
      'signOut': 'లాగ్ అవుట్',
      'signOutConfirm': 'మీరు నిజంగా లాగ్ అవుట్ అవ్వాలనుకుంటున్నారా?',

      // Dashboard
      'greetingMorning': 'శుభోదయం',
      'greetingAfternoon': 'శుభ మధ్యాహ్నం',
      'greetingEvening': 'శుభ సాయంత్రం',
      'welcomeBack': 'స్మృతి AI కి స్వాగతం',
      'howAreYouFeeling': 'ఈ రోజు మీరు ఎలా ఉన్నారు?',
      'quickActions': 'ముఖ్యమైన పనులు',
      'cognitiveGames': 'మెదడు ఆటలు',
      'cognitiveGamesDesc': 'మెదడును ఉల్లాసంగా ఉంచే సరదా ఆటలు',
      'memoryJournal': 'జ్ఞాపకాల డైరీ',
      'memoryJournalDesc': 'మీ అనుభవాలను భద్రపరచుకోండి',
      'voiceCompanion': 'వాయిస్ అసిస్టెంట్',
      'voiceCompanionDesc': 'యాప్‌ను ఉపయోగించడానికి మరియు రిమైండర్లు పెట్టడానికి మాట్లాడండి',
      'dailyReminders': 'రిమైండర్లు',
      'dailyRemindersDesc': 'మందులు మరియు పనుల సమయాలను గుర్తుచేస్తుంది',
      'familyMemories': 'కుటుంబ ఆల్బమ్',
      'familyMemoriesDesc': 'కుటుంబ సభ్యులతో మధుర జ్ఞాపకాలు',

      // Journal
      'journalTitle': 'జ్ఞాపకాల డైరీ',
      'newEntry': 'కొత్త జ్ఞాపకం',
      'editEntry': 'జ్ఞాపకం సవరించండి',
      'saveEntry': 'జ్ఞాపకం సేవ్ చేయండి',
      'savingEntry': 'సేవ్ అవుతోంది...',
      'deleteEntry': 'జ్ఞాపకం తొలగించండి',
      'deleteMemoryConfirmTitle': 'జ్ఞాపకం తొలగించాలా?',
      'deleteMemoryConfirmMessage': 'ఈ జ్ఞాపకాన్ని మీ డైరీ నుండి తొలగించాలనుకుంటున్నారా?',
      'inspirationPrompts': 'ఆలోచనలు:',
      'memoryPrompt1': 'మీకు నచ్చిన ఒక సంతోషకరమైన క్షణం గురించి చెప్పండి',
      'memoryPrompt2': 'ఈ ప్రత్యేకమైన రోజు గురించి చెప్పండి',
      'memoryPrompt3': 'ఈ ప్రదేశం గురించి మీకు ఏమి గుర్తుంది?',
      'memoryPrompt4': 'కుటుంబం లేదా స్నేహితులతో ఒక జ్ఞాపకం',
      'memoryTitle': 'జ్ఞాపకం శీర్షిక:',
      'memoryTitleHint': 'ఉదా: తోటలో ఉదయం టీ',
      'yourMemory': 'మీ జ్ఞాపకం:',
      'yourMemoryHint': 'ఈ సమయం గురించి మీకు గుర్తున్న విషయాలు ఇక్కడ రాయండి...',
      'addPhoto': 'ఫోటో జోడించండి:',
      'gallery': 'గ్యాలరీ',
      'camera': 'కెమెరా',
      'speakYourMemory': 'వాయిస్ ద్వారా చెప్పండి',
      'listeningDictation': 'వింటున్నాము...',
      'stopDictation': 'ఆపడానికి బటన్ నొక్కండి',
      'dictateHint': 'మీరు మాట్లాడే మాటలు ఇక్కడ రాయబడతాయి',
      'aiStory': 'AI కథనం:',
      'createAiStory': '✨ కథను సృష్టించండి',
      'creatingStory': 'కథ సిద్ధమవుతోంది...',
      'storyReflection': '✨ మీ జ్ఞాపకం యొక్క అందమైన ప్రతిబింబం',
      'noMemoriesYet': 'ఇంకా జ్ఞాపకాలు లేవు',
      'emptyJournalDesc': 'మీ సంతోషకరమైన జ్ఞాపకాలను భద్రపరచుకోవడానికి క్రింది బటన్ నొక్కి మొదటి జ్ఞాపకం రాయండి.',
      'journalPrivacyNotice': 'మీ జ్ఞాపకాల డైరీ పూర్తిగా ప్రైవేట్ మరియు సురక్షితమైనది.',
      'writeFirstMemory': 'మొదటి జ్ఞాపకం రాయండి',
      'memorySavedSuccess': 'మీ జ్ఞాపకం భద్రపరచబడింది.',
      'memorySaveError': 'ప్రస్తుతం జ్ఞాపకాన్ని సేవ్ చేయడం సాధ్యం కాలేదు. మళ్ళీ ప్రయత్నించండి.',

      // Games
      'gamesHubTitle': 'రోజువారీ మెదడు వ్యాయామాలు',
      'gamesHubSubtitle': 'ప్రతి ఆట మీ మెదడును ఉల్లాసంగా మరియు చురుగ్గా ఉంచడానికి రూపొందించబడింది.',
      'playAgain': 'మళ్ళీ ఆడండి',
      'wellDone': 'చాలా బాగుంది!',
      'congratulations': 'అభినందనలు!',
      'tryAgain': 'మళ్ళీ ప్రయత్నించండి',
      'score': 'స్కోరు',
      'round': 'రౌండ్',
      'gameMatchingImageTitle': 'చిత్రాలను సరిపోల్చండి',
      'gameMatchingImageDesc': 'ఒకేలాంటి చిత్రాలను లేదా కార్డులను జత చేయండి',
      'gamePickCorrectTitle': 'సరైనదాన్ని ఎంచుకోండి',
      'gamePickCorrectDesc': 'సరైన వస్తువులు మరియు పరికరాలను గుర్తించండి',
      'gameNumberGameTitle': 'సంఖ్యల ఆట',
      'gameNumberGameDesc': 'లెక్కించడం మరియు సంఖ్యల క్రమం',
      'gamePlaceCorrectlyTitle': 'సరైన స్థానంలో ఉంచండి',
      'gamePlaceCorrectlyDesc': 'వస్తువులను సరైన స్థానంలో అమర్చండి',
      'gameFindDifferenceTitle': 'తేడాలను గుర్తించండి',
      'gameFindDifferenceDesc': 'రెండు చిత్రాల మధ్య ఉన్న తేడాలను కనుగొనండి',
      'gameDrawShapeTitle': 'ఆకారాలు గీయండి',
      'gameDrawShapeDesc': 'సాధారణ ఆకారాలను గీయండి',
      'gameSituationMatchTitle': 'సందర్భాన్ని సరిపోల్చండి',
      'gameSituationMatchDesc': 'వస్తువులను సరైన సందర్భంతో జత చేయండి',
      'gameFamilyQuizTitle': 'కుటుంబ క్విజ్',
      'gameFamilyQuizDesc': 'కుటుంబ సభ్యుల గురించి సరదా ప్రశ్నలు',
      'gameRecallingMemoriesTitle': 'జ్ఞాపకాలను గుర్తుచేసుకోవడం',
      'gameRecallingMemoriesDesc': 'గతంలోని మధుర క్షణాలను గుర్తుచేసుకోండి',

      // Voice Assistant
      'tapToSpeak': 'మాట్లాడటానికి నొక్కండి',
      'listening': 'వింటున్నాము... స్పష్టంగా మాట్లాడండి',
      'processing': 'అర్థం చేసుకుంటున్నాము...',
      'tapToStop': 'ఆపడానికి నొక్కండి',
      'heardPrefix': 'నేను విన్నది:',
      'notUnderstood': 'అర్థం కాలేదు. దయచేసి మళ్ళీ మాట్లాడండి.',
      'openingJournal': 'మీ డైరీ తెరవబడుతోంది...',
      'creatingMemory': 'కొత్త జ్ఞాపకం తెరవబడుతోంది...',
      'openingDashboard': 'హోమ్ పేజీకి వెళ్తున్నాము...',
      'openingGames': 'ఆటల పేజీకి వెళ్తున్నాము...',
      'openingReminders': 'రిమైండర్లు తెరవబడుతున్నాయి...',
      'permissionDenied': 'వాయిస్ సేవల కోసం మైక్రోఫోన్ అనుమతి అవసరం. మీరు బటన్లను ఉపయోగించవచ్చు.',
      'speechUnavailable': 'ఈ పరికరంలో వాయిస్ సేవ అందుబాటులో లేదు. మీరు బటన్లను ఉపయోగించవచ్చు.',
      'privacyStatement': 'స్మృతి AI మీ వాయిస్ రికార్డింగ్‌లను సేవ్ చేయదు లేదా అప్‌లోడ్ చేయదు. మీ పరికర వాయిస్ సేవ ద్వారా వాయిస్ గుర్తించబడుతుంది.',
      'offlineClarification': 'వాయిస్ గుర్తింపు ఆఫ్‌లైన్‌లో పనిచేస్తుందా లేదా అనేది మీ పరికరం మరియు భాషా మద్దతుపై ఆధారపడి ఉంటుంది.',
      'askReminderTitle': 'మీకు ఏ విషయం గురించి గుర్తు చేయాలి?',
      'askReminderTime': 'ఏ సమయంలో గుర్తు చేయాలి?',
      'reminderCreated': 'సరే, మీ రిమైండర్ సేవ్ చేయబడింది.',
      'reminderCancelled': 'రిమైండర్ రద్దు చేయబడింది.',

      // Reminders
      'remindersTitle': 'రోజువారీ రిమైండర్లు',
      'createReminder': 'రిమైండర్ సెట్ చేయండి',
      'addReminder': 'రిమైండర్ జోడించండి',
      'editReminder': 'రిమైండర్ సవరించండి',
      'reminderTitleLabel': 'రిమైండర్ వివరాలు',
      'reminderTitleHint': 'ఉదా: సాయంత్రం మందులు వేసుకోవాలి',
      'reminderTimeLabel': 'సమయం',
      'reminderDateLabel': 'తేదీ',
      'dailyRepeat': 'ప్రతిరోజూ పునరావృతం చేయండి',
      'saveReminder': 'రిమైండర్ సేవ్ చేయండి',
      'deleteReminder': 'రిమైండర్ తొలగించండి',
      'noReminders': 'ఇంకా రిమైండర్లు లేవు',
      'noRemindersDesc': 'మీ మందులు మరియు పనుల కోసం రిమైండర్లను జోడించండి.',
      'typeReminder': 'టైప్ చేసి రాయండి',
      'speakReminder': 'మాట్లాడి చెప్పండి',
      'confirmReminder': 'రిమైండర్ ఖరారు',
      'confirmSavePrompt': 'ఈ రిమైండర్‌ను సేవ్ చేయాలా?',
      'today': 'ఈరోజు',
      'upcoming': 'రాబోయేవి',
      'completed': 'పూర్తయినవి',
      'notificationsDisabledWarning': 'నోటిఫికేషన్‌లు ఆఫ్ చేయబడ్డాయి. మీ రిమైండర్‌లు పరికరంలో సురక్షితంగా ఉన్నాయి.',
      'recallingMemoriesYes': 'అవును, చక్కటి జ్ఞాపకాలు!',
      'recallingMemoriesTellMore': 'ఇంకా చెప్పండి / తదుపరి చిత్రం',
      'pleaseFillRequiredDetails': 'దయచేసి అవసరమైన వివరాలను పూరించండి.',
      'speechUnavailableForLanguage': 'ఈ పరికరంలో ఈ భాషకు వాయిస్ గుర్తింపు అందుబాటులో లేదు.',
      'memorySavedNoStory': 'మీ జ్ఞాపకం భద్రపరచబడింది. ప్రస్తుతం కథను సృష్టించలేకపోయాము.',
      'changeTime': 'సమయం మార్చండి',
      'familyMemberAdded': 'కుటుంబ సభ్యుడు విజయవంతంగా జోడించబడ్డారు',
      'noFamilyMembers': 'ఇంకా కుటుంబ సభ్యులు జోడించబడలేదు',
      'addFamilyMember': 'కుటుంబ సభ్యుడిని జోడించండి',
      'fullName': 'పూర్తి పేరు',
      'relation': 'సంబంధం',
      'notesOptional': 'గమనికలు (ఐచ్ఛికం)',
      'saveMember': 'సభ్యుడిని భద్రపరచండి',
      'pickPhoto': 'ఫోటోను ఎంచుకోండి',
      'levelComplete': 'లెవెల్ పూర్తయింది! మీరు ఈరోజు అద్భుతంగా ఆడారు!',
      'nextLevel': 'తరువాతి లెవెల్',
      'currentLevel': 'ప్రస్తుత లెవెల్',
      'encouragementPositive': 'చాలా బాగుంది! అద్భుతమైన పని!',
      'encouragementGentle': 'మంచి ప్రయత్నం. నెమ్మదిగా ఆలోచించండి, మళ్ళీ ప్రయత్నిద్దాం!',
    },

    // ================= HINDI =================
    'hi': {
      'appTitle': 'स्मृति AI',
      'home': 'होम',
      'journal': 'डायरी',
      'games': 'खेल',
      'voiceAssistant': 'आवाज़ सहायक',
      'reminders': 'रिमाइंडर',
      'settings': 'सेटिंग्स',
      'back': 'वापस',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'confirm': 'पुष्टि करें',
      'close': 'बंद करें',
      'done': 'संपन्न',
      'retry': 'पुनः प्रयास करें',
      'comingSoon': 'शीघ्र आ रहा है',

      // Settings
      'language': 'भाषा',
      'languageDesc': 'अपनी पसंदीदा भाषा चुनें',
      'selectLanguage': 'भाषा चुनें',
      'textSize': 'अक्षर का आकार',
      'textSizeDesc': 'बेहतर पढ़ने के लिए अक्षरों का आकार बदलें',
      'reducedMotion': 'धीमी गति',
      'reducedMotionDesc': 'सरल एनिमेशन का उपयोग करें',
      'signOut': 'साइन आउट',
      'signOutConfirm': 'क्या आप वाकई साइन आउट करना चाहते हैं?',

      // Dashboard
      'greetingMorning': 'शुभ प्रभात',
      'greetingAfternoon': 'शुभ दोपहर',
      'greetingEvening': 'शुभ संध्या',
      'welcomeBack': 'स्मृति AI में आपका स्वागत है',
      'howAreYouFeeling': 'आज आप कैसा महसूस कर रहे हैं?',
      'quickActions': 'मुख्य गतिविधियाँ',
      'cognitiveGames': 'दिमागी खेल',
      'cognitiveGamesDesc': 'मन को तरोताज़ा रखने वाले सरल खेल',
      'memoryJournal': 'यादों की डायरी',
      'memoryJournalDesc': 'अपनी सुखद यादों को संजोएं',
      'voiceCompanion': 'आवाज़ सहायक',
      'voiceCompanionDesc': 'ऐप चलाने और रिमाइंडर लगाने के लिए बोलें',
      'dailyReminders': 'रिमाइंडर',
      'dailyRemindersDesc': 'दवाइयों और दैनिक कार्यों की समय-सारणी',
      'familyMemories': 'पारिवारिक एल्बम',
      'familyMemoriesDesc': 'अपनों के साथ बिताए गए पल',

      // Journal
      'journalTitle': 'यादों की डायरी',
      'newEntry': 'नई याद',
      'editEntry': 'याद संपादित करें',
      'saveEntry': 'याद सहेजें',
      'savingEntry': 'सहेजा जा रहा है...',
      'deleteEntry': 'याद हटाएं',
      'deleteMemoryConfirmTitle': 'याद हटाएं?',
      'deleteMemoryConfirmMessage': 'क्या आप इस याद को अपनी डायरी से हटाना चाहते हैं?',
      'inspirationPrompts': 'सुझाव:',
      'memoryPrompt1': 'किसी सुखद याद के बारे में बताएं',
      'memoryPrompt2': 'इस विशेष दिन के बारे में बताएं',
      'memoryPrompt3': 'इस जगह के बारे में आपको क्या याद है?',
      'memoryPrompt4': 'परिवार या दोस्तों के साथ बिताया कोई पल',
      'memoryTitle': 'याद का शीर्षक:',
      'memoryTitleHint': 'उदा: बगीचे में सुबह की चाय',
      'yourMemory': 'आपकी याद:',
      'yourMemoryHint': 'इस समय के बारे में जो याद हो, यहाँ लिखें...',
      'addPhoto': 'तस्वीर जोड़ें:',
      'gallery': 'गैलरी',
      'camera': 'कैमरा',
      'speakYourMemory': 'बोलकर लिखें',
      'listeningDictation': 'सुन रहे हैं...',
      'stopDictation': 'रोकने के लिए बटन दबाएं',
      'dictateHint': 'आपके बोले गए शब्द डायरी में जुड़ जाएंगे',
      'aiStory': 'AI कहानी संस्मरण:',
      'createAiStory': '✨ कहानी बनाएं',
      'creatingStory': 'कहानी बनाई जा रही है...',
      'storyReflection': '✨ आपकी याद का एक सुंदर संस्मरण',
      'noMemoriesYet': 'अभी कोई याद नहीं है',
      'emptyJournalDesc': 'अपनी सुखद यादों को सहेजने के लिए नीचे दिए गए बटन पर टैप करें।',
      'journalPrivacyNotice': 'आपकी यादों की डायरी पूरी तरह से निजी और सुरक्षित है।',
      'writeFirstMemory': 'अपनी पहली याद लिखें',
      'memorySavedSuccess': 'आपकी याद सुरक्षित सहेज ली गई है।',
      'memorySaveError': 'इस समय याद को सहेजा नहीं जा सका। कृपया पुनः प्रयास करें।',

      // Games
      'gamesHubTitle': 'दैनिक दिमागी अभ्यास',
      'gamesHubSubtitle': 'प्रत्येक खेल आपके मस्तिष्क को सक्रिय और प्रसन्न रखने के लिए बनाया गया है।',
      'playAgain': 'पुनः खेलें',
      'wellDone': 'बहुत बढ़िया!',
      'congratulations': 'बधाई हो!',
      'tryAgain': 'पुनः प्रयास करें',
      'score': 'अंक',
      'round': 'दौर',
      'gameMatchingImageTitle': 'तस्वीर मिलान',
      'gameMatchingImageDesc': 'समान वस्तुएं या कार्ड मिलाएं',
      'gamePickCorrectTitle': 'सही चुनें',
      'gamePickCorrectDesc': 'सही वस्तुएं पहचानें',
      'gameNumberGameTitle': 'संख्या खेल',
      'gameNumberGameDesc': 'गिनती और सरल अंकगणित',
      'gamePlaceCorrectlyTitle': 'सही स्थान पर रखें',
      'gamePlaceCorrectlyDesc': 'वस्तुओं को उनके सही स्थान पर सजाएं',
      'gameFindDifferenceTitle': 'अंतर खोजें',
      'gameFindDifferenceDesc': 'दो चित्रों के बीच अंतर पहचानें',
      'gameDrawShapeTitle': 'आकार बनाएं',
      'gameDrawShapeDesc': 'सरल आकृतियां बनाएं',
      'gameSituationMatchTitle': 'परिस्थिति मिलान',
      'gameSituationMatchDesc': 'वस्तुओं को सही परिस्थिति से जोड़ें',
      'gameFamilyQuizTitle': 'परिवार प्रश्नोत्तरी',
      'gameFamilyQuizDesc': 'परिवार के बारे में सरल प्रश्न',
      'gameRecallingMemoriesTitle': 'यादें ताज़ा करें',
      'gameRecallingMemoriesDesc': 'बीते पलों को याद करें',

      // Voice Assistant
      'tapToSpeak': 'बोलने के लिए दबाएं',
      'listening': 'सुन रहे हैं... कृपया स्पष्ट बोलें',
      'processing': 'समझने का प्रयास कर रहे हैं...',
      'tapToStop': 'रोकने के लिए दबाएं',
      'heardPrefix': 'मैंने सुना:',
      'notUnderstood': 'समझ नहीं पाए। कृपया दोबारा बोलें।',
      'openingJournal': 'आपकी यादों की डायरी खुल रही है...',
      'creatingMemory': 'नई याद का पृष्ठ खुल रहा है...',
      'openingDashboard': 'होम पेज पर वापस जा रहे हैं...',
      'openingGames': 'खेलों के पेज पर जा रहे हैं...',
      'openingReminders': 'रिमाइंडर खुल रहे हैं...',
      'permissionDenied': 'आवाज़ पहचान के लिए माइक्रोफ़ोन की अनुमति आवश्यक है। आप बटनों का उपयोग कर सकते हैं।',
      'speechUnavailable': 'इस डिवाइस पर आवाज़ सेवा उपलब्ध नहीं है। आप बटनों का उपयोग कर सकते हैं।',
      'privacyStatement': 'स्मृति AI आपकी आवाज़ रिकॉर्ड या अपलोड नहीं करता है। आवाज़ पहचान आपके डिवाइस द्वारा की जाती है।',
      'offlineClarification': 'आवाज़ पहचान ऑफ़लाइन काम करेगी या नहीं यह आपके डिवाइस पर निर्भर करता है।',
      'askReminderTitle': 'आप किस बारे में रिमाइंडर लगाना चाहते हैं?',
      'askReminderTime': 'किस समय का रिमाइंडर लगाना है?',
      'reminderCreated': 'ठीक है, आपका रिमाइंडर सेट कर दिया गया है।',
      'reminderCancelled': 'रिमाइंडर रद्द कर दिया गया।',

      // Reminders
      'remindersTitle': 'दैनिक रिमाइंडर',
      'createReminder': 'रिमाइंडर बनाएं',
      'addReminder': 'रिमाइंडर जोड़ें',
      'editReminder': 'रिमाइंडर संपादित करें',
      'reminderTitleLabel': 'रिमाइंडर का नाम',
      'reminderTitleHint': 'उदा: शाम की दवा लेना',
      'reminderTimeLabel': 'समय',
      'reminderDateLabel': 'तारीख',
      'dailyRepeat': 'रोज़ाना दोहराएं',
      'saveReminder': 'रिमाइंडर सहेजें',
      'deleteReminder': 'रिमाइंडर हटाएं',
      'noReminders': 'अभी कोई रिमाइंडर नहीं है',
      'noRemindersDesc': 'अपनी दवाइयों और ज़रूरी कामों के लिए रिमाइंडर जोड़ें।',
      'typeReminder': 'टाइप करके लिखें',
      'speakReminder': 'बोलकर बताएं',
      'confirmReminder': 'रिमाइंडर पुष्टि',
      'confirmSavePrompt': 'क्या यह रिमाइंडर सेव करें?',
      'today': 'आज',
      'upcoming': 'आगामी',
      'completed': 'पूर्ण',
      'notificationsDisabledWarning': 'सूचनाएं बंद हैं। आपके रिमाइंडर डिवाइस में सुरक्षित हैं।',
      'recallingMemoriesYes': 'हाँ, बहुत सुंदर यादें!',
      'recallingMemoriesTellMore': 'और बताएं / अगली तस्वीर',
      'pleaseFillRequiredDetails': 'कृपया आवश्यक विवरण भरें।',
      'speechUnavailableForLanguage': 'इस डिवाइस पर इस भाषा के लिए भाषण पहचान उपलब्ध नहीं है।',
      'memorySavedNoStory': 'आपकी याद सुरक्षित रूप से सहेज ली गई है। हम अभी कहानी नहीं बना सके।',
      'changeTime': 'समय बदलें',
      'familyMemberAdded': 'परिवार का सदस्य सफलतापूर्वक जोड़ा गया',
      'noFamilyMembers': 'अभी तक कोई परिवार का सदस्य नहीं जोड़ा गया',
      'addFamilyMember': 'परिवार का सदस्य जोड़ें',
      'fullName': 'पूरा नाम',
      'relation': 'रिश्ता',
      'notesOptional': 'नोट्स (वैकल्पिक)',
      'saveMember': 'सदस्य सहेजें',
      'pickPhoto': 'फोटो चुनें',
      'levelComplete': 'स्तर पूरा हुआ! आपने आज बहुत अच्छा खेला!',
      'nextLevel': 'अगला स्तर',
      'currentLevel': 'वर्तमान स्तर',
      'encouragementPositive': 'बहुत बढ़िया! शानदार काम!',
      'encouragementGentle': 'अच्छा प्रयास। अपना समय लें, फिर से कोशिश करें!',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'te', 'hi'].contains(locale.languageCode.toLowerCase());
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
