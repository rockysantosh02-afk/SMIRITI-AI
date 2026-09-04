import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../base/base_game_screen.dart';
import '../models/game_item.dart';

class DrawShapeScreen extends BaseGameScreen {
  const DrawShapeScreen({super.key, super.initialDifficulty})
      : super(
          gameId: 'draw_shape',
          gameTitle: 'Draw What You Saw',
          gameTitleAs: 'মনত ৰাখি আঁকক',
          domain: 'VISUAL_MEMORY',
        );

  @override
  BaseGameScreenState<DrawShapeScreen> createState() => _DrawShapeScreenState();
}

class _DrawShapeScreenState extends BaseGameScreenState<DrawShapeScreen> {
  String? _lastItemId;
  bool _isShowingPreview = true;
  int _countdownSeconds = 5;
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
    _startPreview(5);
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

  void _evaluateAndSubmit() {
    // Forgiving engagement scoring: if at least 8 points or 1 stroke, pass!
    final totalPoints = _strokes.fold<int>(0, (sum, stroke) => sum + stroke.length);
    final passed = totalPoints >= 6;
    submitAnswer(isCorrect: passed);
  }

  @override
  Widget buildGameContent(BuildContext context, GameItem currentItem) {
    _setupRound(currentItem);
    final shapeKey = currentItem.raw['shape'] as String? ?? 'circle';
    final shapeName = currentItem.raw['shapeName'] as String? ?? 'আকৃতি (Shape)';

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
                    value: _countdownSeconds / 5.0,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'মন দি মনত ৰাখক (Memorize this shape)',
              style: TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _countdownTimer?.cancel();
                setState(() => _isShowingPreview = false);
              },
              child: const Text(
                'মই সাজু (I am ready)',
                style: TextStyle(fontSize: 18, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    // Finger drawing canvas
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 280,
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
              onPanStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                  _strokes.add(_currentStroke);
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              child: CustomPaint(
                painter: _DrawingPainter(strokes: _strokes),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
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
        // Action toolbar: Undo (min 80dp target), Clear (min 80dp target), Repeek
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Undo button
            SizedBox(
              height: 70,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.undo_rounded, size: 28),
                label: const Text('পূৰ্বৰ (Undo)', style: TextStyle(fontSize: 16)),
                onPressed: _strokes.isNotEmpty
                    ? () {
                        setState(() => _strokes.removeLast());
                      }
                    : null,
              ),
            ),

            // Clear button
            SizedBox(
              height: 70,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 28),
                label: const Text('মচি পেলাওক (Clear)', style: TextStyle(fontSize: 16)),
                onPressed: _strokes.isNotEmpty
                    ? () {
                        setState(() => _strokes.clear());
                      }
                    : null,
              ),
            ),

            // Re-peek button ("Show me again")
            SizedBox(
              height: 70,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.visibility_rounded, size: 28),
                label: const Text('আকৌ চাওক\n(Show again)', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                onPressed: !_hasUsedRepeek
                    ? () {
                        _hasUsedRepeek = true;
                        _startPreview(3);
                      }
                    : null,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 36),
            label: const Text(
              'অঁকা শেষ হ\'ল (I am Done)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            onPressed: _evaluateAndSubmit,
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
