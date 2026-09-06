import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/family_repository.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

class RecallingMemoriesScreen extends BaseGameScreen {
  const RecallingMemoriesScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'recalling_memories',
          gameTitle: 'Recalling Memories',
          domain: 'REMINISCENCE',
        );

  @override
  BaseGameScreenState<RecallingMemoriesScreen> createState() =>
      _RecallingMemoriesScreenState();
}

class _RecallingMemoriesScreenState
    extends BaseGameScreenState<RecallingMemoriesScreen> {
  final FamilyRepository _repo = FamilyRepository(DatabaseProvider.instance);

  @override
  Future<List<GameItem>?> getCustomRounds() async {
    final members = await _repo.getAllMembers();

    // Heritage & peaceful places pool
    final heritagePlaces = [
      {
        'key': 'garden',
        'title': 'Peaceful Green Garden',
        'prompt': 'Do you recall walking in a quiet, blooming garden?',
        'desc': 'Fresh morning air, singing birds, and blooming flowers',
        'icon': Icons.forest_rounded,
        'itemKey': 'rhino',
      },
      {
        'key': 'temple',
        'title': 'Sacred Peaceful Temple',
        'prompt': 'Do you recall peaceful visits to the temple with family?',
        'desc': 'Sacred bells, fragrant flowers, and calming prayer',
        'icon': Icons.temple_hindu_rounded,
        'itemKey': 'kamakhya',
      },
      {
        'key': 'river',
        'title': 'Calm River Breeze',
        'prompt': 'Do you remember sitting by the river at sunset?',
        'desc': 'Gentle flowing waters and a refreshing evening breeze',
        'icon': Icons.water_rounded,
        'itemKey': 'brahmaputra',
      },
      {
        'key': 'monument',
        'title': 'Historic Heritage Monument',
        'prompt': 'Do you remember visiting historic cultural monuments?',
        'desc': 'Grand architecture and treasured memories',
        'icon': Icons.account_balance_rounded,
        'itemKey': 'rang_ghar',
      },
    ];

    final rounds = <GameItem>[];

    // First include user's family photos if available
    for (int i = 0; i < members.length && i < 2; i++) {
      final m = members[i];
      rounds.add(GameItem(
        id: 'memory_fam_$i',
        image: m.name,
        prompt: 'Do you remember sweet memories with ${m.name}?',
        options: [
          'Yes, sweet memories!',
          'Tell me more',
          'Next memory',
        ],
        correctIndex: 0,
        domain: 'REMINISCENCE',
        raw: {
          'title': '${m.name} (${m.relation})',
          'photo': m.photoPath,
          'notes': m.notes,
          'isFamily': true,
        },
      ));
    }

    // Fill remaining rounds with regional heritage places
    int placeIdx = 0;
    while (rounds.length < 5) {
      final place = heritagePlaces[placeIdx % heritagePlaces.length];
      rounds.add(GameItem(
        id: 'memory_heritage_${rounds.length}',
        image: place['itemKey'] as String,
        prompt: place['prompt'] as String,
        options: [
          'Yes, wonderful memories!',
          'Tell me more',
          'Next photo',
        ],
        correctIndex: 0,
        domain: 'REMINISCENCE',
        raw: {
          'title': place['title'] as String,
          'desc': place['desc'] as String,
          'itemKey': place['itemKey'] as String,
          'isFamily': false,
        },
      ));
      placeIdx++;
    }

    return rounds;
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    final isFamily = currentItem.raw['isFamily'] as bool? ?? false;
    final photo = currentItem.raw['photo'] as String?;
    final itemKey = currentItem.raw['itemKey'] as String? ?? 'garden';
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();

    String displayTitle = currentItem.raw['title'] as String? ?? '';
    String displayDesc = currentItem.raw['desc'] as String? ?? '';

    if (!isFamily) {
      switch (itemKey) {
        case 'garden':
        case 'rhino':
          if (lang == 'te') {
            displayTitle = 'ప్రశాంతమైన పచ్చని తోట';
            displayDesc = 'తాజా ఉదయపు గాలి, పక్షుల కిలకిలారావాలు, వికసించిన పూలు';
          } else if (lang == 'hi') {
            displayTitle = 'शांत हरा-भरा बगीचा';
            displayDesc = 'ताज़ी सुबह की हवा, चहकते पक्षी और खिले हुए फूल';
          } else {
            displayTitle = 'Peaceful Green Garden';
            displayDesc = 'Fresh morning air, singing birds, and blooming flowers';
          }
          break;
        case 'temple':
        case 'kamakhya':
          if (lang == 'te') {
            displayTitle = 'పవిత్ర ప్రశాంత దేవాలయం';
            displayDesc = 'పవిత్ర ఘంటానాదాలు, సువాసనల పూలు మరియు ప్రశాంత ప్రార్థనలు';
          } else if (lang == 'hi') {
            displayTitle = 'पवित्र शांत मंदिर';
            displayDesc = 'पवित्र घंटियाँ, सुगंधित फूल और शांतिपूर्ण प्रार्थना';
          } else {
            displayTitle = 'Sacred Peaceful Temple';
            displayDesc = 'Sacred bells, fragrant flowers, and calming prayer';
          }
          break;
        case 'river':
        case 'brahmaputra':
          if (lang == 'te') {
            displayTitle = 'ప్రశాంత నదీ గాలులు';
            displayDesc = 'సౌమ్యంగా ప్రవహించే నీరు మరియు ఆహ్లాదకరమైన సాయంత్రపు గాలి';
          } else if (lang == 'hi') {
            displayTitle = 'शांत नदी की हवा';
            displayDesc = 'बहता हुआ निर्मल जल और शाम की ताज़ा हवा';
          } else {
            displayTitle = 'Calm River Breeze';
            displayDesc = 'Gentle flowing waters and a refreshing evening breeze';
          }
          break;
        case 'monument':
        case 'rang_ghar':
          if (lang == 'te') {
            displayTitle = 'చారిత్రక వారసత్వ ప్రదేశం';
            displayDesc = 'గొప్ప శిల్పకళ మరియు విలువైన జ్ఞాపకాలు';
          } else if (lang == 'hi') {
            displayTitle = 'ऐतिहासिक धरोहर स्थल';
            displayDesc = 'भव्य वास्तुकला और अनमोल यादें';
          } else {
            displayTitle = 'Historic Heritage Monument';
            displayDesc = 'Grand architecture and treasured memories';
          }
          break;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main photo / visual
        Container(
          width: 220,
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isFamily && photo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Image.file(
                    File(photo),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.favorite_rounded,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              : Center(
                  child: CulturalVisualCard(
                    itemKey: itemKey,
                    size: 130,
                    showLabel: false,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Title and caption
        Text(
          displayTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        if (displayDesc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            displayDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppTheme.subtitleColor),
          ),
        ],
      ],
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    // Open warm response buttons: every response is valid and positive!
    return Column(
      children: [
        // Response button 1 (80dp height)
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.favorite_rounded, size: 30, color: Colors.pinkAccent),
            label: Text(
              AppLocalizations.of(context).recallingMemoriesYes,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            onPressed: () => submitAnswer(isCorrect: true),
          ),
        ),
        const SizedBox(height: 12),

        // Response button 2 (80dp height)
        SizedBox(
          width: double.infinity,
          height: 80,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 28, color: AppTheme.primaryColor),
            label: Text(
              AppLocalizations.of(context).recallingMemoriesTellMore,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            onPressed: () => submitAnswer(isCorrect: true),
          ),
        ),
      ],
    );
  }
}
