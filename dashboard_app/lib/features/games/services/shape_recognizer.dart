import 'dart:math';
import 'package:flutter/material.dart';

/// Supported basic shapes for cognitive wellness drawing games.
enum RecognizedShape {
  circle,
  square,
  rectangle,
  triangle,
  line,
  unknown,
}

/// Evaluation result comparing expected shape with user's drawing.
class ShapeEvaluationResult {
  final bool isMatch;
  final RecognizedShape detectedShape;
  final String feedbackTitle;
  final String feedbackMessage;

  const ShapeEvaluationResult({
    required this.isMatch,
    required this.detectedShape,
    required this.feedbackTitle,
    required this.feedbackMessage,
  });
}

/// Robust, forgiving geometric shape analyzer designed for elderly handwriting & touch.
class ShapeRecognizer {
  const ShapeRecognizer();

  /// Classifies user drawing strokes into a [RecognizedShape].
  RecognizedShape recognize(List<List<Offset>> strokes) {
    // 1. Flatten and filter noise
    final points = <Offset>[];
    for (final stroke in strokes) {
      for (final pt in stroke) {
        if (points.isEmpty || (pt - points.last).distance >= 2.5) {
          points.add(pt);
        }
      }
    }

    if (points.length < 6) return RecognizedShape.unknown;

    // 2. Bounding box & dimensions
    double minX = points.first.dx, maxX = points.first.dx;
    double minY = points.first.dy, maxY = points.first.dy;
    double totalPathLength = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
      if (i > 0) {
        totalPathLength += (p - points[i - 1]).distance;
      }
    }

    final width = maxX - minX;
    final height = maxY - minY;
    final diagonal = sqrt(width * width + height * height);

    if (diagonal < 30.0 || totalPathLength < 40.0) {
      return RecognizedShape.unknown;
    }

    final aspectRatio = width / (height > 0 ? height : 1.0);

    // 3. Path closure analysis
    final startPoint = points.first;
    final endPoint = points.last;
    final closureDistance = (endPoint - startPoint).distance;

    // Path is closed if start and end are reasonably close relative to diagonal
    final isClosed = closureDistance <= (0.42 * diagonal);
    final isDistinctlyOpen = closureDistance > (0.48 * diagonal);

    // 4. Straightness analysis
    final straightDistance = (endPoint - startPoint).distance;
    final straightness = totalPathLength > 0 ? (straightDistance / totalPathLength) : 0.0;

    // 5. Centroid and radial consistency (circularity)
    double sumX = 0.0, sumY = 0.0;
    for (final p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    final centroid = Offset(sumX / points.length, sumY / points.length);

    double sumRadius = 0.0;
    for (final p in points) {
      sumRadius += (p - centroid).distance;
    }
    final meanRadius = sumRadius / points.length;

    double varianceSum = 0.0;
    for (final p in points) {
      final d = (p - centroid).distance;
      varianceSum += pow(d - meanRadius, 2);
    }
    final normalizedRadialVariance =
        meanRadius > 0 ? (varianceSum / points.length) / (meanRadius * meanRadius) : 1.0;

    // 6. Equidistant resampling & Corner detection
    final corners = _countCorners(points);

    // --- CLASSIFICATION LOGIC ---

    // A. LINE:
    // Open path, high straightness ratio, or strongly elongated aspect ratio
    if (isDistinctlyOpen && (straightness >= 0.68 || (aspectRatio > 2.8 || aspectRatio < 0.35))) {
      return RecognizedShape.line;
    }

    // B. CIRCLE:
    // Closed path, aspect ratio near 1.0, low radial variance (round <= 0.055), minimal corners (<=1)
    final isRoundRatio = aspectRatio >= 0.70 && aspectRatio <= 1.42;
    if (isClosed && isRoundRatio && normalizedRadialVariance <= 0.055 && corners <= 1 && straightness < 0.60) {
      return RecognizedShape.circle;
    }

    // C. TRIANGLE:
    // Closed path with 3 corners or triangular variance
    if (isClosed && (corners == 3 || (corners == 2 && normalizedRadialVariance >= 0.045))) {
      return RecognizedShape.triangle;
    }

    // D. SQUARE:
    // Closed path, aspect ratio near 1.0
    if (isClosed && aspectRatio >= 0.72 && aspectRatio <= 1.38) {
      return RecognizedShape.square;
    }

    // E. RECTANGLE:
    // Closed path, distinct aspect ratio != 1.0
    if (isClosed && (aspectRatio < 0.72 || aspectRatio > 1.38)) {
      return RecognizedShape.rectangle;
    }

    return RecognizedShape.unknown;
  }

