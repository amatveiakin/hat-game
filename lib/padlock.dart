import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/colors.dart';
import 'package:hatgame/theme.dart';

List<BoxShadow> _elevationToShadow(int elevation, Color color) {
  return kElevationToShadow[elevation]
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
      ..color = Color.lerp(MyTheme.accent, MyColors.black(180), 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.butt;
    if (padlockOpen) {
      borderPaint
        ..color = MyTheme.accent
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);
    }
    canvas.drawOval(rect, borderPaint);

    double rotateAngle = 0.0;
    const double shakeStart = 0.5;
    const double shareDuration = 0.1;
    const double shakeReps = 4.0;
    const double shakeAmplitude = pi / 24;
    if (animationProgress > shakeStart &&
        animationProgress < shakeStart + shareDuration) {
      final double shakeProgress =
          (animationProgress - shakeStart) / shareDuration;
      rotateAngle = sin(shakeProgress * pi * shakeReps) * shakeAmplitude;
    }

    final icon = padlockOpen ? Icons.lock_open : Icons.lock_outline;
    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 60.0,
          fontFamily: icon.fontFamily,
          color: MyTheme.accent,
          shadows: _elevationToShadow(2, MyTheme.accent),
        ));
    textPainter.layout();

    canvas.save();
    canvas.translate(padlockPos.dx, padlockPos.dy);
    canvas.rotate(rotateAngle);
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
  final void Function() onUnlocked;

  Padlock({@required this.onUnlocked});

  @override
  createState() => _PadlockState();
}

class _PadlockState extends State<Padlock> with SingleTickerProviderStateMixin {
  static const double _dragStartTolerance = 50.0;
  Size _size = Size.zero;
  bool _panActive = false;
  bool _padlockOpen = false;
  bool _padlockHidden = false;
  Offset _padlockPos;

  var _animationProgress = 0.0;
  Animation<double> _animation;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(duration: Duration(seconds: 4), vsync: this);
    _animation =
        Tween(begin: 0.0, end: 1.0.toDouble()).animate(_animationController)
          ..addListener(() {
            setState(() {
              _animationProgress = _animation.value;
            });
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _animationController.repeat();
            }
          });
    _animationController.forward();
  }

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
              Assert.holds(!_panActive);
              if ((details.localPosition - _padlockPos).distance <
                  _dragStartTolerance) {
                setState(() {
                  _animationController.reset();
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
                } else {
                  _animationController.forward();
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
