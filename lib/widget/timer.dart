import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/colors.dart';

enum TimerViewStyle {
  turnTime,
  bonusTime,
}

class _TimerPainter extends CustomPainter {
  final TimerViewStyle style;
  final double progress; // from 0 to 1

  _TimerPainter(this.style, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (style == TimerViewStyle.turnTime) {
      final paint = Paint()
        ..color = MyColors.black(220)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.butt;
      canvas.drawOval(rect, paint);
      paint..color = MyColors.black(140);
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, paint);
    } else {
      final paint = Paint()
        ..color = MyTheme.primary.withOpacity(0.7)
        ..style = PaintingStyle.fill
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.butt;
      canvas.drawOval(rect, paint);
      paint..color = MyTheme.primary;
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, true, paint);
    }
  }

  @override
  bool shouldRepaint(_TimerPainter oldPainter) {
    return style != oldPainter.style || progress != oldPainter.progress;
  }
}

class TimerView extends StatefulWidget {
  final TimerViewStyle style;
  final Duration duration;
  final void Function() onTimeEnded;
  final void Function(bool) onRunningChanged;

  TimerView(
      {@required this.style,
      @required this.duration,
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

  bool _canPause() {
    return widget.style == TimerViewStyle.turnTime;
  }

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
    Assert.holds(_canPause());
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
      painter: _TimerPainter(widget.style, _progress),
      isComplex: false,
      willChange: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canPause() ? _togglePause : null,
        child: SizedBox.fromSize(
          size: Size.square(
              widget.style == TimerViewStyle.turnTime ? 140.0 : 80.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _seconds.toString(),
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:
                        widget.style == TimerViewStyle.turnTime ? 42.0 : 32.0,
                    color: widget.style == TimerViewStyle.turnTime
                        ? MyColors.black(140)
                        : MyColors.black(220),
                  ),
                ),
                if (_canPause())
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
