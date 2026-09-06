import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/cultural_visual_helper.dart';

/// Normalized region representing the location of a visual difference (0.0 to 1.0).
class DifferenceRegion {
  final double normalizedX;
  final double normalizedY;
  final double normalizedRadius;
  final String description;

  const DifferenceRegion({
    required this.normalizedX,
    required this.normalizedY,
    this.normalizedRadius = 0.18, // Generous 18% radius for elderly touch
    required this.description,
  });

  Rect toRect(Size size) {
    final centerX = normalizedX * size.width;
    final centerY = normalizedY * size.height;
    final minDim = size.width < size.height ? size.width : size.height;
    final r = normalizedRadius * minDim;
    return Rect.fromCircle(center: Offset(centerX, centerY), radius: r);
  }

  bool contains(Offset localPoint, Size size) {
    final centerX = normalizedX * size.width;
    final centerY = normalizedY * size.height;
    final minDim = size.width < size.height ? size.width : size.height;
    final r = normalizedRadius * minDim;
    // Allow at least 48px touch target
    final hitRadius = r < 48.0 ? 48.0 : r;
    final dist = (localPoint - Offset(centerX, centerY)).distance;
    return dist <= hitRadius;
  }
}

/// Level specification ensuring distinct visual difference regions per round.
class DifferenceLevel {
  final String id;
  final DifferenceRegion region;

  const DifferenceLevel({
    required this.id,
    required this.region,
  });

  // Pre-authored distinct difference regions for sequential scenes
  static const List<DifferenceRegion> defaultRegions = [
    DifferenceRegion(
      normalizedX: 0.22,
      normalizedY: 0.25,
      description: 'Upper-left detail',
    ),
    DifferenceRegion(
      normalizedX: 0.78,
      normalizedY: 0.75,
      description: 'Lower-right detail',
    ),
    DifferenceRegion(
      normalizedX: 0.50,
      normalizedY: 0.50,
      description: 'Center detail',
    ),
    DifferenceRegion(
      normalizedX: 0.78,
      normalizedY: 0.25,
      description: 'Upper-right detail',
    ),
    DifferenceRegion(
      normalizedX: 0.22,
      normalizedY: 0.75,
      description: 'Lower-left detail',
    ),
  ];

  static DifferenceRegion getRegionForRound(int roundIndex, {String? itemId}) {
    final idx = roundIndex % defaultRegions.length;
    return defaultRegions[idx];
  }
}

class FindDifferenceScreen extends BaseGameScreen {
  const FindDifferenceScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'find_difference',
          gameTitle: 'Find the Difference',
          domain: 'ATTENTION',
        );

  @override
  BaseGameScreenState<FindDifferenceScreen> createState() =>
      _FindDifferenceScreenState();
}

