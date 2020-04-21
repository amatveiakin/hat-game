import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hatgame/colors.dart';
import 'package:hatgame/theme.dart';

// TODO: Add dynamism: padlock shacking / circle pulsating.

class _PadlockPainter extends CustomPainter {
  final bool padlockOpen;
  final Offset padlockPos;

  _PadlockPainter(this.padlockOpen, this.padlockPos);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var borderPaint = Paint()
      ..color = MyColors.black(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.butt;
    if (padlockOpen) {
      borderPaint..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);
    }
    canvas.drawOval(rect, borderPaint);

    final icon = padlockOpen ? Icons.lock_open : Icons.lock_outline;
    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 60.0,
          fontFamily: icon.fontFamily,
          color: MyTheme.accent,
        ));
    textPainter.layout();
    textPainter.paint(
        canvas, padlockPos - textPainter.size.center(Offset.zero));
  }

  @override
  bool shouldRepaint(_PadlockPainter oldPainter) {
    return padlockOpen != oldPainter.padlockOpen ||
        padlockPos != oldPainter.padlockPos;
  }
}

class Padlock extends StatefulWidget {
  final void Function() onUnlocked;

  Padlock({@required this.onUnlocked});

  @override
  createState() => _PadlockState();
}

class _PadlockState extends State<Padlock> {
  static const double _dragStartTolerance = 50.0;
  Size _size = Size.zero;
  bool _panActive = false;
  bool _padlockOpen = false;
  bool _padlockHidden = false;
  Offset _padlockPos;

  // Use didChangeDependencies instead of initState, because MediaQuery
  // is not available in the latter.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double side =
        min(200, MediaQuery.of(context).size.shortestSide * 0.6);
    _size = Size.square(side);
    _resetPadlockPos();
  }

  void _resetPadlockPos() {
    _setPadlockPos(_size.center(Offset.zero));
  }

  void _setPadlockPos(Offset pos) {
    final radius = _size.height / 2;
    final center = _size.center(Offset.zero);
    final v = pos - center;
    if (v.distance < radius) {
      _padlockOpen = false;
      _padlockPos = pos;
    } else {
      _padlockOpen = true;
      _padlockPos = center + v / v.distance * radius;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _padlockHidden
        ? SizedBox.fromSize(
            size: _size,
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (DragStartDetails details) {
              assert(!_panActive);
              if ((details.localPosition - _padlockPos).distance <
                  _dragStartTolerance) {
                setState(() {
                  _panActive = true;
                });
              }
            },
            onPanUpdate: (DragUpdateDetails details) {
              if (_panActive) {
                setState(() {
                  _setPadlockPos(details.localPosition);
                });
              }
            },
            onPanEnd: (DragEndDetails details) {
              final padlockOpen = _padlockOpen;
              setState(() {
                _panActive = false;
                _resetPadlockPos();
                if (padlockOpen) {
                  _padlockHidden = true;
                }
              });
              if (padlockOpen) {
                widget.onUnlocked();
              }
            },
            child: CustomPaint(
              painter: _PadlockPainter(_padlockOpen, _padlockPos),
              isComplex: false,
              willChange: true,
              child: SizedBox.fromSize(
                size: _size,
              ),
            ),
          );
  }
}
