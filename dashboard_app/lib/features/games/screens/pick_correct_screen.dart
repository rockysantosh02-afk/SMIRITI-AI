import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

class PickCorrectScreen extends BaseGameScreen {
  const PickCorrectScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'pick_correct',
          gameTitle: 'Pick the Correct One',
          domain: 'RECALL',
        );

  @override
  BaseGameScreenState<PickCorrectScreen> createState() =>
      _PickCorrectScreenState();
}

class _PickCorrectScreenState extends BaseGameScreenState<PickCorrectScreen> {
  static const List<String> _optionLetters = ['A', 'B', 'C', 'D'];
  static const List<Key> _optionKeys = [
    Key('pitch_option_a'),
    Key('pitch_option_b'),
    Key('pitch_option_c'),
    Key('pitch_option_d'),
  ];

  (String question, String clue, String correctExplanation) _getQuestionDetails(
    GameItem item,
    String lang,
  ) {
    final correctKey = item.options[item.correctIndex.clamp(0, item.options.length - 1)];
    final correctMeta = CulturalVisualHelper.getMeta(correctKey);

    final raw = item.prompt.toLowerCase();
    final img = item.image.toLowerCase();

    // 1. Musical instruments
    if (raw.contains('instrument') ||
        raw.contains('বাদ্যযন্ত্ৰ') ||
        img == 'dhol' ||
        img == 'pepa') {
      switch (lang) {
        case 'te':
          return (
            'సంగీత వాయిద్యం ఏది?',
            'పండుగలు మరియు సంబరాలలో శబ్దంతో సంగీతాన్ని అందించే వాయిద్యాన్ని చూడండి.',
            '${correctMeta.getLocalizedName(lang)} సరైన సమాధానం. ఇది సంప్రదాయ వాయిద్యం.',
          );
        case 'hi':
          return (
            'संगीत वाद्ययंत्र कौन सा है?',
            'उत्सवों और आयोजनों में बजाए जाने वाले पारंपरिक वाद्ययंत्र को पहचानें।',
            '${correctMeta.getLocalizedName(lang)} सही उत्तर है! यह एक पारंपरिक वाद्ययंत्र है।',
          );
        default:
          return (
            'Which item is the musical instrument?',
            'Look for an instrument traditionally played for celebration and rhythm.',
            '${correctMeta.nameEn} is correct! It is a traditional musical instrument used in celebrations.',
          );
      }
    }

    // 2. Handloom / Attire
    if (raw.contains('handloom') ||
        raw.contains('attire') ||
        raw.contains('কাপোৰ') ||
        img == 'muga_silk' ||
        img == 'gamosa') {
      switch (lang) {
        case 'te':
          return (
            'చేనేత వస్త్రం లేదా సంప్రదాయ దుస్తులు ఏవి?',
            'గౌరవంగా ధరించే లేదా ఉపయోగించే నేసిన వస్త్రాన్ని చూడండి.',
            '${correctMeta.getLocalizedName(lang)} సరైన సమాధానం. ఇది సంప్రదాయ నేత వస్త్రం.',
          );
        case 'hi':
          return (
            'पारंपरिक हथकरघा वस्त्र कौन सा है?',
            'सम्मान और उत्सव के लिए पहने या ओढ़े जाने वाले कपड़े को पहचानें।',
            '${correctMeta.getLocalizedName(lang)} सही उत्तर है! यह एक सुंदर हथकरघा वस्त्र है।',
          );
        default:
          return (
            'Which item is traditional handloom or attire?',
            'Look for beautifully woven cloth worn or presented with honor.',
            '${correctMeta.nameEn} is correct! It is an authentic traditional textile with cultural heritage.',
          );
      }
    }

    // 3. Landmark / Sacred place
    if (raw.contains('landmark') ||
        raw.contains('place') ||
        raw.contains('ঠাই') ||
        img == 'kamakhya' ||
        img == 'brahmaputra') {
      switch (lang) {
        case 'te':
          return (
            'చారిత్రక లేదా సహజ దర్శనీయ ప్రదేశం ఏది?',
            'ప్రశాంతత మరియు ఆధ్యాత్మిక సంపద కలిగిన పవిత్ర ప్రదేశాన్ని గుర్తించండి.',
            '${correctMeta.getLocalizedName(lang)} సరైన సమాధానం. ఇది ప్రసిద్ధ చారిత్రక ప్రదేశం.',
          );
        case 'hi':
          return (
            'ऐतिहासिक या प्राकृतिक तीर्थ स्थल कौन सा है?',
            'आध्यात्मिक शांति और ऐतिहासिक महत्व वाले स्थान को पहचानें।',
            '${correctMeta.getLocalizedName(lang)} सही उत्तर है! यह एक प्रसिद्ध पावन स्थल है।',
          );
        default:
          return (
            'Which one is a historic landmark or natural place?',
            'Look for a sacred site or natural treasure of cultural heritage.',
            '${correctMeta.nameEn} is correct! It is a renowned heritage and pilgrimage landmark.',
          );
      }
    }

    // 4. Food / Fruit / Beverage
    if (raw.contains('food') ||
        raw.contains('fruit') ||
        raw.contains('খাদ্য') ||
        img == 'masor_tenga' ||
        img == 'bamboo_shoot' ||
        img == 'assam_tea') {
      switch (lang) {
        case 'te':
          return (
            'సంప్రదాయ ఆహారం లేదా పానీయం ఏది?',
            'రుచికరమైన లేదా ఆరోగ్యకరమైన స్థానిక వంటకం లేదా పానీయాన్ని చూడండి.',
            '${correctMeta.getLocalizedName(lang)} సరైన సమాధానం. ఇది సాంప్రదాయ ఆహారం.',
          );
        case 'hi':
          return (
            'पारंपरिक खान-पान या पेय पदार्थ कौन सा है?',
            'ताजगी और स्वाद देने वाले स्थानीय व्यंजन अथवा पेय को पहचानें।',
            '${correctMeta.getLocalizedName(lang)} सही उत्तर है! यह एक पारंपरिक स्थानीय व्यंजन है।',
          );
        default:
          return (
            'Which item is traditional food, fruit, or beverage?',
            'Look for something nourishing, flavorful, or locally harvested.',
            '${correctMeta.nameEn} is correct! It is a beloved traditional culinary item.',
          );
      }
    }

    // Default fallback derived from prompt
    final match = RegExp(r'\(([^)]+)\)').firstMatch(item.prompt);
    final englishPrompt = match != null ? match.group(1)!.trim() : item.prompt;
    return (
      englishPrompt.isNotEmpty ? englishPrompt : 'Which item matches the description?',
      'Look for: ${correctMeta.description}',
      '${correctMeta.nameEn} is correct! ${correctMeta.description}.',
    );
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    final lang = Localizations.localeOf(context).languageCode;
    final (question, clue, _) = _getQuestionDetails(currentItem, lang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            key: const Key('pitch_question'),
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 14),

          // INFORMATION / CLUE SECTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppTheme.secondaryColor),
                const SizedBox(width: 6),
                Text(
                  lang == 'te'
                      ? 'సమాచారం / ఆధారం:'
                      : (lang == 'hi' ? 'जानकारी / संकेत:' : 'INFORMATION / CLUE:'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            clue,
            key: const Key('pitch_clue'),
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
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
    final (_, _, explanation) = _getQuestionDetails(currentItem, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            lang == 'te'
                ? 'సరైన సమాధానాన్ని ఎంచుకోండి:'
                : (lang == 'hi' ? 'सही उत्तर चुनें:' : 'CHOOSE THE CORRECT ANSWER:'),
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
            final btnKey = idx < _optionKeys.length ? _optionKeys[idx] : Key('pitch_option_$idx');

            return SizedBox(
              key: btnKey,
              width: (MediaQuery.of(context).size.width - 64) / 2,
              height: 100, // Exceeds 80dp minimum touch target
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
                  final title = isCorrect
                      ? "That's correct!"
                      : "Not quite. Let's look at the clue again.";
                  submitAnswer(
                    isCorrect: isCorrect,
                    feedbackTitle: title,
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
                      size: 56,
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
                                fontSize: 13,
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
