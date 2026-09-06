/// Pre-authored, elderly-calm multilingual strings for Smriti AI Voice Assistant.
///
/// Designed with respect, clarity, and gentle guidance for elders in English, Telugu, and Hindi.
class VoicePrompts {
  VoicePrompts._();

  // --- Initial Greeting (Phase 6) ---
  static const Map<String, String> initialGreeting = {
    'en': 'Hello. What would you like me to help you with?',
    'te': 'హలో. నేను మీకు ఎలా సహాయం చేయగలను?',
    'hi': 'नमस्ते। मैं आपकी कैसे मदद कर सकता हूँ?',
  };

  // --- UI States ---

  static const Map<String, String> tapToSpeak = {
    'en': 'Tap to Speak',
    'te': 'మాట్లాడటానికి నొక్కండి',
    'hi': 'बोलने के लिए दबाएं',
  };

  static const Map<String, String> listening = {
    'en': 'Listening... Speak clearly',
    'te': 'వింటున్నాము... స్పష్టంగా మాట్లాడండి',
    'hi': 'सुन रहे हैं... कृपया स्पष्ट बोलें',
  };

  static const Map<String, String> processing = {
    'en': 'Understanding...',
    'te': 'అర్థం చేసుకుంటున్నాము...',
    'hi': 'समझने का प्रयास कर रहे हैं...',
  };

  static const Map<String, String> tapToStop = {
    'en': 'Tap to Stop',
    'te': 'ఆపడానికి నొక్కండి',
    'hi': 'रोकने के लिए दबाएं',
  };

  static const Map<String, String> readyToListen = {
    'en': 'Ready to listen',
    'te': 'నేను వినడానికి సిద్ధంగా ఉన్నాను',
    'hi': 'मैं सुनने के लिए तैयार हूँ',
  };

  static const Map<String, String> trySaying = {
    'en': 'Try saying:',
    'te': 'ఉదాహరణ మాటలు:',
    'hi': 'आप कह सकते हैं:',
  };

  // --- Feedbacks ---

  static const Map<String, String> heardPrefix = {
    'en': 'I heard:',
    'te': 'నేను విన్నది:',
    'hi': 'मैंने सुना:',
  };

  static const Map<String, String> notUnderstood = {
    'en': 'I didn\'t understand that. Please try speaking again.',
    'te': 'అర్థం కాలేదు. దయచేసి మళ్ళీ మాట్లాడండి.',
    'hi': 'समझ नहीं पाए। कृपया दोबारा बोलें।',
  };

  static const Map<String, String> openingJournal = {
    'en': 'Opening your Journal...',
    'te': 'మీ డైరీ తెరవబడుతోంది...',
    'hi': 'आपकी यादों की डायरी खुल रही है...',
    'as': 'আপোনাৰ স্মৃতিসমূহ খুলి থকা হৈছে...',
    'bn': 'আপনার স্মৃতিগুলো খোলা হচ্ছে...',
  };

  static const Map<String, String> creatingMemory = {
    'en': 'Opening New Memory...',
    'te': 'కొత్త జ్ఞాపకం తెరవబడుతోంది...',
    'hi': 'नई याद का पृष्ठ खुल रहा है...',
    'as': 'নতুন স্মৃতি যোগ কৰক...',
    'bn': 'নতুন স্মৃতি যোগ করুন...',
  };

  static const Map<String, String> openingDashboard = {
    'en': 'Going back Home...',
    'te': 'హోమ్ పేజీకి వెళ్తున్నాము...',
    'hi': 'होम पेज पर वापस जा रहे हैं...',
    'as': 'ঘৰলৈ উভతి যোৱా হৈছে...',
    'bn': 'হোমে ফিরে যাওয়া হচ্ছে...',
  };

  static const Map<String, String> openingGames = {
    'en': 'Opening Games...',
    'te': 'ఆటల పేజీకి వెళ్తున్నాము...',
    'hi': 'खेलों के पेज पर जा रहे हैं...',
    'as': 'খেল আৰম্ভ কৰా হৈছে...',
    'bn': 'খেলা শুরু হচ্ছে...',
  };

