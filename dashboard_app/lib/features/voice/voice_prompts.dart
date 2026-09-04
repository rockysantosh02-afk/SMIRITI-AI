/// Pre-authored, elderly-calm multilingual strings for Smriti AI Voice Assistant.
///
/// NOTE FOR TEAM: All non-English strings are culturally reviewed for North-East Indian
/// elders (Assam, Bengal) and Hindi speakers.
class VoicePrompts {
  VoicePrompts._();

  // --- UI States ---

  static const Map<String, String> tapToSpeak = {
    'as': 'কোৱাৰ বাবে টিপক (Tap to Speak)',
    'bn': 'কথা বলার জন্য চাপুন (Tap to Speak)',
    'hi': 'बोलने के लिए दबाएं (Tap to Speak)',
    'en': 'Tap to Speak',
  };

  static const Map<String, String> listening = {
    'as': 'শুনি থকা হৈছে... কোৱা শেষ হ\'লে থামিব (Listening...)',
    'bn': 'শুনছি... কথা বলা শেষ হলে থামবে (Listening...)',
    'hi': 'सुन रहे हैं... बोलना समाप्त होने पर रुकेंगे (Listening...)',
    'en': 'Listening... Speak clearly',
  };

  static const Map<String, String> processing = {
    'as': 'বুজিবলৈ চেষ্টা কৰা হৈছে... (Understanding...)',
    'bn': 'বোঝার চেষ্টা করছি... (Understanding...)',
    'hi': 'समझने का प्रयास कर रहे हैं... (Understanding...)',
    'en': 'Understanding...',
  };

  static const Map<String, String> tapToStop = {
    'as': 'থামিবলৈ টিপক (Tap to Stop)',
    'bn': 'থামানোর জন্য চাপুন (Tap to Stop)',
    'hi': 'रोकने के लिए दबाएं (Tap to Stop)',
    'en': 'Tap to Stop',
  };

  // --- Feedbacks ---

  static const Map<String, String> heardPrefix = {
    'as': 'মই শুনিলোঁ:',
    'bn': 'আমি শুনেছি:',
    'hi': 'मैंने सुना:',
    'en': 'I heard:',
  };

  static const Map<String, String> notUnderstood = {
    'as': 'বুজি নাপালোঁ। অনুগ্ৰহ কৰি পুনৰ কওক।\n(I didn\'t understand that. Please try again.)',
    'bn': 'বুঝতে পারিনি। দয়া করে আবার বলুন।\n(I didn\'t understand that. Please try again.)',
    'hi': 'समझ नहीं पाए। कृपया दोबारा बोलें।\n(I didn\'t understand that. Please try again.)',
    'en': 'I didn\'t understand that. Please try speaking again.',
  };

  static const Map<String, String> openingJournal = {
    'as': 'আপোনাৰ স্মৃতি ডায়েরী খোলা হৈছে... (Opening your Journal...)',
    'bn': 'আপনার স্মৃতির ডায়েরি খোলা হচ্ছে... (Opening your Journal...)',
    'hi': 'आपकी यादों की डायरी खुल रही है... (Opening your Journal...)',
    'en': 'Opening your Journal...',
  };

  static const Map<String, String> creatingMemory = {
    'as': 'নতুন স্মৃতি লিখাৰ পৃষ্ঠা খোলা হৈছে... (Opening New Memory...)',
    'bn': 'নতুন স্মৃতি লেখার পাতা খোলা হচ্ছে... (Opening New Memory...)',
    'hi': 'नई याद लिखने का पृष्ठ खुल रहा है... (Opening New Memory...)',
    'en': 'Opening New Memory...',
  };

  static const Map<String, String> openingDashboard = {
    'as': 'মূল পৃষ্ঠালৈ ঘূৰি যোৱা হৈছে... (Going to Home...)',
    'bn': 'মূল পাতায় ফিরে যাওয়া হচ্ছে... (Going to Home...)',
    'hi': 'होम पेज पर वापस जा रहे हैं... (Going to Home...)',
    'en': 'Going back Home...',
  };

  static const Map<String, String> openingGames = {
    'as': 'খেলৰ পৃষ্ঠালৈ যোৱা হৈছে... (Opening Games...)',
    'bn': 'খেলার পাতায় যাওয়া হচ্ছে... (Opening Games...)',
    'hi': 'खेलों के पेज पर जा रहे हैं... (Opening Games...)',
    'en': 'Opening Games...',
  };

