import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

class PlaceCorrectlyScreen extends BaseGameScreen {
  const PlaceCorrectlyScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'place_correctly',
          gameTitle: 'Place Correctly',
          gameTitleAs: 'সঠিক স্থানত বহুৱাওক',
          domain: 'SPATIAL',
        );

  @override
  BaseGameScreenState<PlaceCorrectlyScreen> createState() =>
      _PlaceCorrectlyScreenState();
}

class _PlaceCorrectlyScreenState
    extends BaseGameScreenState<PlaceCorrectlyScreen> {
  String? _lastItemId;
  List<String> _targetSlots = [];
  Map<int, String?> _placedSlots = {};
  String? _selectedForTapTap;

  void _setupRound(GameItem item) {
    if (_lastItemId == item.id) return;
    _lastItemId = item.id;
    _selectedForTapTap = null;

    final rawSlots = (item.raw['slots'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        item.options;
    _targetSlots = List<String>.from(rawSlots);
    _placedSlots = {for (int i = 0; i < _targetSlots.length; i++) i: null};
  }

  void _placeItemInSlot(int slotIndex, String itemKey) {
    if (_targetSlots[slotIndex] == itemKey) {
      // Correct placement
      setState(() {
        _placedSlots[slotIndex] = itemKey;
        _selectedForTapTap = null;
      });

      // Check if all slots are filled
      final allFilled = _placedSlots.values.every((v) => v != null);
      if (allFilled) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) submitAnswer(isCorrect: true);
        });
      }
    } else {
      // Mismatch: clear selection with friendly vibration/visual feedback
      setState(() {
        _selectedForTapTap = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'আন এটা স্থানত যত্ন কৰক (Try a different slot)',
            style: TextStyle(fontSize: 18),
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    _setupRound(currentItem);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top Outlined Slots
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Text(
                'লক্ষ্য স্থানসমূহ (Target Slots):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: List.generate(_targetSlots.length, (slotIdx) {
                  final targetKey = _targetSlots[slotIdx];
                  final placedKey = _placedSlots[slotIdx];
                  final isTargeted = placedKey != null;
                  final targetMeta = CulturalVisualHelper.getMeta(targetKey);

                  return DragTarget<String>(
                    onWillAcceptWithDetails: (details) => details.data == targetKey,
                    onAcceptWithDetails: (details) => _placeItemInSlot(slotIdx, details.data),
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: () {
                          if (_selectedForTapTap != null) {
                            _placeItemInSlot(slotIdx, _selectedForTapTap!);
                          }
                        },
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: isTargeted
                                ? const Color(0xFF2E8B57).withValues(alpha: 0.15)
                                : (candidateData.isNotEmpty
                                    ? AppTheme.secondaryColor.withValues(alpha: 0.25)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTargeted
                                  ? const Color(0xFF2E8B57)
                                  : (candidateData.isNotEmpty
                                      ? AppTheme.secondaryColor
                                      : AppTheme.primaryColor.withValues(alpha: 0.5)),
                              width: isTargeted ? 3 : 2,
                              style: isTargeted ? BorderStyle.solid : BorderStyle.solid,
                            ),
                          ),
                          child: isTargeted
                              ? Center(
                                  child: CulturalVisualCard(
                                    itemKey: placedKey,
                                    size: 78,
                                    showLabel: false,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      targetMeta.icon,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      targetMeta.nameAs,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'টানি বহুৱাওক বা স্পৰ্শ কৰি স্থান নিৰ্বাচন কৰক\n(Drag or tap item then tap slot)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, color: AppTheme.subtitleColor),
        ),
      ],
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    // Bottom draggable and tappable items
    final remainingItems = _targetSlots.where((key) {
      final placedCount = _placedSlots.values.where((v) => v == key).length;
      final totalTargetCount = _targetSlots.where((v) => v == key).length;
      return placedCount < totalTargetCount;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: remainingItems.map((itemKey) {
          final isSelected = _selectedForTapTap == itemKey;

          return Draggable<String>(
            data: itemKey,
            feedback: Material(
              color: Colors.transparent,
              child: CulturalVisualCard(
                itemKey: itemKey,
                size: 90,
                showLabel: false,
                isSelected: true,
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: CulturalVisualCard(
                itemKey: itemKey,
                size: 84,
                showLabel: true,
              ),
            ),
            child: CulturalVisualCard(
              itemKey: itemKey,
              size: 84,
              showLabel: true,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedForTapTap = isSelected ? null : itemKey;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
