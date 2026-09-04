import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

class FindDifferenceScreen extends BaseGameScreen {
  const FindDifferenceScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'find_difference',
          gameTitle: 'Find Differences',
          gameTitleAs: 'পাৰ্থক্য বিচাৰক',
          domain: 'ATTENTION',
        );

  @override
  BaseGameScreenState<FindDifferenceScreen> createState() =>
      _FindDifferenceScreenState();
}

class _DifferencePoint {
  final double x;
  final double y;
  final double radius;
  final String desc;

  _DifferencePoint({
    required this.x,
    required this.y,
    this.radius = 60.0,
    required this.desc,
  });
}

class _FindDifferenceScreenState
    extends BaseGameScreenState<FindDifferenceScreen> {
  String? _lastItemId;
  List<_DifferencePoint> _differences = [];
  final Set<int> _foundIndices = {};

  void _setupRound(GameItem item) {
    if (_lastItemId == item.id) return;
    _lastItemId = item.id;
    _foundIndices.clear();

    final rawDiffs = (item.raw['differences'] as List<dynamic>?) ?? [];
    _differences = rawDiffs.map((d) {
      final map = d as Map<String, dynamic>;
      return _DifferencePoint(
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        radius: (map['radius'] as num?)?.toDouble() ?? 60.0,
        desc: map['desc'] as String? ?? 'Difference',
      );
    }).toList();

    if (_differences.isEmpty) {
      _differences = [
        _DifferencePoint(x: 0.3, y: 0.35, desc: 'Top difference'),
        _DifferencePoint(x: 0.7, y: 0.4, desc: 'Middle difference'),
        _DifferencePoint(x: 0.5, y: 0.75, desc: 'Bottom difference'),
      ];
    }
  }

  void _handleTap(Offset localPos, Size size) {
    if (controller.isSessionComplete) return;

    for (int i = 0; i < _differences.length; i++) {
      if (_foundIndices.contains(i)) continue;

      final diff = _differences[i];
      final targetX = diff.x * size.width;
      final targetY = diff.y * size.height;

      final dist = sqrt(pow(localPos.dx - targetX, 2) + pow(localPos.dy - targetY, 2));

      // Generous 60px tap radius
      if (dist <= diff.radius) {
        setState(() {
          _foundIndices.add(i);
        });

        if (_foundIndices.length >= _differences.length) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) submitAnswer(isCorrect: true);
          });
        }
        return;
      }
    }
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    _setupRound(currentItem);
    final meta = CulturalVisualHelper.getMeta(currentItem.image);

    return Column(
      children: [
        // Status row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E8B57), size: 28),
              const SizedBox(width: 10),
              Text(
                'বিচাৰি পোৱা গ\'ল: ${_foundIndices.length} / ${_differences.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Side-by-side scenes
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 550;
            final itemWidth = isWide ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
            const itemHeight = 220.0;

            final scene1 = _buildScene(
              title: 'ছবি ১ (Scene 1)',
              meta: meta,
              width: itemWidth,
              height: itemHeight,
              isAltered: false,
            );
            final scene2 = _buildScene(
              title: 'ছবি ২ (Scene 2)',
              meta: meta,
              width: itemWidth,
              height: itemHeight,
              isAltered: true,
            );

            if (isWide) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  scene1,
                  const SizedBox(width: 16),
                  scene2,
                ],
              );
            } else {
              return Column(
                children: [
                  scene1,
                  const SizedBox(height: 14),
                  scene2,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildScene({
    required String title,
    required CulturalItemMeta meta,
    required double width,
    required double height,
    required bool isAltered,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.subtitleColor),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, Size(width, height)),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: meta.accentColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: meta.primaryColor, width: 2),
            ),
            child: Stack(
              children: [
                // Base cultural scene illustration
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(meta.icon, size: 76, color: meta.primaryColor),
                      const SizedBox(height: 8),
                      Text(
                        meta.nameAs,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: meta.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle difference features for scene 2
                if (isAltered)
                  Positioned(
                    top: height * 0.25,
                    left: width * 0.25,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: meta.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                // Green rings for found differences
                ..._foundIndices.map((i) {
                  final diff = _differences[i];
                  return Positioned(
                    left: diff.x * width - 30,
                    top: diff.y * height - 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E8B57), width: 3.5),
                        color: const Color(0xFF2E8B57).withValues(alpha: 0.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.check, color: Color(0xFF2E8B57), size: 30),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: const Text(
        'যিকোনো এখন ছবিত পাৰ্থক্য স্পৰ্শ কৰক (Tap difference on either image)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 17, color: AppTheme.subtitleColor),
      ),
    );
  }
}
