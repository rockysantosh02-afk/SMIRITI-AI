import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

class NumberGameScreen extends BaseGameScreen {
  const NumberGameScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'number_game',
          gameTitle: 'Number Game',
          gameTitleAs: 'সংখ্যাৰ খেল',
          domain: 'NUMERACY',
        );

  @override
  BaseGameScreenState<NumberGameScreen> createState() =>
      _NumberGameScreenState();
}

class _NumberGameScreenState extends BaseGameScreenState<NumberGameScreen> {
  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    final mode = currentItem.raw['mode'] as String? ?? 'count';

    if (mode == 'sequence') {
      // Sequence mode: [1] [2] [3] [?]
      final seq = (currentItem.raw['sequence'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['1', '2', '3'];

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ...seq.map((numStr) => Container(
                    width: 72,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor, width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        numStr,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  )),
              Container(
                width: 72,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.secondaryColor, width: 3),
                ),
                child: const Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'খালী স্থানত কি সংখ্যা বহিব? (Tap the next number)',
            style: TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
          ),
        ],
      );
    } else if (mode == 'addition') {
      // Visual addition mode: [op1 items] + [op2 items] = ?
      final operands = (currentItem.raw['operands'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [1, 1];
      final op1 = operands[0];
      final op2 = operands[1];
      final itemKey = currentItem.image;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Group 1
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: List.generate(
                    op1,
                    (_) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: CulturalVisualCard(
                        itemKey: itemKey,
                        size: 54,
                        showLabel: false,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '+',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
              // Group 2
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: List.generate(
                    op2,
                    (_) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: CulturalVisualCard(
                        itemKey: itemKey,
                        size: 54,
                        showLabel: false,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '=',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
              const Text(
                '?',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$op1 + $op2 = কিমান হ\'ব? (What is the total sum?)',
            style: const TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
          ),
        ],
      );
    }

    // Default: Count mode (Count the objects)
    final count = currentItem.raw['count'] as int? ?? 3;
    final itemKey = currentItem.image;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(
            count,
            (idx) => CulturalVisualCard(
              itemKey: itemKey,
              size: 84,
              showLabel: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'বস্তুবোৰ গণনা কৰক আৰু উত্তৰটো বাছক (Count the items above)',
          style: TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
        ),
      ],
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(currentItem.options.length, (idx) {
        final optText = currentItem.options[idx];
        final isCorrect = idx == currentItem.correctIndex;

        return SizedBox(
          width: 76,
          height: 84, // Exceeds 80dp minimum target
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: AppTheme.primaryColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => submitAnswer(isCorrect: isCorrect),
            child: Text(
              optText,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
}
