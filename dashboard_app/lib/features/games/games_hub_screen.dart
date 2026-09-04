import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'screens/matching_image_screen.dart';
import 'screens/pick_correct_screen.dart';
import 'screens/number_game_screen.dart';
import 'screens/place_correctly_screen.dart';
import 'screens/find_difference_screen.dart';
import 'screens/draw_shape_screen.dart';
import 'screens/situation_match_screen.dart';
import 'screens/family_quiz_screen.dart';
import 'screens/recalling_memories_screen.dart';

class GameHubItem {
  final String id;
  final String titleAs;
  final String titleEn;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext) builder;
  final bool isReady;

  const GameHubItem({
    required this.id,
    required this.titleAs,
    required this.titleEn,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
    this.isReady = true,
  });
}

/// Games Hub Screen displaying large, accessible cards for all 9 cognitive games.
class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  List<GameHubItem> get _games => [
        GameHubItem(
          id: 'matching_image',
          titleAs: 'ছবি মিলোৱা',
          titleEn: 'Matching Image',
          subtitle: 'Find identical traditional items or pair memory cards',
          icon: Icons.filter_rounded,
          color: const Color(0xFFD9381E),
          builder: (_) => const MatchingImageScreen(),
        ),
        GameHubItem(
          id: 'pick_correct',
          titleAs: 'সঠিকটো বাছক',
          titleEn: 'Pick the Correct One',
          subtitle: 'Recognize the right cultural items & instruments',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF2E8B57),
          builder: (_) => const PickCorrectScreen(),
        ),
        GameHubItem(
          id: 'number_game',
          titleAs: 'সংখ্যাৰ খেল',
          titleEn: 'Number Game',
          subtitle: 'Counting, sequences, and gentle visual math',
          icon: Icons.pin_rounded,
          color: const Color(0xFF1E90FF),
          builder: (_) => const NumberGameScreen(),
        ),
        GameHubItem(
          id: 'place_correctly',
          titleAs: 'সঠিক স্থানত বহুৱাওক',
          titleEn: 'Place Correctly',
          subtitle: 'Drag or tap-tap items into their matching slots',
          icon: Icons.dashboard_customize_rounded,
          color: const Color(0xFF8B4513),
          builder: (_) => const PlaceCorrectlyScreen(),
        ),
        GameHubItem(
          id: 'find_difference',
          titleAs: 'পাৰ্থক্য বিচাৰক',
          titleEn: 'Find Differences',
          subtitle: 'Spot subtle differences between two cultural scenes',
          icon: Icons.visibility_rounded,
          color: const Color(0xFF9370DB),
          builder: (_) => const FindDifferenceScreen(),
        ),
        GameHubItem(
          id: 'draw_shape',
          titleAs: 'মনত ৰাখি আঁকক',
          titleEn: 'Draw What You Saw',
          subtitle: 'Look at a shape, remember it, and sketch on canvas',
          icon: Icons.gesture_rounded,
          color: const Color(0xFFE25822),
          builder: (_) => const DrawShapeScreen(),
        ),
        GameHubItem(
          id: 'situation_match',
          titleAs: 'পৰিস্থিতি মিলোৱা',
          titleEn: 'Match Situation',
          subtitle: 'Pick the right item for everyday life situations',
          icon: Icons.lightbulb_outline_rounded,
          color: const Color(0xFFDAA520),
          builder: (_) => const SituationMatchScreen(),
        ),
        GameHubItem(
          id: 'family_quiz',
          titleAs: 'আপোনজনৰ চিনাকি',
          titleEn: 'Family Quiz',
          subtitle: 'Recognize loved ones and cherish family memories',
          icon: Icons.family_restroom_rounded,
          color: const Color(0xFFC71585),
          builder: (_) => const FamilyQuizScreen(),
        ),
        GameHubItem(
          id: 'recalling_memories',
          titleAs: 'মধুৰ স্মৃতি',
          titleEn: 'Recalling Memories',
          subtitle: 'Gentle reminiscence with family & heritage photos',
          icon: Icons.auto_stories_rounded,
          color: const Color(0xFF4682B4),
          builder: (_) => const RecallingMemoriesScreen(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('মগজুৰ খেল (Brain Games)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sports_esports_rounded, size: 40, color: AppTheme.primaryColor),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'দৈনন্দিন স্মৃতি চৰ্চা',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'প্ৰতিটো খেল আনন্দ আৰু মগজু সতেজ ৰখাৰ বাবে। (Choose a game to play)',
                          style: TextStyle(fontSize: 16, color: AppTheme.subtitleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // All 9 Games List
            ..._games.map((game) => _buildGameCard(context, game)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, GameHubItem game) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.surfaceColor,
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (game.isReady) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: game.builder),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'শীঘ্ৰেই আহি আছে (Coming soon)',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            }
          },
          child: Container(
            constraints: const Duration(milliseconds: 0) == Duration.zero
                ? const BoxConstraints(minHeight: 100)
                : null,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: game.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: game.color.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(game.icon, size: 36, color: game.color),
                ),
                const SizedBox(width: 18),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${game.titleAs} (${game.titleEn})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game.subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.subtitleColor,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Arrow
                Icon(
                  game.isReady ? Icons.arrow_forward_ios_rounded : Icons.lock_outline_rounded,
                  size: 24,
                  color: game.isReady ? AppTheme.primaryColor : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
