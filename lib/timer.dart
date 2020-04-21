import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';

class _TimerPainter extends CustomPainter {
  final double progress; // from 0 to 1

  _TimerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcPaint = Paint()
      ..color = MyColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.butt;
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.butt;
    canvas.drawOval(rect, backgroundPaint);
    canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, arcPaint);
  }

  @override
  bool shouldRepaint(_TimerPainter oldPainter) {
    return progress != oldPainter.progress;
  }
}

class TimerView extends StatefulWidget {
  final Duration duration;

  TimerView({@required this.duration});

  @override
  createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView>
    with SingleTickerProviderStateMixin {
  var _progress = 0.0;
  var _seconds = 0;
  Animation<double> _animation;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController)
      ..addListener(() {
        setState(() {
          _progress = _animation.value;
          _seconds = ((1.0 - _progress) * widget.duration.inSeconds).ceil();
        });
      });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TimerPainter(_progress),
      isComplex: false,
      willChange: true,
      child: SizedBox.fromSize(
        size: Size.square(120.0),
        child: Center(
          child: Text(
            _seconds.toString(),
            maxLines: 1,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 36.0,
              color: MyColors.accent,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