  static List<Offset> _resample(List<Offset> points, int n) {
    if (points.length < 2) return points;
    double totalLen = 0;
    for (int i = 1; i < points.length; i++) {
      totalLen += (points[i] - points[i - 1]).distance;
    }
    final interval = totalLen / (n - 1);
    final res = <Offset>[points.first];
    double accumulated = 0;
    int currentIdx = 0;
    double segmentRemaining = (points[1] - points[0]).distance;

    for (int i = 1; i < n - 1; i++) {
      double target = i * interval;
      while (accumulated + segmentRemaining < target && currentIdx < points.length - 2) {
        accumulated += segmentRemaining;
        currentIdx++;
        segmentRemaining = (points[currentIdx + 1] - points[currentIdx]).distance;
      }
      double t = segmentRemaining > 0 ? (target - accumulated) / segmentRemaining : 0.0;
      res.add(points[currentIdx] + (points[currentIdx + 1] - points[currentIdx]) * t);
    }
    res.add(points.last);
    return res;
  }

  static int _countCorners(List<Offset> points) {
    if (points.length < 5) return 0;
    final sampled = _resample(points, 36);
    int corners = 0;
    bool inCorner = false;
    for (int i = 2; i < sampled.length - 2; i++) {
      final v1 = sampled[i] - sampled[i - 2];
      final v2 = sampled[i + 2] - sampled[i];
      final dot = v1.dx * v2.dx + v1.dy * v2.dy;
      final mag = v1.distance * v2.distance;
      if (mag > 0) {
        final cosA = (dot / mag).clamp(-1.0, 1.0);
        final angle = acos(cosA) * (180.0 / pi);
        if (angle >= 40.0) {
          if (!inCorner) {
            corners++;
            inCorner = true;
          }
        } else {
          inCorner = false;
        }
      }
    }
    final startEndDist = (sampled.last - sampled.first).distance;
    if (startEndDist < 30.0) {
      final v1 = sampled[sampled.length - 1] - sampled[sampled.length - 3];
      final v2 = sampled[2] - sampled[0];
      final dot = v1.dx * v2.dx + v1.dy * v2.dy;
      final mag = v1.distance * v2.distance;
      if (mag > 0) {
        final cosA = (dot / mag).clamp(-1.0, 1.0);
        final closeAngle = acos(cosA) * (180.0 / pi);
        if (closeAngle >= 40.0) {
          corners++;
        }
      }
    }
    return corners;
  }

