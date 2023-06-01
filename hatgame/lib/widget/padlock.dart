import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/colors.dart';

List<BoxShadow> _elevationToShadow(int elevation, Color color) {
  return kElevationToShadow[elevation]!
      .map((s) => BoxShadow(
            color: color.withOpacity(s.color.opacity),
            offset: s.offset,
            blurRadius: s.blurRadius,
            spreadRadius: s.spreadRadius,
          ))
      .toList();
}

class _PadlockPainter extends CustomPainter {
  final bool padlockOpen;
  final Offset padlockPos;
  final double animationProgress;

  _PadlockPainter(this.padlockOpen, this.padlockPos, this.animationProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var borderPaint = Paint()
      ..color = Color.lerp(MyTheme.secondary, MyColors.black(180), 0.5)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    if (padlockOpen) {
      borderPaint
        ..color = MyTheme.secondary
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    }
    canvas.drawOval(rect, borderPaint);

    const double shakeReps = 4.0;
    const double shakeAmplitude = pi / 24;
    final double rotateAngle =
        sin(animationProgress * pi * shakeReps) * shakeAmplitude;

    const double maxSizeIncrement = 0.25;
    final double scale = 1.0 + sin(animationProgress * pi) * maxSizeIncrement;

    final icon = padlockOpen ? Icons.lock_open : Icons.lock_outline;
    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 72.0,
          fontFamily: icon.fontFamily,
          color: MyTheme.secondary,
          shadows: _elevationToShadow(2, MyTheme.secondary),
        ));
    textPainter.layout();

    canvas.save();
    canvas.translate(padlockPos.dx, padlockPos.dy);
    canvas.rotate(rotateAngle);
    canvas.scale(scale);
    textPainter.paint(canvas, -textPainter.size.center(Offset.zero));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PadlockPainter oldPainter) {
    return padlockOpen != oldPainter.padlockOpen ||
        padlockPos != oldPainter.padlockPos ||
        animationProgress != oldPainter.animationProgress;
  }
}

class Padlock extends StatefulWidget {
  final AnimationController animationController;
  final void Function() onUnlocked;

  const Padlock(
      {Key? key, required this.onUnlocked, required this.animationController})
      : super(key: key);

  @override
  createState() => PadlockState();
}

class PadlockState extends State<Padlock> with SingleTickerProviderStateMixin {
  static const double _dragStartTolerance = 50.0;
  bool _panActive = false;
  bool _padlockOpen = false;
  bool _padlockHidden = false;
  late Size _size;
  late Offset _padlockPos;

  var _animationProgress = 0.0;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = Tween(begin: 0.0, end: 1.0).animate(widget.animationController)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _animationProgress = _animation.value;
          });
        }
      });
  }

  // Use didChangeDependencies instead of initState, because MediaQuery
  // is not available in the latter.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TODO: Check available space rather then screen size: replace MediaQuery
    // with LayoutBuilder or FractionallySizedBox.
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
              Assert.holds(!_panActive);
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
              painter: _PadlockPainter(
                  _padlockOpen, _padlockPos, _animationProgress),
              isComplex: false,
              willChange: true,
              child: SizedBox.fromSize(
                size: _size,
              ),
            ),
          );
  }
}