  static const Map<String, String> openingReminders = {
    'as': 'ৰিমাইণ্ডাৰ খোলা হৈছে... (Opening Reminders...)',
    'bn': 'অনুস্মারক খোলা হচ্ছে... (Opening Reminders...)',
    'hi': 'रिमाइंडर खुल रहे हैं... (Opening Reminders...)',
    'en': 'Opening Reminders...',
  };

  static const Map<String, String> remindersNotice = {
    'as': 'ৰিমাইণ্ডাৰ অতি সোনকালে উপলব্ধ হ\'ব।\n(Reminders will be available soon.)',
    'bn': 'অনুস্মারক খুব শীঘ্রই উপলব্ধ হবে।\n(Reminders will be available soon.)',
    'hi': 'रिमाइंडर जल्द ही उपलब्ध होंगे।\n(Reminders will be available soon.)',
    'en': 'Reminders will be available soon in an upcoming update.',
  };

  static const Map<String, String> permissionDenied = {
    'as': 'মাইক্ৰ\'ফনৰ অনুমতি প্ৰয়োজন। আপুনি ভইচ কমাণ্ড নোহোৱাকৈও Smriti AI ব্যৱহাৰ কৰিব পাৰে।',
    'bn': 'মাইক্রোফোনের অনুমতি প্রয়োজন। আপনি ভয়েস কমান্ড ছাড়াও Smriti AI ব্যবহার করতে পারেন।',
    'hi': 'माइक्रोफ़ोन की अनुमति चाहिए। आप बिना आवाज़ के भी Smriti AI का उपयोग कर सकते हैं।',
    'en': 'Microphone permission is needed for voice commands. You can still use Smriti AI without voice.',
  };

  static const Map<String, String> speechUnavailable = {
    'as': 'এই ডিভাইচত ভইচ সেৱা উপলব্ধ নহয়। আপুনি বুটামবোৰ ব্যৱহাৰ কৰিব পাৰে।',
    'bn': 'এই ডিভাইসে ভয়েস সেবা উপলব্ধ নেই। আপনি বোতামগুলো ব্যবহার করতে পারেন।',
    'hi': 'इस डिवाइस पर आवाज़ सेवा उपलब्ध नहीं है। आप बटनों का उपयोग कर सकते हैं।',
    'en': 'Voice commands are not available right now. You can continue using the buttons.',
  };

  // --- Privacy & Engine Declarations ---

  static const Map<String, String> privacyStatement = {
    'as': 'Smriti AI-য়ে আপোনাৰ মাত বা কণ্ঠ বাৰ্তা সংৰক্ষণ বা আপলোড নকৰে। কণ্ঠ চিনাক্তকৰণ আপোনাৰ ডিভাইচৰ ভইচ সেৱাৰ দ্বাৰা কৰা হয়।',
    'bn': 'Smriti AI আপনার ভয়েস রেকর্ড, সংরক্ষণ বা আপলোড করে না। ভয়েস শনাক্তকরণ আপনার ডিভাইসের ভয়েস পরিষেবা দ্বারা পরিচালিত হয়।',
    'hi': 'Smriti AI आपकी आवाज़ को रिकॉर्ड, सहेज या अपलोड नहीं करता है। आवाज़ पहचान आपके डिवाइस की सेवा द्वारा नियंत्रित की जाती है।',
    'en': 'Smriti AI does not record, save, or upload your voice recordings. Speech recognition is handled by your device\'s speech service.',
  };

  static const Map<String, String> offlineClarification = {
    'as': 'কণ্ঠ চিনাক্তকৰণ অফলাইনত কাম কৰিব নে নকৰে সেয়া আপোনাৰ ডিভাইচ আৰু ইনষ্টল কৰা ভাষা সমৰ্থনৰ ওপৰত নিৰ্ভৰ কৰে।',
    'bn': 'ভয়েস শনাক্তকরণ অফলাইনে কাজ করবে কিনা তা আপনার ডিভাইস এবং ইনস্টল করা ভাষার সমর্থনের ওপর নির্ভর করে।',
    'hi': 'आवाज़ पहचान ऑफ़लाइन काम करेगी या नहीं यह आपके डिवाइस और इंस्टॉल की गई भाषा सहायता पर निर्भर करता है।',
    'en': 'Whether speech recognition works offline depends on your device and installed language support.',
  };

  static String get(Map<String, String> map, String languageCode) {
    return map[languageCode] ?? map['en'] ?? '';
  }
}