  /// Evaluates user drawing against expected shape key ('circle', 'square', 'triangle', 'line', 'rectangle').
  ShapeEvaluationResult evaluate({
    required String expectedShapeKey,
    required List<List<Offset>> strokes,
    required String languageCode,
  }) {
    final cleanExpected = expectedShapeKey.toLowerCase().trim();
    final detected = recognize(strokes);

    bool isMatch = false;

    switch (cleanExpected) {
      case 'circle':
        isMatch = detected == RecognizedShape.circle;
        break;
      case 'line':
        isMatch = detected == RecognizedShape.line;
        break;
      case 'square':
        isMatch = detected == RecognizedShape.square;
        break;
      case 'rectangle':
        isMatch = detected == RecognizedShape.rectangle || detected == RecognizedShape.square;
        break;
      case 'triangle':
      case 'cone': // Japi cone resembles triangle
        isMatch = detected == RecognizedShape.triangle;
        break;
      case 'diamond':
        isMatch = detected == RecognizedShape.square || detected == RecognizedShape.triangle;
        break;
      default:
        // Forgiving fallback for complex shapes
        isMatch = detected != RecognizedShape.unknown;
    }

    final shapeName = _getShapeName(cleanExpected, languageCode);

    if (isMatch) {
      final title = languageCode == 'te'
          ? 'చక్కగా గీశారు!'
          : (languageCode == 'hi' ? 'बहुत बढ़िया!' : 'Great shape!');
      final message = languageCode == 'te'
          ? 'మీరు సరైన $shapeName ఆకారాన్ని గీశారు.'
          : (languageCode == 'hi'
              ? 'आपने बिल्कुल सही $shapeName बनाया है।'
              : 'Great! You drew the correct $shapeName.');
      return ShapeEvaluationResult(
        isMatch: true,
        detectedShape: detected,
        feedbackTitle: title,
        feedbackMessage: message,
      );
    } else {
      final title = languageCode == 'te'
          ? 'మరోసారి ప్రయత్నించండి'
          : (languageCode == 'hi' ? 'पुनः प्रयास करें' : 'Try again');
      final hint = _getShapeHint(cleanExpected, languageCode);
      final message = languageCode == 'te'
          ? 'ఇది $shapeName లాగా లేదు. $hint'
          : (languageCode == 'hi'
              ? 'यह $shapeName जैसा नहीं लग रहा है। $hint'
              : 'That\'s not quite a $shapeName. $hint');
      return ShapeEvaluationResult(
        isMatch: false,
        detectedShape: detected,
        feedbackTitle: title,
        feedbackMessage: message,
      );
    }
  }

  String _getShapeName(String shapeKey, String lang) {
    switch (shapeKey) {
      case 'circle':
        return lang == 'te' ? 'వృత్తం (సర్కిల్)' : (lang == 'hi' ? 'गोला (वृत्त)' : 'circle');
      case 'line':
        return lang == 'te' ? 'గీత (లైన్)' : (lang == 'hi' ? 'सीधी रेखा' : 'line');
      case 'triangle':
      case 'cone':
        return lang == 'te' ? 'త్రిభుజం' : (lang == 'hi' ? 'त्रिकोण' : 'triangle');
      case 'square':
        return lang == 'te' ? 'చతురస్రం' : (lang == 'hi' ? 'चौकोर (वर्ग)' : 'square');
      case 'rectangle':
        return lang == 'te' ? 'దీర్ఘచతురస్రం' : (lang == 'hi' ? 'आयत' : 'rectangle');
      default:
        return shapeKey;
    }
  }

  String _getShapeHint(String shapeKey, String lang) {
    switch (shapeKey) {
      case 'circle':
        return lang == 'te'
            ? 'గుండ్రంగా తిప్పుతూ మూసివున్న ఆకారాన్ని గీయండి.'
            : (lang == 'hi'
                ? 'एक गोल, बंद वक्र बनाने का प्रयास करें।'
                : 'Try drawing a single round, curved shape.');
      case 'line':
        return lang == 'te'
            ? 'ఒక వైపు నుండి మరొక వైపుకు నేరుగా గీత గీయండి.'
            : (lang == 'hi'
                ? 'एक सिरे से दूसरे सिरे तक सीधी लकीर खींचें।'
                : 'Try drawing a straight stroke from one side to the other.');
      case 'triangle':
      case 'cone':
        return lang == 'te'
            ? 'మూడు సరళమైన భుజాలు మరియు మూడు మూలలతో గీయండి.'
            : (lang == 'hi'
                ? 'तीन भुजाओं और तीन कोनों वाली आकृति बनाएं।'
                : 'Try drawing a shape with three sides and three corners.');
      case 'square':
        return lang == 'te'
            ? 'సమానమైన నాలుగు భుజాలు గల చతురస్రాన్ని గీయండి.'
            : (lang == 'hi'
                ? 'चार समान भुजाओं वाला चौकोर बनाएं।'
                : 'Try drawing a shape with four equal sides and corners.');
      case 'rectangle':
        return lang == 'te'
            ? 'నాలుగు భుజాలు గల వెడల్పైన లేదా పొడవైన ఆకారాన్ని గీయండి.'
            : (lang == 'hi'
                ? 'चार भुजाओं वाली थोड़ी लंबी आकृति बनाएं।'
                : 'Try drawing a four-sided shape that is wider or taller.');
      default:
        return 'Try matching the shape shown.';
    }
  }
}
