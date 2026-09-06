import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

class SituationMatchScreen extends BaseGameScreen {
  const SituationMatchScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'situation_match',
          gameTitle: 'Match Situation',
          domain: 'REASONING',
        );

  @override
  BaseGameScreenState<SituationMatchScreen> createState() =>
      _SituationMatchScreenState();
}

class _SituationMatchScreenState
    extends BaseGameScreenState<SituationMatchScreen> {
  static const List<String> _optionLetters = ['A', 'B', 'C', 'D'];
  static const List<Key> _optionKeys = [
    Key('situation_option_a'),
    Key('situation_option_b'),
    Key('situation_option_c'),
    Key('situation_option_d'),
  ];

  (String situation, String question, String explanation) _getSituationDetails(
    GameItem item,
    String lang,
  ) {
    final correctKey = item.options[item.correctIndex.clamp(0, item.options.length - 1)];
    final correctMeta = CulturalVisualHelper.getMeta(correctKey);
    final raw = item.prompt.toLowerCase();
    final img = item.image.toLowerCase();

    // 1. Rain situation
    if (raw.contains('rain') || raw.contains('বৰষুণ') || img == 'japi' && raw.contains('rain')) {
      switch (lang) {
        case 'te':
          return (
            'బయట జోరుగా వర్షం కురుస్తోంది.',
            'ఈ పరిస్థితికి సరైన స్పందన లేదా వస్తువు ఏది?',
            'జాపి వర్షం మరియు ఎండ నుండి తలను సురక్షితంగా ఉంచే వెదురు టోపీ.',
          );
        case 'hi':
          return (
            'बाहर तेज़ बारिश हो रही है।',
            'इस स्थिति में सबसे सही विकल्प क्या होगा?',
            'जापी (पारंपरिक छतरी टोपी) बारिश और धूप से बचाने के लिए सबसे उपयुक्त है।',
          );
        default:
          return (
            'It is raining heavily outside.',
            'What would be the best response or item to take?',
            'A Japi is a traditional wide-brimmed woven hat designed specifically to protect from the rain.',
          );
      }
    }

    // 2. Welcoming a guest
    if (raw.contains('guest') || raw.contains('অতিথি') || img == 'gamosa') {
      switch (lang) {
        case 'te':
          return (
            'మీ ఇంటికి ఒక ఆత్మీయ అతిథి వచ్చారు.',
            'వారిని గౌరవంగా ఆహ్వానించడానికి ఏది ఉత్తమమైన ఎంపిక?',
            'గమోసాను గౌరవ చిహ్నంగా అతిథులకు సమర్పిస్తారు.',
          );
        case 'hi':
          return (
            'आपके घर एक सम्मानीय अतिथि आए हैं।',
            'उनका आदरपूर्वक स्वागत करने के लिए सबसे अच्छा विकल्प क्या है?',
            'गमोसा सम्मान और प्रेम का प्रतीक है, जिसे पारंपरिक रूप से अतिथियों को भेंट किया जाता है।',
          );
        default:
          return (
            'A respected guest has arrived at your home.',
            'What would be the best response to welcome and honor them?',
            'A Gamosa is a handwoven cloth presented to guests as a warm token of heartfelt respect.',
          );
      }
    }

    // 3. Festive celebration
    if (raw.contains('bihu') || raw.contains('festival') || raw.contains('আনন্দ') || img == 'dhol') {
      switch (lang) {
        case 'te':
          return (
            'ఈ రోజు అందరూ కలిసి పండుగ జరుపుకుంటున్నారు.',
            'ఉల్లాసంగా ఉత్సవంలో పాల్గొనడానికి ఉత్తమ ఎంపిక ఏది?',
            'ధోల్ పండుగలలో లయబద్ధమైన సంగీతాన్ని ఇచ్చే సాంప్రదాయ వాయిద్యం.',
          );
        case 'hi':
          return (
            'आज सब मिलकर उत्सव मना रहे हैं।',
            'उत्सव के आनंद को बढ़ाने के लिए सबसे उपयुक्त क्या है?',
            'ढोल पारंपरिक उत्सवों में बजाया जाने वाला मुख्य वाद्ययंत्र है।',
          );
        default:
          return (
            'Today is a joyful cultural celebration with family and friends.',
            'What would be the best response to celebrate together?',
            'Playing the traditional Dhol brings everyone together with joyful rhythm.',
          );
      }
    }

    // 4. Morning beverage
    if (raw.contains('morning') || raw.contains('warm') || raw.contains('పువా') || img == 'assam_tea') {
      switch (lang) {
        case 'te':
          return (
            'ప్రశాంతమైన ఉదయం వేళ సేదతీరాలి.',
            'ఉదయాన్నే శరీరాన్ని ఉత్తేజపరిచేందుకు ఉత్తమ ఎంపిక ఏది?',
            'వేడి వేడి తాజా టీ ఉదయాన్నే మనసుకు ఆహ్లాదాన్ని మరియు ఆరోగ్యాన్ని ఇస్తుంది.',
          );
        case 'hi':
          return (
            'एक शांत और सुहानी सुबह है।',
            'दिन की शुरुआत में ताजगी के लिए सबसे अच्छा विकल्प क्या है?',
            'गरमा-गरम चाय सुबह के समय मन और शरीर को नई ऊर्जा देती है।',
          );
        default:
          return (
            'It is a calm and pleasant morning.',
            'What would be the best choice to start the day with warmth?',
            'Fresh hot tea warms the body and gently refreshes the senses in the morning.',
          );
      }
    }

    // 5. Prayer / temple offering
    if (raw.contains('prayer') || raw.contains('temple') || raw.contains('prasad') || img == 'xorai') {
      switch (lang) {
        case 'te':
          return (
            'మీరు ప్రార్థన మందిరానికి లేదా గుడికి వెళ్లారు.',
            'ప్రసాదాన్ని సమర్పించడానికి ఉత్తమ పళ్లెం ఏది?',
            'షోరై పవిత్రమైన పూజా సమర్పణల కోసం ఉపయోగించే సాంప్రదాయ పళ్లెం.',
          );
        case 'hi':
          return (
            'आप प्रार्थना कक्ष या मंदिर में जा रहे हैं।',
            'प्रसाद अर्पित करने के लिए सबसे पवित्र थाली कौन सी है?',
            'शोराई पारंपरिक कांस्य थाली है जो पवित्र अवसरों पर प्रसाद के लिए उपयोग की जाती है।',
          );
        default:
          return (
            'You are visiting a place of quiet prayer and worship.',
            'What would be the best response to offer prasad with devotion?',
            'A Xorai is a traditional raised pedestal tray used to offer sacred blessings.',
          );
      }
    }

    // Generic fallback extracting English from prompt
    final match = RegExp(r'\(([^)]+)\)').firstMatch(item.prompt);
    final rawEnglish = match != null ? match.group(1)!.trim() : item.prompt;
    final parts = rawEnglish.split('?');
    final situationPart = parts.isNotEmpty && parts[0].trim().isNotEmpty
        ? '${parts[0].trim()}.'
        : 'Think about everyday life and appropriate caring choices.';
    final questionPart = parts.length > 1 && parts[1].trim().isNotEmpty
        ? '${parts[1].trim()}?'
        : 'What would be the best response?';

    return (
      situationPart,
      questionPart,
      '${correctMeta.nameEn} is the best choice because ${correctMeta.description.toLowerCase()}.',
    );
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    final lang = Localizations.localeOf(context).languageCode;
    final (situation, question, _) = _getSituationDetails(currentItem, lang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SITUATION BADGE & TEXT
          Container(
            key: const Key('situation_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFB8860B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.psychology_rounded, size: 20, color: Color(0xFFB8860B)),
                const SizedBox(width: 6),
                Text(
                  lang == 'te'
                      ? 'పరిస్థితి:'
                      : (lang == 'hi' ? 'स्थिति:' : 'SITUATION:'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB8860B),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            situation,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 14),

          // QUESTION SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline_rounded, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  lang == 'te' ? 'ప్రశ్న:' : (lang == 'hi' ? 'प्रश्न:' : 'QUESTION:'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            key: const Key('situation_question'),
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.subtitleColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    final lang = Localizations.localeOf(context).languageCode;
    final (_, _, explanation) = _getSituationDetails(currentItem, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            lang == 'te'
                ? 'సరైన ప్రతిస్పందనను ఎంచుకోండి:'
                : (lang == 'hi' ? 'सबसे अच्छा विकल्प चुनें:' : 'CHOOSE THE BEST RESPONSE:'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.subtitleColor,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(currentItem.options.length, (idx) {
            final optKey = currentItem.options[idx];
            final meta = CulturalVisualHelper.getMeta(optKey);
            final isCorrect = idx == currentItem.correctIndex;
            final letter = idx < _optionLetters.length ? _optionLetters[idx] : '${idx + 1}';
            final btnKey = idx < _optionKeys.length ? _optionKeys[idx] : Key('situation_option_$idx');

            return SizedBox(
              key: btnKey,
              width: (MediaQuery.of(context).size.width - 64) / 2,
              height: 96, // Exceeds 80dp minimum touch target
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.textColor,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: meta.primaryColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                onPressed: () {
                  final feedbackTitle = isCorrect
                      ? "That's a kind choice!"
                      : "Let's think about what would be more helpful.";
                  submitAnswer(
                    isCorrect: isCorrect,
                    feedbackTitle: feedbackTitle,
                    explanation: explanation,
                  );
                },
                child: Row(
                  children: [
                    // A/B/C/D letter badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: meta.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: meta.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CulturalVisualCard(
                      itemKey: optKey,
                      size: 54,
                      showLabel: false,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.getLocalizedName(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: meta.primaryColor,
                            ),
                          ),
                          if (lang != 'en')
                            Text(
                              meta.nameEn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtitleColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
