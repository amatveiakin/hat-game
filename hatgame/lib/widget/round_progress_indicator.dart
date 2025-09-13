import 'dart:math';

import 'package:flutter/material.dart';

const double desiredWidgetWidth = 120.0;
const double minWidgetWidth = 100.0;
const double maxWidgetWidth = 240.0;
const double desiredSegmentWidth = 40.0;
const int maxDiscreteRounds = 12;
const double inactiveHeight = 4.0;
const double activeHeight = 8.0;
const double maxPadding = 2.0;

class RoundProgressIndicator extends StatelessWidget {
  final int roundIndex;
  final int numRounds;
  final double roundProgress;
  final Color baseColor;
  final Color completionColor;

  RoundProgressIndicator({
    super.key,
    required this.roundIndex,
    required this.numRounds,
    required this.roundProgress,
    required this.baseColor,
    required this.completionColor,
  }) {
    assert(roundIndex >= 0);
    assert(roundIndex < numRounds);
    assert(roundProgress >= 0.0);
    assert(roundProgress <= 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final desiredWidth =
          (numRounds * desiredSegmentWidth + desiredWidgetWidth) / 2;
      final maxWidth = min(maxWidgetWidth, constraints.maxWidth);
      final width = desiredWidth.clamp(minWidgetWidth, maxWidth);
      return CustomPaint(
        size: Size(width, activeHeight),
        painter: _RoundProgressIndicatorPainter(
          roundIndex: roundIndex,
          numRounds: numRounds,
          roundProgress: roundProgress,
          baseColor: baseColor,
          completionColor: completionColor,
        ),
      );
    });
  }
}

class _RoundProgressIndicatorPainter extends CustomPainter {
  final int roundIndex;
  final int numRounds;
  final double roundProgress;
  final Color baseColor;
  final Color completionColor;

  _RoundProgressIndicatorPainter({
    required this.roundIndex,
    required this.numRounds,
    required this.roundProgress,
    required this.baseColor,
    required this.completionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final canvasRect = Offset.zero & size;
    final centerY = canvasRect.center.dy;
    final inactiveFill = _fill(baseColor);
    final completedFill = _fill(completionColor);

    // TODO: Improve support for a huge (100+) number of rounds: add minimum
    // active segment width; draw two monolithic rects for the inactive rounds
    // when inactive round segments become too small.
    final w = canvasRect.width / numRounds;
    for (int i = 0; i < numRounds; i++) {
      final padding = min(maxPadding, w * 0.08);
      final left = canvasRect.left + i * w + padding;
      final right = canvasRect.left + (i + 1) * w - padding;
      final h = (i == roundIndex) ? activeHeight : inactiveHeight;
      final rect = Rect.fromLTRB(left, centerY - h / 2, right, centerY + h / 2);
      final rrect =
          RRect.fromRectAndRadius(rect, Radius.circular(min(w, h) * 0.7));
      if (i < roundIndex) {
        canvas.drawRRect(rrect, completedFill);
      } else if (i == roundIndex) {
        // Is is recommended to use `saveLayer` with clipping:
        // https://api.flutter.dev/flutter/dart-ui/Canvas/saveLayer.html
        canvas.save();
        canvas.clipRRect(rrect);
        canvas.saveLayer(rect, Paint());
        canvas.drawRect(rect, inactiveFill);
        canvas.drawRect(
            rect.topLeft & Size(rect.width * roundProgress, rect.height),
            completedFill);
        canvas.restore();
        canvas.restore();
      } else {
        canvas.drawRRect(rrect, inactiveFill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Paint _fill(Color color) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.fill;
}
