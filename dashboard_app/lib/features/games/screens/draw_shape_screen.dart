import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';
import '../services/shape_recognizer.dart';

class DrawShapeScreen extends BaseGameScreen {
  const DrawShapeScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'draw_shape',
          gameTitle: 'Draw What You Saw',
          domain: 'VISUAL_MEMORY',
          enableScroll: false, // Prevents parent scroll from intercepting canvas drawing gestures
        );

  @override
  BaseGameScreenState<DrawShapeScreen> createState() => _DrawShapeScreenState();
}

class _DrawShapeScreenState extends BaseGameScreenState<DrawShapeScreen> {
  String? _lastItemId;
  bool _isShowingPreview = true;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;
  bool _hasUsedRepeek = false;

  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _setupRound(GameItem item) {
    if (_lastItemId == item.id) return;
    _lastItemId = item.id;
    _strokes.clear();
    _currentStroke = [];
    _hasUsedRepeek = false;
    _startPreview(3);
  }

  void _startPreview(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _isShowingPreview = true;
      _countdownSeconds = seconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        t.cancel();
        setState(() {
          _isShowingPreview = false;
        });
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _evaluateAndSubmit(GameItem currentItem, String langCode) {
    const recognizer = ShapeRecognizer();
    final expectedShapeKey = currentItem.raw['shape'] as String? ?? 'circle';
    final eval = recognizer.evaluate(
      expectedShapeKey: expectedShapeKey,
      strokes: _strokes,
      languageCode: langCode,
    );

    submitAnswer(
      isCorrect: eval.isMatch,
      feedbackTitle: eval.feedbackTitle,
      explanation: eval.feedbackMessage,
    );
  }

  String _getShapeDisplayName(String shapeKey) {
    switch (shapeKey.toLowerCase()) {
      case 'circle':
        return 'Circle';
      case 'triangle':
        return 'Triangle';
      case 'square':
        return 'Square';
      case 'star':
        return 'Star';
      case 'diamond':
        return 'Diamond';
      case 'cone':
        return 'Shield / Cone';
      default:
        return 'Shape';
    }
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    _setupRound(currentItem);
    final shapeKey = currentItem.raw['shape'] as String? ?? 'circle';
    final shapeName = _getShapeDisplayName(shapeKey);

    if (_isShowingPreview) {
      // 5s calm countdown view
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Calm circular countdown ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _countdownSeconds / 3.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Text(
                  '$_countdownSeconds',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Shape illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryColor, width: 3),
              ),
              child: Center(
                child: _buildShapeIcon(shapeKey, size: 90),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              shapeName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Memorize this shape',
              style: TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _countdownTimer?.cancel();
                setState(() => _isShowingPreview = false);
              },
              child: const Text(
                'I am ready',
                style: TextStyle(fontSize: 20, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // Finger drawing canvas with touch clamping and opaque hit test behavior
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        const canvasHeight = 280.0;

        return Container(
          width: canvasWidth,
          height: canvasHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              key: const Key('draw_shape_canvas'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                final clampedX =
                    details.localPosition.dx.clamp(0.0, canvasWidth);
                final clampedY =
                    details.localPosition.dy.clamp(0.0, canvasHeight);
                setState(() {
                  _currentStroke = [Offset(clampedX, clampedY)];
                  _strokes.add(_currentStroke);
                });
              },
              onPanUpdate: (details) {
                final clampedX =
                    details.localPosition.dx.clamp(0.0, canvasWidth);
                final clampedY =
                    details.localPosition.dy.clamp(0.0, canvasHeight);
                setState(() {
                  _currentStroke.add(Offset(clampedX, clampedY));
                });
              },
              onPanEnd: (_) {
                setState(() {});
              },
              child: CustomPaint(
                painter: _DrawingPainter(strokes: _strokes),
                size: const Size(double.infinity, canvasHeight),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShapeIcon(String shapeKey, {required double size}) {
    switch (shapeKey) {
      case 'triangle':
        return Icon(Icons.change_history_rounded, size: size, color: AppTheme.primaryColor);
      case 'square':
        return Icon(Icons.crop_square_rounded, size: size, color: AppTheme.primaryColor);
      case 'star':
        return Icon(Icons.star_outline_rounded, size: size, color: AppTheme.primaryColor);
      case 'diamond':
        return Icon(Icons.diamond_outlined, size: size, color: AppTheme.primaryColor);
      case 'cone':
        return Icon(Icons.shield_outlined, size: size, color: AppTheme.primaryColor);
      default:
        return Icon(Icons.circle_outlined, size: size, color: AppTheme.primaryColor);
    }
  }

  @override
  Widget buildOptions(BuildContext context, GameItem currentItem) {
    if (_isShowingPreview) return const SizedBox.shrink();

    return Column(
      children: [
        // Action toolbar: Undo (80dp target), Clear (80dp target), Repeek
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Undo button
            Expanded(
              child: SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.undo_rounded, size: 28),
                  label: const Text('Undo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: _strokes.isNotEmpty
                      ? () {
                          setState(() => _strokes.removeLast());
                        }
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Clear button
            Expanded(
              child: SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 28),
                  label: const Text('Clear Canvas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: _strokes.isNotEmpty
                      ? () {
                          setState(() => _strokes.clear());
                        }
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Re-peek button ("Show again")
            Expanded(
              child: SizedBox(
                height: 80,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 26),
                  label: const Text('Show\nagain', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: !_hasUsedRepeek
                      ? () {
                          _hasUsedRepeek = true;
                          _startPreview(3);
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // "I'm Done" submit button (80dp height)
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 36),
            label: const Text(
              'I am Done',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _evaluateAndSubmit(
              currentItem,
              Localizations.localeOf(context).languageCode,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 12.0 // 12px thick smooth brush for elders
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 6.0, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
