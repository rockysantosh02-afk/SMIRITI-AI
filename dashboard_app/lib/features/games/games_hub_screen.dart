import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
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
  final String titleEn;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext) builder;
  final bool isReady;

  const GameHubItem({
    required this.id,
    required this.titleEn,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
    this.isReady = true,
  });

  String getLocalizedTitle(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (id) {
      case 'matching_image':
        return loc.gameMatchingImageTitle;
      case 'pick_correct':
        return loc.gamePickCorrectTitle;
      case 'number_game':
        return loc.gameNumberGameTitle;
      case 'place_correctly':
        return loc.gamePlaceCorrectlyTitle;
      case 'find_difference':
        return loc.gameFindDifferenceTitle;
      case 'draw_shape':
        return loc.gameDrawShapeTitle;
      case 'situation_match':
        return loc.gameSituationMatchTitle;
      case 'family_quiz':
        return loc.gameFamilyQuizTitle;
      case 'recalling_memories':
        return loc.gameRecallingMemoriesTitle;
      default:
        return titleEn;
    }
  }

  String getLocalizedSubtitle(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (id) {
      case 'matching_image':
        return loc.gameMatchingImageDesc;
      case 'pick_correct':
        return loc.gamePickCorrectDesc;
      case 'number_game':
        return loc.gameNumberGameDesc;
      case 'place_correctly':
        return loc.gamePlaceCorrectlyDesc;
      case 'find_difference':
        return loc.gameFindDifferenceDesc;
      case 'draw_shape':
        return loc.gameDrawShapeDesc;
      case 'situation_match':
        return loc.gameSituationMatchDesc;
      case 'family_quiz':
        return loc.gameFamilyQuizDesc;
      case 'recalling_memories':
        return loc.gameRecallingMemoriesDesc;
      default:
        return subtitle;
    }
  }
}

/// Games Hub Screen displaying large, accessible cards for all 9 cognitive games.
class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  List<GameHubItem> get _games => [
        GameHubItem(
          id: 'matching_image',
          titleEn: 'Matching Image',
          subtitle: 'Find identical items or pair memory cards',
          icon: Icons.filter_rounded,
          color: const Color(0xFFD9381E),
          builder: (_) => const MatchingImageScreen(),
        ),
        GameHubItem(
          id: 'pick_correct',
          titleEn: 'Pick the Correct One',
          subtitle: 'Recognize the right items and instruments',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF2E8B57),
          builder: (_) => const PickCorrectScreen(),
        ),
        GameHubItem(
          id: 'number_game',
          titleEn: 'Number Game',
          subtitle: 'Counting, sequences, and gentle visual math',
          icon: Icons.pin_rounded,
          color: const Color(0xFF1E90FF),
          builder: (_) => const NumberGameScreen(),
        ),
        GameHubItem(
          id: 'place_correctly',
          titleEn: 'Place Correctly',
          subtitle: 'Position items in their right locations',
          icon: Icons.grid_view_rounded,
          color: const Color(0xFFFF8C00),
          builder: (_) => const PlaceCorrectlyScreen(),
        ),
        GameHubItem(
          id: 'find_difference',
          titleEn: 'Find the Difference',
          subtitle: 'Careful visual comparison of patterns and colors',
          icon: Icons.visibility_rounded,
          color: const Color(0xFF8A2BE2),
          builder: (_) => const FindDifferenceScreen(),
        ),
        GameHubItem(
          id: 'draw_shape',
          titleEn: 'Draw Shape',
          subtitle: 'Trace gentle geometry, letters, and numbers',
          icon: Icons.gesture_rounded,
          color: const Color(0xFF20B2AA),
          builder: (_) => const DrawShapeScreen(),
        ),
        GameHubItem(
          id: 'situation_match',
          titleEn: 'Situation Match',
          subtitle: 'Connect actions to scenes and daily events',
          icon: Icons.psychology_rounded,
          color: const Color(0xFFB8860B),
          builder: (_) => const SituationMatchScreen(),
        ),
        GameHubItem(
          id: 'family_quiz',
          titleEn: 'Family Quiz',
          subtitle: 'Warm and gentle trivia about loved ones and family memories',
          icon: Icons.family_restroom_rounded,
          color: const Color(0xFFC71585),
          builder: (_) => const FamilyQuizScreen(),
        ),
        GameHubItem(
          id: 'recalling_memories',
          titleEn: 'Recalling Memories',
          subtitle: 'Gentle reminiscence with family & heritage photos',
          icon: Icons.auto_stories_rounded,
          color: const Color(0xFF4682B4),
          builder: (_) => const RecallingMemoriesScreen(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.cognitiveGames,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          tooltip: loc.back,
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
              child: Row(
                children: [
                  const Icon(Icons.sports_esports_rounded, size: 40, color: AppTheme.primaryColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.gamesHubTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.gamesHubSubtitle,
                          style: const TextStyle(fontSize: 16, color: AppTheme.subtitleColor),
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
    final loc = AppLocalizations.of(context);

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
                SnackBar(
                  content: Text(
                    loc.comingSoon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            }
          },
          child: Container(
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
                        game.getLocalizedTitle(context),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game.getLocalizedSubtitle(context),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.subtitleColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