class _FindDifferenceScreenState
    extends BaseGameScreenState<FindDifferenceScreen> {
  String? _lastItemId;
  late DifferenceRegion _activeRegion;
  bool _differenceFound = false;
  String? _missNotice;

  void _setupRound(GameItem item) {
    if (_lastItemId == item.id) return;
    _lastItemId = item.id;
    _differenceFound = false;
    _missNotice = null;

    final roundIdx = controller.currentRoundIndex;
    final rawDiffs = item.raw['differences'] as List<dynamic>?;

    if (rawDiffs != null && rawDiffs.isNotEmpty) {
      final first = rawDiffs.first as Map<String, dynamic>;
      _activeRegion = DifferenceRegion(
        normalizedX: (first['x'] as num).toDouble(),
        normalizedY: (first['y'] as num).toDouble(),
        normalizedRadius: (first['radius'] as num?)?.toDouble() ?? 0.18,
        description: first['desc'] as String? ?? 'Difference',
      );
    } else {
      _activeRegion = DifferenceLevel.getRegionForRound(roundIdx, itemId: item.id);
    }
  }

  void _handleTap(Offset localPos, Size size) {
    if (controller.isSessionComplete || _differenceFound) return;

    if (_activeRegion.contains(localPos, size)) {
      setState(() {
        _differenceFound = true;
        _missNotice = null;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          submitAnswer(
            isCorrect: true,
            feedbackTitle: 'You found it!',
            explanation: 'Great eye! You spotted the difference accurately.',
          );
        }
      });
    } else {
      setState(() {
        _missNotice = Localizations.localeOf(context).languageCode == 'te'
            ? 'అక్కడ కాదు. రెండు చిత్రాలను జాగ్రత్తగా పరిశీలించండి.'
            : (Localizations.localeOf(context).languageCode == 'hi'
                ? 'वहाँ नहीं। दोनों चित्रों को ध्यान से देखें।'
                : 'Not there. Look carefully at both pictures.');
      });
    }
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    _setupRound(currentItem);
    final meta = CulturalVisualHelper.getMeta(currentItem.image);
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      children: [
        // Status & instruction badge
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
              Icon(
                _differenceFound ? Icons.check_circle_rounded : Icons.search_rounded,
                color: _differenceFound ? const Color(0xFF2E8B57) : AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                _differenceFound
                    ? (lang == 'te'
                        ? 'తేడా కనుగొనబడింది!'
                        : (lang == 'hi' ? 'अंतर मिल गया!' : 'Difference Found!'))
                    : (lang == 'te'
                        ? 'తేడా ఉన్న ప్రదేశాన్ని తాకండి'
                        : (lang == 'hi'
                            ? 'अंतर वाले स्थान को स्पर्श करें'
                            : 'Tap where you see a difference')),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _differenceFound ? const Color(0xFF2E8B57) : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Gentle miss banner if tapped away
        if (_missNotice != null && !_differenceFound) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade700, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Text(
                  _missNotice!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Side-by-side or stacked scenes
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 550;
            final itemWidth = isWide ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
            const itemHeight = 220.0;

            final scene1Title = lang == 'te'
                ? 'చిత్రం 1'
                : (lang == 'hi' ? 'दृश्य 1' : 'Picture 1');
            final scene2Title = lang == 'te'
                ? 'చిత్రం 2'
                : (lang == 'hi' ? 'दृश्य 2' : 'Picture 2');

            final scene1 = _buildScene(
              key: const Key('find_difference_scene_a'),
              title: scene1Title,
              meta: meta,
              width: itemWidth,
              height: itemHeight,
              isAltered: false,
            );
            final scene2 = _buildScene(
              key: const Key('find_difference_scene_b'),
              title: scene2Title,
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
    required Key key,
    required String title,
    required CulturalItemMeta meta,
    required double width,
    required double height,
    required bool isAltered,
  }) {
    // Exact coordinates of the visual difference on the scene
    final targetX = _activeRegion.normalizedX * width;
    final targetY = _activeRegion.normalizedY * height;

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.subtitleColor,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          key: key,
          behavior: HitTestBehavior.opaque,
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
                        meta.getLocalizedName(
                          Localizations.localeOf(context).languageCode,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: meta.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // The visual difference exists in Scene 2 at EXACT targetX and targetY
                if (isAltered)
                  Positioned(
                    left: targetX - 16,
                    top: targetY - 16,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: meta.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Green celebration ring when found
                if (_differenceFound)
                  Positioned(
                    left: targetX - 32,
                    top: targetY - 32,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E8B57), width: 3.5),
                        color: const Color(0xFF2E8B57).withValues(alpha: 0.25),
                      ),
                      child: const Center(
                        child: Icon(Icons.check, color: Color(0xFF2E8B57), size: 32),
                      ),
                    ),
                  ),
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
      child: Text(
        Localizations.localeOf(context).languageCode == 'te'
            ? 'రెండు చిత్రాలను పరిశీలించి తేడా ఉన్న ప్రదేశాన్ని నొక్కండి'
            : (Localizations.localeOf(context).languageCode == 'hi'
                ? 'दोनों तस्वीरों को देखकर अंतर वाले स्थान को स्पर्श करें'
                : 'Look at both pictures and tap the place with the difference'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17, color: AppTheme.subtitleColor),
      ),
    );
  }
}
