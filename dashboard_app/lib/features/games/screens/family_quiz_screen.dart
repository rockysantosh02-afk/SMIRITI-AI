import 'dart:io';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/family_repository.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';

class FamilyQuizScreen extends BaseGameScreen {
  const FamilyQuizScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'family_quiz',
          gameTitle: 'Family Quiz',
          gameTitleAs: 'আপোনজনৰ চিনাকি',
          domain: 'RECALL',
        );

  @override
  BaseGameScreenState<FamilyQuizScreen> createState() =>
      _FamilyQuizScreenState();
}

class _FamilyQuizScreenState extends BaseGameScreenState<FamilyQuizScreen> {
  final FamilyRepository _repo = FamilyRepository(DatabaseProvider.instance);

  @override
  Future<List<GameItem>?> getCustomRounds() async {
    final members = await _repo.getAllMembers();

    // Built-in friendly backup members if user has not yet added any
    final sampleMembers = [
      {'name': 'ৰাহুল (Rahul)', 'relation': 'Grandson (নাতি)', 'photo': null},
      {'name': 'অনিতা (Anita)', 'relation': 'Daughter (কন্যা)', 'photo': null},
      {'name': 'বিকাশ (Bikash)', 'relation': 'Son (পুত্ৰ)', 'photo': null},
      {'name': 'পূজা (Pooja)', 'relation': 'Granddaughter (নাতিনী)', 'photo': null},
      {'name': 'প্ৰিয়া (Priya)', 'relation': 'Niece (ভাগিনী)', 'photo': null},
    ];

    final activeList = members.isNotEmpty
        ? members
            .map((m) => {
                  'name': m.name,
                  'relation': m.relation,
                  'photo': m.photoPath,
                })
            .toList()
        : sampleMembers;

    final rounds = <GameItem>[];
    for (int i = 0; i < 5; i++) {
      final target = activeList[i % activeList.length];
      final targetName = target['name'] as String;
      final targetRelation = target['relation'] as String;

      // Collect distractors
      final otherNames = activeList
          .where((m) => m['name'] != targetName)
          .map((m) => m['name'] as String)
          .toList();

      while (otherNames.length < 2) {
        otherNames.add('মৰমৰ বন্ধু (Dear Friend)');
        otherNames.add('প্ৰিয় চুবুৰীয়া (Neighbor)');
      }

      final opts = [otherNames[0], otherNames[1]];
      final correctIdx = i % 3;
      opts.insert(correctIdx, targetName);

      rounds.add(GameItem(
        id: 'fam_quiz_$i',
        image: targetName,
        prompt: widget.initialDifficulty != null && widget.initialDifficulty! >= 2
            ? 'এখেতৰ নাম আৰু চিনাকি কি? (Recognize this family member)'
            : 'এখেত কোন হয়? (Who is this person?)',
        options: opts,
        correctIndex: correctIdx,
        domain: 'RECALL',
        raw: {
          'name': targetName,
          'relation': targetRelation,
          'photo': target['photo'],
        },
      ));
    }
    return rounds;
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    final photoPath = currentItem.raw['photo'] as String?;
    final relation = currentItem.raw['relation'] as String? ?? 'Family Member';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Photo / Avatar card
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.primaryColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: photoPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 90,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 90,
                    color: AppTheme.primaryColor,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Friendly relation badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.secondaryColor),
          ),
          child: Text(
            'সম্পৰ্ক: $relation',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    // 3 large name buttons (min 80dp tall)
    return Column(
      children: List.generate(currentItem.options.length, (idx) {
        final optionName = currentItem.options[idx];
        final isCorrect = idx == currentItem.correctIndex;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 80, // 80dp minimum target
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.textColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              onPressed: () => submitAnswer(isCorrect: isCorrect),
              child: Text(
                optionName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
