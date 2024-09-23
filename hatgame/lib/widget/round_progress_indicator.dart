import 'dart:math';

import 'package:flutter/material.dart';

const double widgetWidth = 120.0;
const int maxDiscreteRounds = 12;
const double inactiveRadius = 5.4;
const double activeRadius = 9.2;
const double activePadding = 1.8;
const double lineThickness = 2.4;
const double inactiveThickness = 2.0;
const double activeThickness = 2.6;

// TODO: Instead of filling empty circles with background color, find a way to
// actually keep them empty. Ideas: smth BlendMode, smth ClipPath or just
// manually split the line into segments.
// TODO: Consider adapting width to the number of rounds, something like:
//   min(max(minWidth, numRounds * optimalSpacing), maxWidth, parentWidth)
// where parentWidth is taken from LayoutBuilder.
class RoundProgressIndicator extends StatelessWidget {
  final int roundIndex;
  final int numRounds;
  final double roundProgress;
  final Color backgroundColor;
  final Color baseColor;
  final Color highlightColor;

  RoundProgressIndicator({
    Key? key,
    required this.roundIndex,
    required this.numRounds,
    required this.roundProgress,
    required this.backgroundColor,
    required this.baseColor,
    required this.highlightColor,
  }) : super(key: key) {
    assert(roundIndex >= 0);
    assert(roundIndex < numRounds);
    assert(roundProgress >= 0.0);
    assert(roundProgress <= 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widgetWidth, activeRadius * 2),
      painter: _RoundProgressIndicatorPainter(
        roundIndex: roundIndex,
        numRounds: numRounds,
        roundProgress: roundProgress,
        backgroundColor: backgroundColor,
        baseColor: baseColor,
        highlightColor: highlightColor,
      ),
    );
  }
}

class _RoundProgressIndicatorPainter extends CustomPainter {
  final int roundIndex;
  final int numRounds;
  final double roundProgress;
  final Color backgroundColor;
  final Color baseColor;
  final Color highlightColor;

  _RoundProgressIndicatorPainter({
    required this.roundIndex,
    required this.numRounds,
    required this.roundProgress,
    required this.backgroundColor,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Offset.zero & size;
    final innerRect = outerRect.deflate(activeRadius);
    final backgroundFill = _fill(backgroundColor);
    final inactiveFill = _fill(baseColor);
    final activeBackgroundFill =
        _fill(Color.lerp(backgroundColor, highlightColor, 0.1)!);
    final activeFill = _fill(highlightColor);
    final lineStroke = _stroke(baseColor, lineThickness);
    final inactiveStroke = _stroke(baseColor, inactiveThickness);
    final activeStroke = _stroke(highlightColor, activeThickness);

    final circleCenter = (int i) {
      if (numRounds == 1) {
        return innerRect.center;
      }
      final dx = innerRect.left + i * innerRect.width / (numRounds - 1);
      var dy = innerRect.center.dy;
      if (i < roundIndex) {
        return Offset(dx - activePadding, dy);
      } else if (i == roundIndex) {
        return Offset(dx, dy);
      } else {
        return Offset(dx + activePadding, dy);
      }
    };

    final drawCircle = (int i) {
      final c = circleCenter(i);
      final r = (i == roundIndex) ? activeRadius : inactiveRadius;
      if (i < roundIndex) {
        canvas.drawCircle(c, r, inactiveFill);
        canvas.drawCircle(c, r, inactiveStroke);
      } else if (i == roundIndex) {
        canvas.drawCircle(c, r, activeBackgroundFill);
        canvas.drawArc(Rect.fromCenter(center: c, width: 2 * r, height: 2 * r),
            -pi / 2, roundProgress * 2 * pi, true, activeFill);
        canvas.drawCircle(c, r, activeStroke);
      } else {
        canvas.drawCircle(c, r, backgroundFill);
        canvas.drawCircle(c, r, inactiveStroke);
      }
    };

    if (numRounds <= maxDiscreteRounds) {
      canvas.drawLine(innerRect.centerLeft, innerRect.centerRight, lineStroke);
      for (int i = 0; i < numRounds; i++) {
        if (i != roundIndex) {
          drawCircle(i);
        }
      }
      drawCircle(roundIndex);
    } else {
      final topLeft = outerRect.centerLeft - Offset(0, inactiveRadius);
      final bottomRight = outerRect.centerRight + Offset(0, inactiveRadius);
      final radius = Radius.circular(inactiveRadius);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromPoints(
                  topLeft, Offset(circleCenter(roundIndex).dx, bottomRight.dy)),
              radius),
          inactiveFill);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromPoints(topLeft, bottomRight), radius),
          inactiveStroke);
      drawCircle(roundIndex);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Paint _stroke(Color color, double width) {
  return Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke;
}

Paint _fill(Color color) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.fill;
}
