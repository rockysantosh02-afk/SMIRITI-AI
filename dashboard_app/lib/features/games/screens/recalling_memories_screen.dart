import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
          gameTitleAs: 'মধুৰ স্মৃতি',
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

    // Heritage places pool
    final heritagePlaces = [
      {
        'key': 'kaziranga',
        'title': 'কাজিৰঙা ৰাষ্ট্ৰীয় উদ্যান (Kaziranga)',
        'prompt': 'এই ঠাইডোখৰ মনত পৰিছেনে? (Do you remember visiting Kaziranga?)',
        'desc': 'গঁড় আৰু প্ৰকৃতিৰে ভৰপূৰ সেউজীয়া কাজিৰঙা',
        'icon': Icons.forest_rounded,
        'itemKey': 'rhino',
      },
      {
        'key': 'majuli',
        'title': 'মাজুলীৰ সত্ৰ (Majuli Satra)',
        'prompt': 'মাজুলীৰ নামঘৰ বা সত্ৰলৈ গৈ পাইছিলনে? (Have you visited the Satras of Majuli?)',
        'desc': 'ব্ৰহ্মপুত্ৰৰ বুকুত থকা পৱিত্ৰ নদীদ্বীপ',
        'icon': Icons.temple_buddhist_rounded,
        'itemKey': 'majuli',
      },
      {
        'key': 'brahmaputra',
        'title': 'মহাৰথী ব্ৰহ্মপুত্ৰ (Brahmaputra River)',
        'prompt': 'ব্ৰহ্মপুত্ৰৰ পাৰত বহি সুন্দৰ বতাহ পাইছিলনে? (Memories by the Brahmaputra)',
        'desc': 'আমাৰ অসমৰ জীৱনৰেখা লুইতৰ ঘাট',
        'icon': Icons.water_rounded,
        'itemKey': 'brahmaputra',
      },
      {
        'key': 'kamakhya',
        'title': 'নীলাচল কামাখ্যা (Kamakhya Temple)',
        'prompt': 'নীলাচল পাহাৰলৈ গৈ মা কামাখ্যাক সেৱা জনাইছেনে? (Kamakhya pilgrimage)',
        'desc': 'ঐতিহাসিক প্ৰাচীন শক্তিপীঠ',
        'icon': Icons.temple_hindu_rounded,
        'itemKey': 'kamakhya',
      },
      {
        'key': 'rang_ghar',
        'title': 'ৰংঘৰৰ বাকৰি (Historic Rang Ghar)',
        'prompt': 'ৰংঘৰৰ সৌন্দৰ্য্য দেখিছেনে? (Do you recall the royal pavilion?)',
        'desc': 'স্বৰ্গদেউসকলৰ ঐতিহাসিক ৰংঘৰ',
        'icon': Icons.stadium_rounded,
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
        prompt: 'এই ছবিখনত থকা ${m.name}ৰ সৈতে কথা মনত পৰিছেনে? (Do you remember sweet memories with ${m.name}?)',
        options: [
          'হয়, বৰ সুন্দৰ স্মৃতি! (Yes, sweet memories)',
          'আৰু কওক (Tell me more)',
          'পৰৱৰ্তী স্মৃতি চাওঁ (Next memory)',
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
          'হয়, বৰ ভাল স্মৃতি! (Yes, wonderful memories!)',
          'আৰু কওক (Tell me more)',
          'পৰৱৰ্তী ছবি চাওঁ (Next photo)',
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
    final title = currentItem.raw['title'] as String? ?? '';
    final desc = currentItem.raw['desc'] as String? ?? '';
    final photo = currentItem.raw['photo'] as String?;
    final itemKey = currentItem.raw['itemKey'] as String? ?? 'xorai';

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
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            desc,
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
            label: const Text(
              'হয়, বৰ ভাল স্মৃতি! (Yes, sweet memories!)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            label: const Text(
              'আৰু কওক / পৰৱৰ্তী ছবি (Tell me more)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            onPressed: () => submitAnswer(isCorrect: true),
          ),
        ),
      ],
    );
  }
}
