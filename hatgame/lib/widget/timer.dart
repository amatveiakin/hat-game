import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/colors.dart';
import 'package:hatgame/util/duration.dart';

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
      paint.color = MyColors.black(140);
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, paint);
    } else {
      final paint = Paint()
        ..color = MyTheme.primary.withOpacity(0.7)
        ..style = PaintingStyle.fill
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.butt;
      canvas.drawOval(rect, paint);
      paint.color = MyTheme.primary;
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, true, paint);
    }
  }

  @override
  bool shouldRepaint(_TimerPainter oldPainter) {
    return style != oldPainter.style || progress != oldPainter.progress;
  }
}

// TODO: Test how Timer behaves when the app is minimized (esp. onTimeEnded).
class TimerView extends StatefulWidget {
  final TimerViewStyle style;
  final Duration duration;
  final Duration? startTime;
  final bool startPaused;
  final bool hideOnTimeEnded;
  final void Function()? onTimeEnded;
  final void Function(bool)? onRunningChanged;

  const TimerView(
      {super.key,
      required this.style,
      required this.duration,
      this.startTime = Duration.zero,
      this.startPaused = false,
      this.hideOnTimeEnded = false,
      this.onTimeEnded,
      this.onRunningChanged});

  @override
  createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView>
    with SingleTickerProviderStateMixin {
  TimerViewStyle get style => widget.style;
  Duration get duration => widget.duration;
  Duration? get startTime => widget.startTime;

  double _progress = 0.0;
  int _seconds = 0;
  bool _timeEnded = false;
  late Animation<double> _animation;
  late AnimationController _animationController;

  bool _canPause() {
    return widget.onRunningChanged != null && !_timeEnded;
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(duration: duration, vsync: this);
    _animationController.value = durationDiv(startTime!, duration);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController)
      ..addListener(() {
        setState(_updateProgress);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Assert.holds(!_timeEnded);
          setState(() {
            _timeEnded = true;
          });
          widget.onTimeEnded?.call();
        }
      });
    _updateProgress();
    if (!widget.startPaused) {
      _animationController.forward();
    }
  }

  bool _isRunning() {
    return _animationController.isAnimating;
  }

  void _updateProgress() {
    _progress = _animation.value;
    _seconds = ((1.0 - _progress) * duration.inSeconds).ceil();
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
    widget.onRunningChanged!(_isRunning());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canPause() ? _togglePause : null,
      child: SizedBox.fromSize(
        size: Size.square(style == TimerViewStyle.turnTime ? 140.0 : 80.0),
        child: widget.hideOnTimeEnded && _timeEnded
            ? Container()
            : CustomPaint(
                painter: _TimerPainter(style, _progress),
                isComplex: false,
                willChange: true,
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
                              style == TimerViewStyle.turnTime ? 42.0 : 32.0,
                          color: style == TimerViewStyle.turnTime
                              ? MyColors.black(140)
                              : MyColors.black(220),
                        ),
                      ),
                      if (_canPause())
                        Icon(
                          _isRunning() ? Icons.pause : Icons.play_arrow,
                          size: 32.0,
                          color: MyTheme.secondary,
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