  static const Map<String, String> openingReminders = {
    'en': 'Opening Reminders...',
    'te': 'రిమైండర్లు తెరవబడుతున్నాయి...',
    'hi': 'रिमाइंडर खुल रहे हैं...',
    'as': 'ৰিমাইণ্ডাৰ খোলা হৈছে...',
    'bn': 'রিমাইন্ডার খোলা হচ্ছে...',
  };

  static const Map<String, String> openingSettings = {
    'en': 'Opening Settings...',
    'te': 'సెట్టింగ్‌లు తెరవబడుతున్నాయి...',
    'hi': 'सेटिंग्स खुल रही हैं...',
    'as': 'ছেটিংছ খোলা হৈছে...',
    'bn': 'সেটিংস খোলা হচ্ছে...',
  };

  static const Map<String, String> openingProfile = {
    'en': 'Opening Profile...',
    'te': 'ప్రొఫైల్ తెరవబడుతోంది...',
    'hi': 'प्रोफ़ाइल खुल रही है...',
    'as': 'প্ৰফাইল খোলা হৈছে...',
    'bn': 'প্রোফাইল খোলা হচ্ছে...',
  };

  static const Map<String, String> permissionDenied = {
    'en': 'Microphone permission is needed for voice commands. You can still use Smriti AI without voice.',
    'te': 'వాయిస్ కమాండ్ల కోసం మైక్రోఫోన్ అనుమతి అవసరం. మీరు బటన్లను ఉపయోగించవచ్చు.',
    'hi': 'आवाज़ पहचान के लिए माइक्रोफ़ोन की अनुमति आवश्यक है। आप बटनों का उपयोग कर सकते हैं।',
  };

  static const Map<String, String> speechUnavailable = {
    'en': 'Voice commands are not available right now. You can continue using the buttons.',
    'te': 'ఈ పరికరంలో వాయిస్ సేవ అందుబాటులో లేదు. మీరు బటన్లను ఉపయోగించవచ్చు.',
    'hi': 'इस डिवाइस पर आवाज़ सेवा उपलब्ध नहीं है। आप बटनों का उपयोग कर सकते हैं।',
  };

  // --- Reminders Voice Prompts ---

  static const Map<String, String> creatingReminder = {
    'en': 'Setting your reminder...',
    'te': 'రిమైండర్ సెట్ చేస్తున్నాము...',
    'hi': 'रिमाइंडर सेट किया जा रहा है...',
  };

  static const Map<String, String> reminderCreated = {
    'en': 'Okay, I have created your reminder.',
    'te': 'సరే, మీ రిమైండర్ సేవ్ చేయబడింది.',
    'hi': 'ठीक है, आपका रिमाइंडर सेट कर दिया गया है।',
  };

  static const Map<String, String> reminderSavedNoNotification = {
    'en': 'Your reminder was saved, but I couldn\'t schedule its notification.',
    'te': 'మీ రిమైండర్ సేవ్ చేయబడింది, కానీ నోటిఫికేషన్ షెడ్యూల్ చేయడం సాధ్యం కాలేదు.',
    'hi': 'आपका रिमाइंडर सेव हो गया है, लेकिन नोटिफिकेशन शेड्यूल नहीं हो सका।',
  };

  static const Map<String, String> reminderFailed = {
    'en': 'I couldn\'t set the reminder right now. Please try again.',
    'te': 'ప్రస్తుతం రిమైండర్ సెట్ చేయడం సాధ్యం కాలేదు. దయచేసి మళ్ళీ ప్రయత్నించండి.',
    'hi': 'अभी रिमाइंडर सेट नहीं किया जा सका। कृपया दोबारा प्रयास करें।',
  };

  static const Map<String, String> speaking = {
    'en': 'Smriti is speaking...',
    'te': 'స్మృతి మాట్లాడుతోంది...',
    'hi': 'स्मृति बोल रही हैं...',
  };

  static const Map<String, String> reminderUpdated = {
    'en': 'Your reminder has been updated.',
    'te': 'మీ రిమైండర్ నవీకరించబడింది.',
    'hi': 'आपका रिमाइंडर अपडेट कर दिया गया है।',
  };

  static const Map<String, String> reminderDeleted = {
    'en': 'Your reminder has been deleted.',
    'te': 'రిమైండర్ తొలగించబడింది.',
    'hi': 'रिमाइंडर हटा दिया गया है।',
  };

