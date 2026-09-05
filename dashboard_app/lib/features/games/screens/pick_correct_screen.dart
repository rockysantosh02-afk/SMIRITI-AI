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
          gameTitleAs: 'সঠিকটো বাছক',
          domain: 'RECALL',
        );

  @override
  BaseGameScreenState<PickCorrectScreen> createState() =>
      _PickCorrectScreenState();
}

class _PickCorrectScreenState extends BaseGameScreenState<PickCorrectScreen> {
  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 12),
          Text(
            'তলৰ চাৰিটা বিকল্পৰ পৰা বাছনি কৰক',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap the card that matches the prompt',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(currentItem.options.length, (idx) {
        final optKey = currentItem.options[idx];
        final meta = CulturalVisualHelper.getMeta(optKey);
        final isCorrect = idx == currentItem.correctIndex;

        return SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 2,
          height: 100, // Exceeds 80dp minimum
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
            onPressed: () => submitAnswer(isCorrect: isCorrect),
            child: Row(
              children: [
                CulturalVisualCard(
                  itemKey: optKey,
                  size: 68,
                  showLabel: false,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.getLocalizedName(
                          Localizations.localeOf(context).languageCode,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: meta.primaryColor,
                        ),
                      ),
                      Text(
                        meta.nameEn.split(' ').first,
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
    );
  }
}
