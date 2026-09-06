import 'package:flutter/material.dart';
import '../models/game_item.dart';
import 'cultural_visual_helper.dart';

/// Centralized helper providing fully localized game prompts, instructions,
/// questions, and options across English, Telugu, and Hindi.
///
/// Ensures game prompts and options ALWAYS match the user's active language.
class GameLocalizedContent {
  /// Clean any existing Assamese or raw text prompt into a canonical clean prompt
  /// in the target language.
  static String getLocalizedPrompt(
    GameItem item, {
    required String gameId,
    required String languageCode,
    BuildContext? context,
  }) {
    final lang = languageCode.toLowerCase().trim();

    switch (gameId) {
      case 'recalling_memories':
        return _getRecallingMemoriesPrompt(item, lang);
      case 'matching_image':
        return _getMatchingImagePrompt(item, lang);
      case 'family_quiz':
        return _getFamilyQuizPrompt(item, lang);
      case 'number_game':
        return _getNumberGamePrompt(item, lang);
      case 'find_difference':
        return _getFindDifferencePrompt(lang);
      case 'place_correctly':
        return _getPlaceCorrectlyPrompt(lang);
      case 'pick_correct':
        return _getPickCorrectPrompt(lang);
      case 'draw_shape':
        return _getDrawShapePrompt(item, lang);
      case 'situation_match':
        return _getSituationMatchPrompt(item, lang);
      default:
        return _cleanFallback(item.prompt, lang);
    }
  }

  static String _cleanFallback(String rawPrompt, String lang) {
    // If prompt has (English in parens)
    final match = RegExp(r'\(([^)]+)\)').firstMatch(rawPrompt);
    final englishText = match != null ? match.group(1)!.trim() : rawPrompt;

    if (lang == 'te') {
      return 'సరిపోలే సమాధానాన్ని ఎంచుకోండి';
    } else if (lang == 'hi') {
      return 'सही उत्तर चुनें';
    }
    return englishText;
  }

  static String _getRecallingMemoriesPrompt(GameItem item, String lang) {
    final isFamily = item.raw['isFamily'] as bool? ?? false;
    if (isFamily) {
      final name = item.image;
      switch (lang) {
        case 'te':
          return '$name తో గడిపిన తీపి జ్ఞాపకాలు గుర్తున్నాయా?';
        case 'hi':
          return 'क्या आपको $name के साथ बिताई प्यारी यादें याद हैं?';
        case 'en':
        default:
          return 'Do you remember sweet memories with $name?';
      }
    }

    final key = item.raw['itemKey'] as String? ?? item.image;
    switch (key) {
      case 'garden':
      case 'rhino':
        switch (lang) {
          case 'te':
            return 'పూలతో నిండిన నిశ్శబ్దమైన తోటలో నడిచిన జ్ఞాపకాలు గుర్తున్నాయా?';
          case 'hi':
            return 'क्या आपको शांत, खिले हुए बगीचे में टहलना याद है?';
          case 'en':
          default:
            return 'Do you recall walking in a quiet, blooming garden?';
        }
      case 'temple':
      case 'kamakhya':
        switch (lang) {
          case 'te':
            return 'కుటుంబంతో కలిసి ప్రశాంతంగా దేవాలయానికి వెళ్లిన రోజులు గుర్తున్నాయా?';
          case 'hi':
            return 'क्या आपको परिवार के साथ मंदिर की शांतिपूर्ण यात्राएं याद हैं?';
          case 'en':
          default:
            return 'Do you recall peaceful visits to the temple with family?';
        }
      case 'river':
      case 'brahmaputra':
        switch (lang) {
          case 'te':
            return 'సూర్యాస్తమయం వేళ నది ఒడ్డున కూర్చున్న జ్ఞాపకాలు గుర్తున్నాయా?';
          case 'hi':
            return 'क्या आपको सूर्यास्त के समय नदी किनारे बैठना याद है?';
          case 'en':
          default:
            return 'Do you remember sitting by the river at sunset?';
        }
      case 'monument':
      case 'rang_ghar':
        switch (lang) {
          case 'te':
            return 'చారిత్రక సాంస్కృతిక ప్రదేశాలను సందర్శించిన రోజులు గుర్తున్నాయా?';
          case 'hi':
            return 'क्या आपको ऐतिहासिक सांस्कृतिक स्थानों पर जाना याद है?';
          case 'en':
          default:
            return 'Do you remember visiting historic cultural places?';
        }
      default:
        switch (lang) {
          case 'te':
            return 'ఈ ప్రదేశంతో మీకు ఏవైనా జ్ఞాపకాలు ఉన్నాయా?';
          case 'hi':
            return 'क्या आपको इस स्थान से जुड़ी कोई याद है?';
          case 'en':
          default:
            return 'Do you recall sweet memories of this place?';
        }
    }
  }

