import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

class MatchingImageScreen extends BaseGameScreen {
  const MatchingImageScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'matching_image',
          gameTitle: 'Matching Image',
          gameTitleAs: 'ছবি মিলোৱা',
          domain: 'VISUAL_MEMORY',
        );

  @override
  BaseGameScreenState<MatchingImageScreen> createState() =>
      _MatchingImageScreenState();
}

class _CardPairState {
  final int id;
  final String itemKey;
  bool isFaceUp;
  bool isMatched;

  _CardPairState({
    required this.id,
    required this.itemKey,
  })  : isFaceUp = false,
        isMatched = false;
}

class _MatchingImageScreenState
    extends BaseGameScreenState<MatchingImageScreen> {
  // Pair matching mode state (Tier 3+)
  List<_CardPairState> _pairCards = [];
  int? _firstSelectedIndex;
  bool _isProcessingPair = false;
  String? _lastLoadedRoundId;

  void _setupPairCardsIfNeeded(GameItem item) {
    if (controller.difficultyLevel < 3) return;
    if (_lastLoadedRoundId == item.id) return;

    _lastLoadedRoundId = item.id;
    _firstSelectedIndex = null;
    _isProcessingPair = false;

    // Determine number of pairs based on tier (Tier 3: 3 pairs, Tier 4-5: 4 pairs)
    final numPairs = controller.difficultyLevel >= 4 ? 4 : 3;
    final keys = {item.image, ...item.options}
        .take(numPairs)
        .toList();
    while (keys.length < numPairs) {
      keys.add(CulturalVisualHelper.items.keys.elementAt(Random().nextInt(CulturalVisualHelper.items.length)));
    }

    final cards = <_CardPairState>[];
    int cardId = 0;
    for (final k in keys) {
      cards.add(_CardPairState(id: cardId++, itemKey: k));
      cards.add(_CardPairState(id: cardId++, itemKey: k));
    }
    cards.shuffle();
    _pairCards = cards;
  }

  void _onCardTapped(int index) {
    if (_isProcessingPair || _pairCards[index].isFaceUp || _pairCards[index].isMatched) {
      return;
    }

    setState(() {
      _pairCards[index].isFaceUp = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      final firstIdx = _firstSelectedIndex!;
      _firstSelectedIndex = null;
      _isProcessingPair = true;

      if (_pairCards[firstIdx].itemKey == _pairCards[index].itemKey) {
        // Matched!
        setState(() {
          _pairCards[firstIdx].isMatched = true;
          _pairCards[index].isMatched = true;
          _isProcessingPair = false;
        });

        // Check if all pairs matched
        final allMatched = _pairCards.every((c) => c.isMatched);
        if (allMatched) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) submitAnswer(isCorrect: true);
          });
        }
      } else {
        // Mismatch: flip back after brief pause
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            setState(() {
              _pairCards[firstIdx].isFaceUp = false;
              _pairCards[index].isFaceUp = false;
              _isProcessingPair = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    if (controller.difficultyLevel >= 3) {
      _setupPairCardsIfNeeded(currentItem);
      // Grid of face-down cards
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            const Text(
              'দুটা একে কাৰ্ড বিচাৰি স্পৰ্শ কৰক (Tap two cards to match pairs)',
              style: TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: List.generate(_pairCards.length, (idx) {
                final card = _pairCards[idx];
                return GestureDetector(
                  onTap: () => _onCardTapped(idx),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: card.isFaceUp
                          ? AppTheme.surfaceColor
                          : AppTheme.primaryColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: card.isMatched
                            ? const Color(0xFF2E8B57)
                            : AppTheme.primaryColor,
                        width: card.isMatched ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: card.isFaceUp
                        ? Center(
                            child: CulturalVisualCard(
                              itemKey: card.itemKey,
                              size: 76,
                              showLabel: false,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.question_mark_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    // Tier 1-2: Single Target Image in Center
    final meta = CulturalVisualHelper.getMeta(currentItem.image);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CulturalVisualCard(
          itemKey: currentItem.image,
          size: 150,
          showLabel: true,
        ),
        const SizedBox(height: 12),
        Text(
          meta.nameEn,
          style: const TextStyle(
            fontSize: 18,
            color: AppTheme.subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    if (controller.difficultyLevel >= 3) {
      // In pair matching, the cards are in the middle content area
      return const SizedBox.shrink();
    }

    // Tier 1-2: 3-4 bottom option buttons (min 80dp tall)
    return Column(
      children: [
        const Text(
          'তলৰ পৰা একে ছবিখন বাছক (Choose the matching one below):',
          style: TextStyle(fontSize: 17, color: AppTheme.subtitleColor),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(currentItem.options.length, (idx) {
            final optKey = currentItem.options[idx];
            final isCorrect = idx == currentItem.correctIndex;

            return SizedBox(
              width: (MediaQuery.of(context).size.width - 64) / 2,
              height: 90,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.textColor,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
                onPressed: () => submitAnswer(isCorrect: isCorrect),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CulturalVisualCard(
                      itemKey: optKey,
                      size: 60,
                      showLabel: false,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        CulturalVisualHelper.getMeta(optKey).getLocalizedName(
                          Localizations.localeOf(context).languageCode,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
