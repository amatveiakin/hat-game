import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/assets.dart';

class _PadlockPainter extends CustomPainter {
  final ui.Image background;
  final ui.Image foreground;
  final int? wordsInHat;
  final bool padlockOpen;
  final Offset padlockPos;
  final bool panActive;
  final double animationProgress;

  _PadlockPainter(
      this.wordsInHat,
      this.background,
      this.foreground,
      this.padlockOpen,
      this.padlockPos,
      this.panActive,
      this.animationProgress);

  @override
  void paint(Canvas canvas, Size size) {
    const paperSize = Size(0.27, 0.42);
    final side = min(size.width, size.height);
    // Leave empty space above the hat to make paper area draggable.
    final spaceAbove = side * 0.2;
    final center =
        size.center(Offset.zero) - Size.square(side).center(Offset.zero);
    final hatRect = Rect.fromLTRB(0, spaceAbove, side, side).shift(center);

    drawHat(ui.Image image) {
      paintImage(
          canvas: canvas, rect: hatRect, image: image, fit: BoxFit.scaleDown);
    }
    drawPaper(int? showThreshold, Offset pos, double angle) {
      if (showThreshold != null && wordsInHat != null) {
        if (wordsInHat! < showThreshold) {
          return;
        }
      }
      final unitRect = (pos - paperSize.center(Offset.zero)) & paperSize;
      final dstRect = _scaleRect(unitRect, side, side).shift(center);
      final fill = Paint()
        ..color = Color(0xffe2dec8)
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = Color(0xff404040)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      _drawRotatedRect(canvas, dstRect, angle, fill, stroke);
    }

    final primaryAnimationProgress = panActive ? 0.0 : animationProgress;
    final primaryJump =
        sin(Curves.slowMiddle.transform(primaryAnimationProgress) * pi) * 0.2;
    final primaryAngle =
        sin(_easeInOutLinear(primaryAnimationProgress) * 4.0 * pi) * 6.0;
    final secondaryAngle = sin(animationProgress * 4 * pi) * 2.0;
    drawHat(background);
    drawPaper(4, Offset(0.42, 0.41), -8.0 + secondaryAngle);
    drawPaper(2, Offset(0.58, 0.39), 4.0 - secondaryAngle);
    drawPaper(5, Offset(0.55, 0.46), 2.0 + secondaryAngle);
    drawPaper(
        null,
        (padlockPos - center) * (1.0 / side) + Offset(0, -primaryJump),
        primaryAngle);
    drawPaper(3, Offset(0.45, 0.51), -3.0 - secondaryAngle);
    drawHat(foreground);
  }

  @override
  bool shouldRepaint(_PadlockPainter oldPainter) {
    return wordsInHat != oldPainter.wordsInHat ||
        padlockOpen != oldPainter.padlockOpen ||
        padlockPos != oldPainter.padlockPos ||
        panActive != oldPainter.panActive ||
        animationProgress != oldPainter.animationProgress;
  }
}

class Padlock extends StatefulWidget {
  final Size size;
  final AnimationController animationController;
  final void Function() onUnlocked;
  final int? wordsInHat;
  final ValueNotifier<bool>? readyToOpen;

  const Padlock(
      {super.key,
      required this.size,
      required this.onUnlocked,
      required this.animationController,
      this.wordsInHat,
      this.readyToOpen});

  @override
  createState() => PadlockState();
}

class PadlockState extends State<Padlock> with SingleTickerProviderStateMixin {
  static const double _dragStartTolerance = 50.0;
  late final Future<ui.Image> _background =
      loadAssetImage('images/hat_with_words_bg.png');
  late final Future<ui.Image> _foreground =
      loadAssetImage('images/hat_with_words_fg.png');
  bool _panActive = false;
  bool _padlockOpen = false;
  bool _padlockHidden = false;
  late Offset _padlockPos;

  var _animationProgress = 0.0;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _resetPadlockPos(false);
    _animation = Tween(begin: 0.0, end: 1.0).animate(widget.animationController)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _animationProgress = _animation.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _doDispose();
    super.dispose();
  }

  void _doDispose() async {
    (await _background).dispose();
    (await _foreground).dispose();
  }

  void _resetPadlockPos(bool notify) {
    final size = widget.size;
    final side = min(size.width, size.height);
    _setPadlockPos(size.center(Offset(0, -side * 0.2)), notify);
  }

  void _setPadlockPos(Offset pos, bool notify) {
    final size = widget.size;
    final side = min(size.width, size.height);
    final unlockHeight = size.height * 0.4;
    final center = size.center(Offset.zero);
    final minY = center.dy - side * 0.12;
    final y = min(pos.dy, minY);
    final maxDx = 2.0 * pow(minY - y, 2) / size.width;
    // Make sure the paper does not overlap with the hat.
    final x = pos.dx.clamp(center.dx - maxDx, center.dx + maxDx);
    _padlockPos = Offset(x, y);
    _padlockOpen = pos.dy <= center.dy - unlockHeight;
    if (notify && widget.readyToOpen != null) {
      widget.readyToOpen!.value = _padlockOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    if (_padlockHidden) {
      return SizedBox.fromSize(
        size: size,
      );
    }
    return FutureBuilder(
        future: Future.wait([_background, _foreground]),
        builder: (context, AsyncSnapshot<List<ui.Image>> snapshot) {
          if (!snapshot.hasData) {
            return SizedBox.fromSize(
              size: size,
            );
          }
          final [background, foreground] = snapshot.data!;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (DragStartDetails details) {
              Assert.holds(!_panActive);
              final center = size.center(Offset.zero);
              // Make the start region vertically prolonged to allow either
              // dragging the piece of paper itself, or dragging something out
              // of the hat.
              if ((details.localPosition - _padlockPos).distance +
                      (details.localPosition - center).distance <
                  (_padlockPos - center).distance + 2.0 * _dragStartTolerance) {
                setState(() {
                  _panActive = true;
                });
              }
            },
            onPanUpdate: (DragUpdateDetails details) {
              if (_panActive) {
                setState(() {
                  _setPadlockPos(details.localPosition, true);
                });
              }
            },
            onPanEnd: (DragEndDetails details) {
              final padlockOpen = _padlockOpen;
              setState(() {
                _panActive = false;
                _resetPadlockPos(true);
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
                  widget.wordsInHat,
                  background,
                  foreground,
                  _padlockOpen,
                  _padlockPos,
                  _panActive,
                  _animationProgress),
              isComplex: false,
              willChange: true,
              child: SizedBox.fromSize(
                size: size,
              ),
            ),
          );
        });
  }
}

double _easeInOutLinear(double x) {
  return ((x * 2.0) - 0.5).clamp(0.0, 1.0);
}

Rect _scaleRect(Rect rect, double scaleX, double scaleY) {
  return Rect.fromLTWH(
    rect.left * scaleX,
    rect.top * scaleY,
    rect.width * scaleX,
    rect.height * scaleY,
  );
}

// Draws a rectange rotated around center.
void _drawRotatedRect(
    Canvas canvas, Rect rect, double angle, Paint fill, Paint stroke) {
  canvas.save();
  final center = rect.center;
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle * (pi / 180.0));
  canvas.translate(-center.dx, -center.dy);
  canvas.drawRect(rect, fill);
  canvas.drawRect(rect, stroke);
  canvas.restore();
}