  static String _getMatchingImagePrompt(GameItem item, String lang) {
    final meta = CulturalVisualHelper.getMeta(item.image);
    final itemName = meta.getLocalizedName(lang);
    switch (lang) {
      case 'te':
        return 'సరిపోలే చిత్రాన్ని ఎంచుకోండి: $itemName';
      case 'hi':
        return 'मिलता-जुलता चित्र चुनें: $itemName';
      case 'en':
      default:
        return 'Find the matching image: ${meta.nameEn}';
    }
  }

  static String _getFamilyQuizPrompt(GameItem item, String lang) {
    final tier = item.raw['tier'] as int? ?? 1;
    if (tier >= 2) {
      switch (lang) {
        case 'te':
          return 'ఈ కుటుంబ సభ్యుడిని గుర్తించండి';
        case 'hi':
          return 'इस परिवार के सदस्य को पहचानें';
        case 'en':
        default:
          return 'Recognize this family member';
      }
    }
    switch (lang) {
      case 'te':
        return 'ఈ వ్యక్తి ఎవరు?';
      case 'hi':
        return 'यह व्यक्ति कौन हैं?';
      case 'en':
      default:
        return 'Who is this person?';
    }
  }

  static String _getNumberGamePrompt(GameItem item, String lang) {
    final mode = item.raw['mode'] as String? ?? 'count';
    if (mode == 'sequence') {
      switch (lang) {
        case 'te':
          return 'వరుసలో వచ్చే తదుపరి సంఖ్యను ఎంచుకోండి';
        case 'hi':
          return 'क्रम में अगली संख्या चुनें';
        case 'en':
        default:
          return 'Tap the next number in sequence';
      }
    } else if (mode == 'addition') {
      switch (lang) {
        case 'te':
          return 'మొత్తం ఎంత అవుతుంది?';
        case 'hi':
          return 'कुल योग कितना होगा?';
        case 'en':
        default:
          return 'What is the total sum?';
      }
    }
    switch (lang) {
      case 'te':
        return 'వస్తువులను లెక్కించి సమాధానాన్ని ఎంచుకోండి';
      case 'hi':
        return 'वस्तुओं को गिनें और उत्तर चुनें';
      case 'en':
      default:
        return 'Count the items and choose the answer';
    }
  }

  static String _getFindDifferencePrompt(String lang) {
    switch (lang) {
      case 'te':
        return 'చిత్రంలో ఉన్న తేడాను గుర్తించి తాకండి';
      case 'hi':
        return 'चित्र में अंतर पहचानकर स्पर्श करें';
      case 'en':
      default:
        return 'Tap the difference on either image';
    }
  }

  static String _getPlaceCorrectlyPrompt(String lang) {
    switch (lang) {
      case 'te':
        return 'వస్తువును సరైన స్థానంలో ఉంచండి';
      case 'hi':
        return 'वस्तु को सही स्थान पर रखें';
      case 'en':
      default:
        return 'Place the item in the correct spot';
    }
  }

  static String _getPickCorrectPrompt(String lang) {
    switch (lang) {
      case 'te':
        return 'క్రింది ఎంపికల నుండి సరైనదాన్ని ఎంచుకోండి';
      case 'hi':
        return 'नीचे दिए गए विकल्पों में से सही चुनें';
      case 'en':
      default:
        return 'Choose the correct option below';
    }
  }

  static String _getDrawShapePrompt(GameItem item, String lang) {
    switch (lang) {
      case 'te':
        return 'చూపిన ఆకారాన్ని స్క్రీన్‌పై గీయండి';
      case 'hi':
        return 'दिखाए गए आकार को स्क्रीन पर बनाएं';
      case 'en':
      default:
        return 'Draw the shape shown on screen';
    }
  }

  static String _getSituationMatchPrompt(GameItem item, String lang) {
    switch (lang) {
      case 'te':
        return 'ఈ పరిస్థితికి సరైన చర్యను ఎంచుకోండి';
      case 'hi':
        return 'इस स्थिति के लिए सही विकल्प चुनें';
      case 'en':
      default:
        return 'Choose the best action for this situation';
    }
  }
}
