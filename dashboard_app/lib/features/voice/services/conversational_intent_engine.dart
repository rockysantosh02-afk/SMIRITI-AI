/// Intent categories for supportive elderly conversation
enum ConversationalIntent {
  happiness,
  sadness,
  loneliness,
  excitement,
  worry,
  missingSomeone,
  familyNews,
  memories,
  achievement,
  travel,
  celebration,
  dailyActivities,
  healthConcerns,
  gratitude,
  frustration,
  confusion,
  greeting,
  farewell,
  unknown,
}

/// Analysis result from conversational intent detection
class ConversationalIntentResult {
  final ConversationalIntent intent;
  final String categoryName;
  final Map<String, dynamic> extractedContext;

  const ConversationalIntentResult({
    required this.intent,
    required this.categoryName,
    this.extractedContext = const {},
  });
}

/// Context-aware conversational intent detector and response generator.
///
/// Designed specifically for elderly users:
/// - Warm, respectful, empathetic tone
/// - Non-diagnostic, non-medical
/// - Never impersonates family members or real people
/// - Generates natural, context-rich responses with engaging follow-up questions
/// - Multilingual: English, Telugu, Hindi
class ConversationalIntentEngine {
  const ConversationalIntentEngine();

  /// Detect intent and context from user utterance
  ConversationalIntentResult detect(String rawText) {
    final clean = rawText.toLowerCase().trim();

    final hasFamilyWord = clean.contains('daughter') ||
        clean.contains('son') ||
        clean.contains('child') ||
        clean.contains('grandson') ||
        clean.contains('granddaughter') ||
        clean.contains('కూతురు') ||
        clean.contains('కొడుకు') ||
        clean.contains('మనవడు') ||
        clean.contains('మనవరాలు') ||
        clean.contains('बेटी') ||
        clean.contains('बेटा') ||
        clean.contains('पोता') ||
        clean.contains('पोती');

    final hasStudyWord = clean.contains('higher studies') ||
        clean.contains('studies') ||
        clean.contains('study') ||
        clean.contains('college') ||
        clean.contains('university') ||
        clean.contains('చదువు') ||
        clean.contains('కాలేజీ') ||
        clean.contains('पढ़ाई') ||
        clean.contains('कॉलेज');

    final hasAbroadWord = clean.contains('usa') ||
        clean.contains('america') ||
        clean.contains('abroad') ||
        clean.contains('foreign') ||
        clean.contains('us') ||
        clean.contains('వేరే దేశం') ||
        clean.contains('అమెరికా') ||
        clean.contains('विदेश') ||
        clean.contains('अमेरिका');

    // 1. Family news with studies / going abroad (Special priority for milestone news)
    if (hasFamilyWord && (hasAbroadWord || hasStudyWord || clean.contains('called me') || clean.contains('calling'))) {
      return ConversationalIntentResult(
        intent: ConversationalIntent.familyNews,
        categoryName: 'family_news',
        extractedContext: {
          'isAbroad': hasAbroadWord,
          'isStudies': hasStudyWord,
          'isCall': clean.contains('called') || clean.contains('phone'),
          'relation': clean.contains('daughter') || clean.contains('కూతురు') || clean.contains('बेटी')
              ? 'daughter'
              : (clean.contains('son') || clean.contains('కొడుకు') || clean.contains('बेटा') ? 'son' : 'family'),
        },
      );
    }

    // 2. Loneliness
    if (clean.contains('lonely') ||
        clean.contains('alone') ||
        clean.contains('nobody with me') ||
        clean.contains('no one to talk') ||
        clean.contains('ఒంటరి') ||
        clean.contains('ఎవరూ లేరు') ||
        clean.contains('अकेला') ||
        clean.contains('अकेली') ||
        clean.contains('कोई नहीं है')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.loneliness,
        categoryName: 'loneliness',
      );
    }

