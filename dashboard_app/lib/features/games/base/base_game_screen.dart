import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/repositories/game_repository.dart';
import '../controllers/game_session_controller.dart';
import '../models/game_item.dart';
import '../models/game_result.dart';
import '../services/content_pack_service.dart';
import '../services/game_localized_content.dart';

/// Abstract base screen for all Smriti AI cognitive and memory games.
/// Provides:
/// - Round progress dots (1..5)
/// - Huge prompt text (24sp+)
/// - Flexible center content area
/// - Min 80dp oversized action targets
/// - Gentle, positive-only encouragement overlay auto-dismissing after 2s
/// - Warm session completion view with stars, Play Again, and Home actions
abstract class BaseGameScreen extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final String? gameTitleAs;
  final String domain;
  final int? initialDifficulty;
  final bool enableScroll;

  const BaseGameScreen({
    super.key,
    required this.gameId,
    required this.gameTitle,
    this.gameTitleAs,
    this.domain = 'COGNITIVE',
    this.initialDifficulty,
    this.enableScroll = true,
  });
}

abstract class BaseGameScreenState<T extends BaseGameScreen> extends State<T> {
  GameSessionController? _controller;
  GameSessionController get controller => _controller!;
  GameSessionController? get sessionController => _controller;
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool _showFeedbackOverlay = false;
  bool _lastRoundWasCorrect = true;
  GameResult? _sessionResult;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  /// Override this to provide custom rounds if the game does not use content_pack directly (e.g. personal memory)
  Future<List<GameItem>?> getCustomRounds() async => null;

  Future<void> _initSession({int? targetDifficulty}) async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseProvider.instance;
      final gameRepo = GameRepository(db);

      // Ensure content pack is ready
      if (!ContentPackService.instance.isLoaded) {
        await ContentPackService.instance.load();
      }

      final sessionCtrl = GameSessionController(
        gameId: widget.gameId,
        gameRepository: gameRepo,
        initialDifficulty: targetDifficulty ?? widget.initialDifficulty,
      );

      final customRounds = await getCustomRounds();
      await sessionCtrl.initialize(customRounds: customRounds);