  static const Map<String, String> askReminderTitle = {
    'en': 'What would you like me to remind you about?',
    'te': 'మీకు ఏ విషయం గురించి గుర్తు చేయాలి?',
    'hi': 'आप किस बारे में रिमाइंडर लगाना चाहते हैं?',
  };

  static const Map<String, String> askReminderTime = {
    'en': 'When should I remind you?',
    'te': 'ఏ సమయంలో గుర్తు చేయాలి?',
    'hi': 'किस समय का रिमाइंडर लगाना है?',
  };

  static const Map<String, String> askReminderDate = {
    'en': 'Which day should I remind you?',
    'te': 'ఏ రోజున గుర్తు చేయాలి?',
    'hi': 'किस तारीख का रिमाइंडर लगाना है?',
  };

  static const Map<String, String> invalidReminderTime = {
    'en': 'Please tell me a valid time, like 8 PM or tomorrow morning.',
    'te': 'దయచేసి సరైన సమయాన్ని చెప్పండి, ఉదాహరణకు సాయంత్రం 8 గంటలు లేదా రేపు ఉదయం.',
    'hi': 'कृपया सही समय बताएं, जैसे शाम 8 बजे या कल सुबह।',
  };

  static const Map<String, String> reminderCancelled = {
    'en': 'Reminder creation cancelled.',
    'te': 'రిమైండర్ రద్దు చేయబడింది.',
    'hi': 'रिमाइंडर रद्द कर दिया गया।',
  };

  static const Map<String, String> confirmSaveReminder = {
    'en': 'Should I save this reminder?',
    'te': 'ఈ రిమైండర్‌ను సేవ్ చేయమంటారా?',
    'hi': 'क्या मैं इस रिमाइंडर को सहेज लूँ?',
  };

  static const Map<String, String> yesNoCancelHelp = {
    'en': 'Say Yes to save, or No to cancel.',
    'te': 'సేవ్ చేయడానికి "అవును" అని, లేదా రద్దు చేయడానికి "వద్దు" అని చెప్పండి.',
    'hi': 'सहेजने के लिए "हाँ" कहें, या रद्द करने के लिए "नहीं" कहें।',
  };

  /// Constructs a clear conversational confirmation prompt for a reminder.
  static String formatConfirmationPrompt({
    required String title,
    required String timeStr,
    required String dateStr,
    required String languageCode,
  }) {
    switch (languageCode) {
      case 'te':
        return 'నేను $dateStr $timeStr సమయంలో "$title" గురించి గుర్తు చేస్తాను. ఈ రిమైండర్‌ను సేవ్ చేయమంటారా?';
      case 'hi':
        return 'मैं $dateStr $timeStr को "$title" के लिए याद दिलाऊँगा। क्या मैं इस रिमाइंडर को सहेज लूँ?';
      case 'en':
      default:
        return 'I will remind you $dateStr at $timeStr to $title. Should I save this reminder?';
    }
  }

  // --- Privacy & Engine Declarations ---

  static const Map<String, String> privacyStatement = {
    'en': 'Smriti AI does not record, save, or upload your voice recordings. Speech recognition is handled by your device\'s speech service.',
    'te': 'స్మృతి AI మీ వాయిస్ రికార్డింగ్‌లను సేవ్ చేయదు లేదా అప్‌లోడ్ చేయదు. మీ పరికర వాయిస్ సేవ ద్వారా వాయిస్ గుర్తించబడుతుంది.',
    'hi': 'स्मृति AI आपकी आवाज़ रिकॉर्ड या अपलोड नहीं करता है। आवाज़ पहचान आपके डिवाइस द्वारा की जाती है।',
  };

  static const Map<String, String> offlineClarification = {
    'en': 'Whether speech recognition works offline depends on your device and installed language support.',
    'te': 'వాయిస్ గుర్తింపు ఆఫ్‌లైన్‌లో పనిచేస్తుందా లేదా అనేది మీ పరికరం మరియు భాషా మద్దతుపై ఆధారపడి ఉంటుంది.',
    'hi': 'आवाज़ पहचान ऑफ़लाइन काम करेगी या नहीं यह आपके डिवाइस पर निर्भर करता है।',
  };

  static String get(Map<String, String> map, String languageCode) {
    return map[languageCode] ?? map['en'] ?? '';
  }
}