    // 3. Missing someone
    if (clean.contains('miss') ||
        clean.contains('missing') ||
        clean.contains('గుర్తుకొస్తున్నారు') ||
        clean.contains('గుర్తొస్తున్నారు') ||
        clean.contains('याद आ रही') ||
        clean.contains('याद आते')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.missingSomeone,
        categoryName: 'missing_someone',
      );
    }

    // 4. Sadness
    if (clean.contains('sad') ||
        clean.contains('unhappy') ||
        clean.contains('crying') ||
        clean.contains('tears') ||
        clean.contains('బాధ') ||
        clean.contains('దుఃఖం') ||
        clean.contains('ఉదాసీనత') ||
        clean.contains('उदास') ||
        clean.contains('दुखी') ||
        clean.contains('दुख')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.sadness,
        categoryName: 'sadness',
      );
    }

    // 5. Worry / Anxiety
    if (clean.contains('worry') ||
        clean.contains('worried') ||
        clean.contains('anxious') ||
        clean.contains('nervous') ||
        clean.contains('scared') ||
        clean.contains('ఆందోళన') ||
        clean.contains('భయం') ||
        clean.contains('దిగులు') ||
        clean.contains('चिंता') ||
        clean.contains('घबराहट') ||
        clean.contains('परेशान')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.worry,
        categoryName: 'worry',
      );
    }

    // 6. Excitement
    if (clean.contains('excited') ||
        clean.contains('exciting') ||
        clean.contains('thrilled') ||
        clean.contains('ఉత్సాహం') ||
        clean.contains('ఆత్రుత') ||
        clean.contains('उत्साहित') ||
        clean.contains('रोमांचित')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.excitement,
        categoryName: 'excitement',
      );
    }

    // 7. Happiness / Joy
    if (clean.contains('very happy') ||
        clean.contains('happy') ||
        clean.contains('glad') ||
        clean.contains('joy') ||
        clean.contains('wonderful day') ||
        clean.contains('good day') ||
        clean.contains('చాలా సంతోషం') ||
        clean.contains('సంతోషం') ||
        clean.contains('ఆనందం') ||
        clean.contains('బాగుంది') ||
        clean.contains('बहुत खुश') ||
        clean.contains('खुश') ||
        clean.contains('प्रसन्न') ||
        clean.contains('अच्छा दिन')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.happiness,
        categoryName: 'happiness',
      );
    }

    // 8. Achievements
    if (clean.contains('achievement') ||
        clean.contains('won') ||
        clean.contains('award') ||
        clean.contains('passed') ||
        clean.contains('success') ||
        clean.contains('గెలిచారు') ||
        clean.contains('విజయం') ||
        clean.contains('జీతా') ||
        clean.contains('सफलता') ||
        clean.contains('इनाम')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.achievement,
        categoryName: 'achievement',
      );
    }

    // 9. Travel
    if (clean.contains('travel') ||
        clean.contains('trip') ||
        clean.contains('journey') ||
        clean.contains('train') ||
        clean.contains('flight') ||
        clean.contains('tour') ||
        clean.contains('ప్రయాణం') ||
        clean.contains('ట్రిప్') ||
        clean.contains('यात्रा') ||
        clean.contains('सफर')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.travel,
        categoryName: 'travel',
      );
    }

    // 10. Celebrations
    if (clean.contains('birthday') ||
        clean.contains('anniversary') ||
        clean.contains('festival') ||
        clean.contains('celebration') ||
        clean.contains('పుట్టినరోజు') ||
        clean.contains('పండుగ') ||
        clean.contains('వేడుక') ||
        clean.contains('जन्मदिन') ||
        clean.contains('सालगिरह') ||
        clean.contains('त्योहार') ||
        clean.contains('उत्सव')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.celebration,
        categoryName: 'celebration',
      );
    }

    // 11. Memories / Reminiscence
    if (clean.contains('remember') ||
        clean.contains('old days') ||
        clean.contains('childhood') ||
        clean.contains('past') ||
        clean.contains('జ్ఞాపకాలు') ||
        clean.contains('గతంలో') ||
        clean.contains('పాత రోజులు') ||
        clean.contains('याद है') ||
        clean.contains('बचपन') ||
        clean.contains('पुराने दिन')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.memories,
        categoryName: 'memories',
      );
    }

    // 12. Health concerns (Supportive non-medical)
    if (clean.contains('doctor') ||
        clean.contains('pain') ||
        clean.contains('tired') ||
        clean.contains('knee') ||
        clean.contains('headache') ||
        clean.contains('నొప్పి') ||
        clean.contains('అలసట') ||
        clean.contains('వైద్యుడు') ||
        clean.contains('दर्द') ||
        clean.contains('थकान') ||
        clean.contains('डॉक्टर')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.healthConcerns,
        categoryName: 'health_concerns',
      );
    }

    // 13. Gratitude
    if (clean.contains('thank you') ||
        clean.contains('thanks') ||
        clean.contains('grateful') ||
        clean.contains('ధన్యవాదాలు') ||
        clean.contains('కృతజ్ఞతలు') ||
        clean.contains('धन्यवाद') ||
        clean.contains('शुक्रिया')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.gratitude,
        categoryName: 'gratitude',
      );
    }

    // 14. Frustration
    if (clean.contains('frustrated') ||
        clean.contains('angry') ||
        clean.contains('irritated') ||
        clean.contains('కోపం') ||
        clean.contains('చిరాకు') ||
        clean.contains('गुस्सा') ||
        clean.contains('चिढ़')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.frustration,
        categoryName: 'frustration',
      );
    }

    // 15. Confusion
    if (clean.contains('confused') ||
        clean.contains('forgot') ||
        clean.contains('don\'t know') ||
        clean.contains('గందరగోళం') ||
        clean.contains('మర్చిపోయాను') ||
        clean.contains('उलझन') ||
        clean.contains('भूल गया')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.confusion,
        categoryName: 'confusion',
      );
    }

    // 16. Daily Activities
    if (clean.contains('tea') ||
        clean.contains('walk') ||
        clean.contains('garden') ||
        clean.contains('market') ||
        clean.contains('temple') ||
        clean.contains('cooked') ||
        clean.contains('టీ') ||
        clean.contains('నడక') ||
        clean.contains('తోట') ||
        clean.contains('గుడి') ||
        clean.contains('चाय') ||
        clean.contains('टहलना') ||
        clean.contains('बगीचा') ||
        clean.contains('मंदिर')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.dailyActivities,
        categoryName: 'daily_activities',
      );
    }

    // 17. Greetings
    if (clean.contains('how are you') ||
        clean.contains('hello') ||
        clean.contains('good morning') ||
        clean.contains('good afternoon') ||
        clean.contains('good evening') ||
        clean.contains('నమస్కారం') ||
        clean.contains('ఎలా ఉన్నారు') ||
        clean.contains('नमस्ते') ||
        clean.contains('कैसे हैं')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.greeting,
        categoryName: 'greeting',
      );
    }

    // 18. Farewell
    if (clean.contains('goodbye') ||
        clean.contains('bye') ||
        clean.contains('good night') ||
        clean.contains('వెళ్లొస్తాను') ||
        clean.contains('శుభరాత్రి') ||
        clean.contains('अलविदा') ||
        clean.contains('शुभ रात्रि')) {
      return const ConversationalIntentResult(
        intent: ConversationalIntent.farewell,
        categoryName: 'farewell',
      );
    }

    return const ConversationalIntentResult(
      intent: ConversationalIntent.unknown,
      categoryName: 'unknown',
    );
  }

  /// Generates a warm, supportive, context-aware response for the detected intent
  String generateResponse({
    required ConversationalIntentResult analysis,
    required String userText,
    required String languageCode,
  }) {
    final lang = languageCode.toLowerCase().trim();

    switch (analysis.intent) {
      case ConversationalIntent.familyNews:
        return _generateFamilyNewsResponse(analysis, lang);

      case ConversationalIntent.happiness:
        switch (lang) {
          case 'te':
            return 'మీరు సంతోషంగా ఉన్నారని తెలిసి నాకు ఎంతో ఆనందంగా ఉంది! ఈ రోజు అంత సంతోషాన్ని ఇచ్చిన ఆ ప్రత్యేక విషయం ఏమిటి?';
          case 'hi':
            return 'यह सुनकर बहुत अच्छा लगा कि आप खुश हैं! आज ऐसा क्या खास हुआ जिसने आपका दिन इतना खुशनुमा बना दिया?';
          default:
            return 'That\'s wonderful to hear! What happened today that made you so happy?';
        }

      case ConversationalIntent.sadness:
        switch (lang) {
          case 'te':
            return 'ఈ రోజు మీరు బాధగా ఉన్నందుకు నాకు చింతగా ఉంది. మీ మనసులో ఉన్న భావాలను పంచుకోవడానికి నేను ఇక్కడే ఉన్నాను. ఏ విషయం మిమ్మల్ని బాధపెడుతోందో నాతో చెబుతారా?';
          case 'hi':
            return 'मुझे दुख है कि आज आपका मन उदास है। मैं आपकी बात सुनने के लिए हमेशा यहाँ हूँ। क्या आप बताना चाहेंगे कि आपके मन में क्या चल रहा है?';
          default:
            return 'I am sorry you are feeling down today. I am right here with you. Would you like to share what has been on your mind?';
        }

      case ConversationalIntent.loneliness:
        switch (lang) {
          case 'te':
            return 'ఒంటరిగా అనిపించినప్పుడు సమయం భారంగా అనిపిస్తుంది. కానీ మీరు ఎప్పుడూ ఒంటరి కాదు, మీతో మాట్లాడటానికి నేను ఎల్లప్పుడూ సిద్ధంగా ఉన్నాను. మీ మనసులో ఏముందో నాతో చెబుతారా?';
          case 'hi':
            return 'अकेलापन महसूस होना स्वाभाविक है, पर याद रखिए कि आप अकेले नहीं हैं। मैं हमेशा आपकी बात सुनने के लिए तैयार हूँ। क्या आप अपने मन की कोई बात साझा करना चाहेंगे?';
          default:
            return 'I\'m sorry today feels lonely. I\'m here to listen. Would you like to tell me what has been on your mind?';
        }

      case ConversationalIntent.missingSomeone:
        switch (lang) {
          case 'te':
            return 'మనకు బాగా ఇష్టమైన వారిని మిస్ అవ్వడం చాలా సహజం. వారితో గడిపిన అందమైన క్షణాలు ఎప్పటికీ మన హృదయంలో ఉంటాయి. వారి గురించి ఏదైనా మధురమైన జ్ఞాపకాన్ని చెబుతారా?';
          case 'hi':
            return 'अपनों की याद आना बहुत स्वाभाविक है। उनके साथ बिताए पल हमेशा दिल के करीब रहते हैं। क्या आप उनसे जुड़ी कोई प्यारी याद बताना चाहेंगे?';
          default:
            return 'Missing someone you love is such a tender feeling. The memories you share with them are always close to your heart. Would you like to tell me about a sweet memory with them?';
        }

      case ConversationalIntent.worry:
        switch (lang) {
          case 'te':
            return 'ఆందోళన కలగడం సహజమే. ఒకసారి దీర్ఘంగా శ్వాస తీసుకోండి. ఏ విషయం గురించి ఎక్కువగా ఆలోచిస్తున్నారో నాతో నిదానంగా చెప్పండి.';
          case 'hi':
            return 'चिंता होना स्वाभाविक है। एक गहरी साँस लीजिए, सब ठीक होगा। किस बात को लेकर आपका मन परेशान है?';
          default:
            return 'It is completely natural to feel worried sometimes. Take a gentle breath. What is causing you concern right now?';
        }

      case ConversationalIntent.excitement:
        switch (lang) {
          case 'te':
            return 'వావ్, మీ ఉత్సాహం చూస్తుంటే నాకు కూడా ఎంతో సంతోషంగా ఉంది! ఆ ఆనందకరమైన విశేషాల గురించి పూర్తిగా వినాలనుకుంటున్నాను.';
          case 'hi':
            return 'वाह, आपका उत्साह देखकर मुझे भी बहुत खुशी हो रही है! इस रोमांचक खबर के बारे में मुझे भी थोड़ा विस्तार से बताएं।';
          default:
            return 'That is so exciting! Your positive energy is contagious. Tell me all about what happened!';
        }

      case ConversationalIntent.achievement:
        switch (lang) {
          case 'te':
            return 'అభినందనలు! ఇది ఎంతో గర్వించదగ్గ గొప్ప విజయం. ఈ విజయం వెనుక ఉన్న శ్రమ మరియు ప్రయాణం గురించి నాతో పంచుకుంటారా?';
          case 'hi':
            return 'बहुत-बहुत बधाई! यह सच में गर्व का क्षण है। इस सफलता के बारे में थोड़ा और बताइए।';
          default:
            return 'Congratulations! That is a remarkable achievement to be proud of. How does it feel to celebrate this milestone?';
        }

      case ConversationalIntent.travel:
        switch (lang) {
          case 'te':
            return 'కొత్త ప్రదేశాలకు ప్రయాణం చేయడం ఎల్లప్పుడూ కొత్త అనుభవాలను తెస్తుంది. మీ ప్రయాణంలో మీరు ఏమేమి చూడాలని ఎదురుచూస్తున్నారు?';
          case 'hi':
            return 'यात्रा करना हमेशा मन को तरोताजा कर देता है। आप इस यात्रा में क्या-क्या देखने की योजना बना रहे हैं?';
          default:
            return 'Traveling brings such wonderful new memories. What are you looking forward to seeing the most on this journey?';
        }

      case ConversationalIntent.celebration:
        switch (lang) {
          case 'te':
            return 'వేడుకలు మరియు పండుగలు కుటుంబంతో గడపడానికి ఎంతో అనువైన సమయం. మీ సంబరాలు ఎలా జరుగుతున్నాయి?';
          case 'hi':
            return 'उत्सव और त्योहार जीवन में खुशियों के रंग भर देते हैं। आप इस खास दिन को कैसे मना रहे हैं?';
          default:
            return 'Celebrations bring such warmth and joy! How are you and your family planning to celebrate this special day?';
        }

      case ConversationalIntent.memories:
        switch (lang) {
          case 'te':
            return 'గత జ్ఞాపకాలను నెమరువేసుకోవడం ఎంతో మధురమైన అనుభూతిని ఇస్తుంది. ఆ రోజుల నాటి విశేషాలు వినడం నాకు చాలా ఆసక్తిగా ఉంటుంది.';
          case 'hi':
            return 'पुरानी यादों को याद करना मन को बहुत शांति देता है। उस समय का कोई खास किस्सा मुझे भी सुनाइए।';
          default:
            return 'Reminiscing about precious memories is so heartwarming. What is your fondest memory from those times?';
        }

      case ConversationalIntent.dailyActivities:
        switch (lang) {
          case 'te':
            return 'అది చాలా మంచి దినచర్య! ప్రశాంతంగా రోజువారీ పనులు చేసుకోవడం ఆరోగ్యానికి ఎంతో మేలు చేస్తుంది. తర్వాత ఇంకేం చేయాలని ఆలోచిస్తున్నారు?';
          case 'hi':
            return 'यह तो बहुत अच्छी दिनचर्या है! सुकून से समय बिताना सेहत के लिए बहुत अच्छा होता है। इसके बाद आपका क्या करने का विचार है?';
          default:
            return 'That sounds like a lovely part of your day! Taking time for everyday routines is so grounding. What else do you have planned today?';
        }

      case ConversationalIntent.healthConcerns:
        switch (lang) {
          case 'te':
            return 'మీ ఆరోగ్యం గురించి శ్రద్ధ వహించడం చాలా ముఖ్యం. దయచేసి శరీరానికి తగిన విశ్రాంతి ఇవ్వండి, అవసరమైతే వైద్యులను సంప్రదించండి. ఇప్పుడు ఎలా అనిపిస్తోంది?';
          case 'hi':
            return 'सेहत का ध्यान रखना सबसे जरूरी है। कृपया थोड़ा आराम करें और जरूरत हो तो डॉक्टर से सलाह लें। अभी आप कैसा महसूस कर रहे हैं?';
          default:
            return 'Taking good care of your health and body is so important. Please make sure to get plenty of gentle rest. How are you feeling right at this moment?';
        }

      case ConversationalIntent.gratitude:
        switch (lang) {
          case 'te':
            return 'మీ ప్రేమపూర్వక మాటలకు ధన్యవాదాలు. మీతో మాట్లాడటం నాకు ఎల్లప్పుడూ ఎంతో ఆనందాన్ని ఇస్తుంది!';
          case 'hi':
            return 'आपके स्नेहभरे शब्दों के लिए बहुत धन्यवाद। आपसे बात करके मुझे हमेशा बेहद खुशी होती है!';
          default:
            return 'You are so very welcome. It is truly a pleasure chatting with you!';
        }

      case ConversationalIntent.frustration:
        switch (lang) {
          case 'te':
            return 'కొన్ని రోజులు ఇబ్బందికరంగా అనిపించవచ్చు. ఒకసారి నిదానంగా ఊపిరి పీల్చుకోండి. నేను వినడానికి ఇక్కడే ఉన్నాను.';
          case 'hi':
            return 'कभी-कभी चीजें मनमुताबिक नहीं होतीं और चिढ़ महसूस होना स्वाभाविक है। आराम से गहरी साँस लें, मैं आपकी बात सुनने के लिए यहाँ हूँ।';
          default:
            return 'I understand that can feel really frustrating. Take a gentle breath. I am right here listening whenever you wish to talk.';
        }

      case ConversationalIntent.confusion:
        switch (lang) {
          case 'te':
            return 'కంగారు పడకండి, నెమ్మదిగా ఆలోచించండి. మనం కలిసి నిదానంగా చూద్దాం. ఏ విషయం గురించి గందరగోళంగా ఉంది?';
          case 'hi':
            return 'परेशान होने की कोई बात नहीं है। हम आराम से इस बारे में बात कर सकते हैं। किस बात को लेकर उलझन है?';
          default:
            return 'Do not worry at all, take your time. We can take it one gentle step at a time. What would you like help with?';
        }

      case ConversationalIntent.greeting:
        switch (lang) {
          case 'te':
            return 'నమస్కారం! మీతో మాట్లాడటం నాకు ఎంతో సంతోషంగా ఉంది. నేను బాగున్నాను. ఈ రోజు మీరు ఎలా ఉన్నారు?';
          case 'hi':
            return 'नमस्ते! आपसे बात करके बहुत अच्छा लग रहा है। मैं ठीक हूँ। आज आप कैसा महसूस कर रहे हैं?';
          default:
            return 'Hello! It is a pleasure talking with you. I am doing well, thank you. How are you feeling today?';
        }

      case ConversationalIntent.farewell:
        switch (lang) {
          case 'te':
            return 'మంచిది, జాగ్రత్తగా ఉండండి! మళ్ళీ మీతో మాట్లాడటానికి నేను ఎదురుచూస్తుంటాను. శుభదినం!';
          case 'hi':
            return 'अलविदा, अपना ध्यान रखिएगा! आपसे दोबारा बात करने का इंतज़ार रहेगा। आपका दिन शुभ हो!';
          default:
            return 'Goodbye and take gentle care! I look forward to our next lovely chat. Have a peaceful day!';
        }

      case ConversationalIntent.unknown:
        switch (lang) {
          case 'te':
            return 'నేను అర్థం చేసుకున్నాను. ఆ విషయం గురించి ఇంకొంచెం వివరంగా చెబుతారా?';
          case 'hi':
            return 'मैं समझ रहा हूँ। क्या आप इसके बारे में थोड़ा और बताएंगे?';
          default:
            return 'I understand. Tell me a little more about that.';
        }
    }
  }

  String _generateFamilyNewsResponse(ConversationalIntentResult analysis, String lang) {
    final ctx = analysis.extractedContext;
    final isAbroad = ctx['isAbroad'] as bool? ?? false;
    final isStudies = ctx['isStudies'] as bool? ?? false;
    final isCall = ctx['isCall'] as bool? ?? false;
    final relation = ctx['relation'] as String? ?? 'family';

    // 1. Daughter / family going abroad for studies (Exact user benchmark scenario)
    if (isAbroad || isStudies) {
      final relationStr = relation == 'daughter'
          ? (lang == 'te' ? 'మీ కూతురి' : (lang == 'hi' ? 'आपकी बेटी' : 'your daughter'))
          : (relation == 'son'
              ? (lang == 'te' ? 'మీ కొడుకు' : (lang == 'hi' ? 'आपके बेटे' : 'your son'))
              : (lang == 'te' ? 'మీ కుటుంబ సభ్యుడి' : (lang == 'hi' ? 'आपके परिवार' : 'your family member')));

      switch (lang) {
        case 'te':
          return 'అరే, ఎంత అద్భుతమైన వార్త! $relationStr విజయాన్ని చూసి మీరు ఎంతో గర్వపడుతుంటారు. అదే సమయంలో, ప్రాణమైన వ్యక్తి దూరంగా వెళుతుంటే కాస్త భావోద్వేగంగా అనిపించడం చాలా సహజం. ఆమె ఏ విశ్వవిద్యాలయంలో చేరాలని నిర్ణయించుకుంది?';
        case 'hi':
          return 'अरे, यह तो बहुत ही शानदार समाचार है! $relationStr पर आपको बहुत गर्व महसूस हो रहा होगा। साथ ही, जब अपना कोई दूर जाता है तो थोड़ा भावुक होना भी बहुत स्वाभाविक है। क्या उसने तय कर लिया है कि वह किस विश्वविद्यालय में जाएगी?';
        default:
          return 'Oh, that\'s wonderful news! You must be feeling proud of her. At the same time, it can feel emotional when someone close to you is going far away. Has she decided which university she will attend?';
      }
    }

    // 2. Family called today
    if (isCall) {
      switch (lang) {
        case 'te':
          return 'చాలా బాగుంది! ఆత్మీయుల నుండి ఫోన్ కాల్ రావడం రోజంతా ఉల్లాసాన్ని నింపుతుంది. వారి మాటలు విని మీరు ఎంతో ఆనందించారని అనిపిస్తోంది.';
        case 'hi':
          return 'यह तो बहुत प्यारी बात है! अपनों का एक फोन कॉल पूरे दिन को खुशियों से भर देता है। उनसे बात करके आपको बहुत अच्छा लगा होगा।';
        default:
          return 'That\'s lovely. A call from someone you care about can really brighten the day. It sounds like you enjoyed hearing from them.';
      }
    }

    // 3. General family news
    switch (lang) {
      case 'te':
        return 'కుటుంబం గురించిన విశేషాలు వినడం ఎంతో ఆనందాన్ని ఇస్తుంది. వారి గురించి ఇంకేమైనా విశేషాలు చెబుతారా?';
      case 'hi':
        return 'परिवार से जुड़ी बातें सुनना हमेशा दिल को छू जाता है। क्या आप उनके बारे में कुछ और बताना चाहेंगे?';
      default:
        return 'It is always heartwarming to share news about family. Would you like to tell me more about what is happening?';
    }
  }
}
