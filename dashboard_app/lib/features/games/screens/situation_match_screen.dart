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
          gameTitleAs: 'পৰিস্থিতি মিলোৱা',
          domain: 'REASONING',
        );

  @override
  BaseGameScreenState<SituationMatchScreen> createState() =>
      _SituationMatchScreenState();
}

class _SituationMatchScreenState
    extends BaseGameScreenState<SituationMatchScreen> {
  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              size: 58,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'দৈনন্দিন জীৱনৰ উচিত বাছনি',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Think what makes the most sense in this situation',
            style: TextStyle(fontSize: 15, color: AppTheme.subtitleColor),
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
          height: 96, // Exceeds 80dp touch target minimum
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
                  size: 64,
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
                          fontSize: 17,
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