      if (mounted) {
        setState(() {
          _controller = sessionCtrl;
          _isLoading = false;
          _showFeedbackOverlay = false;
          _sessionResult = null;
        });
      }
    } catch (e, st) {
      debugPrint('[BaseGameScreen] Error initializing session: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Called by subclass when user selects an answer or completes a round
  Future<void> submitAnswer({required bool isCorrect}) async {
    if (_showFeedbackOverlay || controller.isSessionComplete) return;

    _lastRoundWasCorrect = isCorrect;
    setState(() {
      _showFeedbackOverlay = true;
    });

    final willFinish = await controller.recordAttempt(correct: isCorrect);

    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      if (willFinish) {
        final result = await controller.completeSession(domain: widget.domain);
        if (mounted) {
          setState(() {
            _showFeedbackOverlay = false;
            _sessionResult = result;
          });
        }
      } else {
        setState(() {
          _showFeedbackOverlay = false;
        });
      }
    });
  }

  /// Subclasses build the specific game area in the center
  Widget buildGameContent(BuildContext context, GameItem currentItem);

  /// Subclasses build the bottom action area (options/buttons)
  Widget buildOptions(BuildContext context, GameItem currentItem);

  /// Optional prompt override if subclass wants custom text
  String getPromptText(GameItem currentItem) => currentItem.prompt;

  /// Localized prompt resolver supporting English, Telugu, and Hindi
  String getLocalizedPromptText(BuildContext context, GameItem currentItem) {
    final custom = getPromptText(currentItem);
    if (custom != currentItem.prompt) {
      return custom;
    }
    final langCode = Localizations.localeOf(context).languageCode;
    return GameLocalizedContent.getLocalizedPrompt(
      currentItem,
      gameId: widget.gameId,
      languageCode: langCode,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text(
                'Loading game...',
                style: TextStyle(fontSize: 20, color: AppTheme.subtitleColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessionResult != null) {
      return _buildSessionCompleteScreen(_sessionResult!);
    }

    final currentItem = controller.currentItem;
    if (currentItem == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: ElevatedButton(
            onPressed: () => _initSession(),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 80)),
            child: const Text('Play Again', style: TextStyle(fontSize: 22)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Progress Indicator (Round dots 1..5)
                  _buildProgressDots(),
                  const SizedBox(height: 16),

                  // 2. Huge Prompt Text (24sp+)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      getLocalizedPromptText(context, currentItem),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Middle Content Area (respects enableScroll)
                  Expanded(
                    child: Center(
                      child: widget.enableScroll
                          ? SingleChildScrollView(
                              child: buildGameContent(context, currentItem),
                            )
                          : buildGameContent(context, currentItem),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Bottom Oversized Option Buttons (Min 80dp touch target)
                  buildOptions(context, currentItem),
                ],
              ),
            ),
          ),

          // 5. Gentle Encouragement Overlay (2 seconds)
          if (_showFeedbackOverlay) _buildFeedbackOverlay(),
        ],
      ),
    );
  }

  String _getDisplayTitle(BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (widget.gameId) {
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
        return widget.gameTitle;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final loc = AppLocalizations.of(context);

    return AppBar(
      title: Text(
        _getDisplayTitle(context),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 32),
        tooltip: loc.back,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_controller != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${loc.round} ${_controller!.difficultyLevel}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(controller.totalRounds, (index) {
        final isPassed = index < controller.currentRoundIndex;
        final isCurrent = index == controller.currentRoundIndex;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isCurrent ? 28 : 18,
          height: 18,
          decoration: BoxDecoration(
            color: isPassed
                ? AppTheme.primaryColor
                : (isCurrent ? AppTheme.secondaryColor : Colors.grey[300]),
            borderRadius: BorderRadius.circular(9),
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackOverlay() {
    final isCorrect = _lastRoundWasCorrect;
    final loc = AppLocalizations.of(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCorrect ? const Color(0xFF2E8B57) : AppTheme.secondaryColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCorrect ? Icons.stars_rounded : Icons.favorite_rounded,
                size: 72,
                color: isCorrect ? const Color(0xFF2E8B57) : AppTheme.secondaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                isCorrect ? loc.wellDone : loc.tryAgain,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? const Color(0xFF2E8B57) : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCorrect ? loc.encouragementPositive : loc.encouragementGentle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, color: AppTheme.subtitleColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCompleteScreen(GameResult result) {
    final loc = AppLocalizations.of(context);
    final hasPassed = result.accuracy >= 0.6;
    final canAdvance = hasPassed && result.newDifficultyLevel > result.difficultyLevel;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasPassed ? loc.congratulations : loc.tryAgain),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Celebration Star Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final hasStar = index < result.stars;
                    return Icon(
                      Icons.star_rounded,
                      size: 64,
                      color: hasStar ? Colors.amber[600] : Colors.grey[300],
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Affirming warm text
                Text(
                  hasPassed ? loc.congratulations : loc.tryAgain,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasPassed ? loc.levelComplete : loc.encouragementGentle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: AppTheme.subtitleColor),
                ),
                const SizedBox(height: 24),

                // Stats card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${loc.score}: ${result.correctRounds} / ${result.roundsPlayed}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${loc.currentLevel}: ${result.difficultyLevel}',
                        style: const TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
                      ),
                      if (canAdvance) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${loc.nextLevel}: ${loc.round} ${result.newDifficultyLevel}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Advance to Next Level Button (if unlocked)
                if (canAdvance) ...[
                  SizedBox(
                    height: 80,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 36),
                      label: Text(
                        '${loc.nextLevel} (${loc.round} ${result.newDifficultyLevel})',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _initSession(targetDifficulty: result.newDifficultyLevel),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Play Again Button (Min 80dp)
                SizedBox(
                  height: 80,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.replay_rounded, size: 36),
                    label: Text(
                      loc.playAgain,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _initSession(targetDifficulty: result.difficultyLevel),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to Games Hub Button (Min 80dp)
                SizedBox(
                  height: 80,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor, width: 2.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.grid_view_rounded, size: 32, color: AppTheme.primaryColor),
                    label: Text(
                      loc.games,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 16),

                // Home Button (Min 80dp)
                SizedBox(
                  height: 80,
                  child: TextButton.icon(
                    icon: const Icon(Icons.home_rounded, size: 32, color: AppTheme.subtitleColor),
                    label: Text(
                      loc.home,
                      style: const TextStyle(fontSize: 20, color: AppTheme.subtitleColor),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

