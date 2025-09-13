import 'package:flutter/material.dart';

// Produces text with underlined and overlined parts that look like this:
//
//       ╭───╮
//   pluralias
//   ╰────╯
//
class DecoratedText extends StatelessWidget {
  final String text;
  final int? highlightFirst;
  final int? highlightLast;
  final Color lineColor;
  final double lineThickness;
  final double cornerRadius;
  final TextStyle? textStyle;

  const DecoratedText({
    super.key,
    required this.text,
    required this.highlightFirst,
    required this.highlightLast,
    required this.lineColor,
    this.lineThickness = 2.0,
    this.cornerRadius = 4.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DecorationPainter(
        text: text,
        highlightFirst: highlightFirst,
        highlightLast: highlightLast,
        textStyle: textStyle ?? DefaultTextStyle.of(context).style,
        lineColor: lineColor,
        lineThickness: lineThickness,
        cornerRadius: cornerRadius,
      ),
      child: Text(text, style: textStyle),
    );
  }
}

class _DecorationPainter extends CustomPainter {
  final String text;
  final int? highlightFirst;
  final int? highlightLast;
  final TextStyle textStyle;
  final Color lineColor;
  final double lineThickness;
  final double cornerRadius;

  _DecorationPainter({
    required this.text,
    this.highlightFirst,
    this.highlightLast,
    required this.textStyle,
    required this.lineColor,
    required this.lineThickness,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineThickness
      ..strokeCap = StrokeCap.round;

    if (highlightFirst != null) {
      final underlineRect = _getTextRect(textPainter, 0, highlightFirst!);
      _drawRoundedUnderline(canvas, underlineRect, paint);
    }

    if (highlightLast != null) {
      final overlineRect =
          _getTextRect(textPainter, text.length - highlightLast!, text.length);
      _drawRoundedOverline(canvas, overlineRect, paint);
    }
  }

  Rect _getTextRect(TextPainter textPainter, int start, int end) {
    const verticalPadding = 2.0;
    final startOffset =
        textPainter.getOffsetForCaret(TextPosition(offset: start), Rect.zero);
    final endOffset =
        textPainter.getOffsetForCaret(TextPosition(offset: end), Rect.zero);

    return Rect.fromPoints(
      startOffset + Offset(0, -verticalPadding),
      endOffset + Offset(0, textPainter.height + verticalPadding),
    );
  }

  void _drawRoundedUnderline(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()
      ..moveTo(rect.left, rect.bottom - cornerRadius)
      ..arcToPoint(
        Offset(rect.left + cornerRadius, rect.bottom),
        radius: Radius.circular(cornerRadius),
        clockwise: false,
      )
      ..lineTo(rect.right - cornerRadius, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: false,
      );

    canvas.drawPath(path, paint);
  }

  void _drawRoundedOverline(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()
      ..moveTo(rect.left, rect.top + cornerRadius)
      ..arcToPoint(
        Offset(rect.left + cornerRadius, rect.top),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      )
      ..lineTo(rect.right - cornerRadius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + cornerRadius),
        radius: Radius.circular(cornerRadius),
        clockwise: true,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
