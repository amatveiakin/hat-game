import 'dart:math';

import 'package:flutter/material.dart';

class HighlightableController {
  final _animationController;

  HighlightableController({required TickerProvider vsync})
      : _animationController = AnimationController(
          duration: const Duration(milliseconds: 700),
          vsync: vsync,
        );

  void highlight() {
    _animationController.reset();
    _animationController.forward();
  }

  void dispose() {
    _animationController.dispose();
  }
}

class Highlightable extends StatefulWidget {
  final Widget child;
  final HighlightableController controller;

  const Highlightable({
    Key? key,
    required this.child,
    required this.controller,
  }) : super(key: key);

  @override
  createState() => _HighlightableState();
}

class _HighlightableState extends State<Highlightable> {
  static const double animationRepetitions = 2;
  double _animationProgress = 0.0;
  late Animation<double> _animation;
  double _highlightStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _animation = Tween(begin: 0.0, end: 1.0)
        .animate(widget.controller._animationController)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _animationProgress = _animation.value;
            _highlightStrength = (1.0 -
                    cos(animationRepetitions * 2.0 * pi * _animationProgress)) /
                2.0;
          });
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _HighlightablePainter(_highlightStrength),
      child: widget.child,
    );
  }
}

class _HighlightablePainter extends CustomPainter {
  final double highlightStrength; // [0.0, 1.0]

  _HighlightablePainter(this.highlightStrength);

  @override
  void paint(Canvas canvas, Size size) {
    const double maxOpacity = 0.3;
    var paint = Paint()
      // TODO: Take the color form the theme.
      ..color = Colors.black.withOpacity(maxOpacity * highlightStrength)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_HighlightablePainter oldPainter) {
    return highlightStrength != oldPainter.highlightStrength;
  }
}
