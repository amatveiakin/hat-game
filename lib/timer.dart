import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/colors.dart';
import 'package:hatgame/theme.dart';

class _TimerPainter extends CustomPainter {
  final double progress; // from 0 to 1

  _TimerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcPaint = Paint()
      ..color = MyColors.black(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.butt;
    final backgroundPaint = Paint()
      ..color = MyColors.black(220)
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
  final void Function() onTimeEnded;
  final void Function(bool) onRunningChanged;

  TimerView(
      {@required this.duration,
      @required this.onTimeEnded,
      this.onRunningChanged});

  @override
  createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  int _seconds = 0;
  bool _timeEnded = false;
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
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Assert.holds(!_timeEnded);
          _timeEnded = true;
          widget.onTimeEnded?.call();
        }
      });
    _animationController.forward();
  }

  bool _isRunning() {
    return _animationController.isAnimating;
  }

  void _togglePause() {
    if (_timeEnded) {
      return;
    }

    setState(() {
      if (_isRunning()) {
        _animationController.stop();
      } else {
        _animationController.forward();
      }
    });
    widget.onRunningChanged(_isRunning());
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TimerPainter(_progress),
      isComplex: false,
      willChange: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePause,
        child: SizedBox.fromSize(
          size: Size.square(140.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _seconds.toString(),
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 42.0,
                    color: MyColors.black(140),
                  ),
                ),
                Icon(
                  _isRunning() ? Icons.pause : Icons.play_arrow,
                  size: 32.0,
                  color: MyTheme.accent,
                )
              ],
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
