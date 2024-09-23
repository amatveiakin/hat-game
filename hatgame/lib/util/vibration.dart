import 'package:hatgame/util/assertion.dart';
import 'package:vibration/vibration.dart';

class MyVibration {
  static Future<void> heavyVibration() async {
    try {
      if ((await Vibration.hasVibrator()) != true) {
        return;
      }
      await Vibration.vibrate(duration: 500, amplitude: 255);
    } catch (e) {
      _logVibrationError(e);
    }
  }

  static Future<void> mediumVibration() async {
    try {
      if ((await Vibration.hasVibrator()) != true) {
        return;
      }
      if ((await Vibration.hasAmplitudeControl()) == true) {
        await Vibration.vibrate(duration: 300, amplitude: 192);
      } else {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      _logVibrationError(e);
    }
  }

  static void _logVibrationError(Object e) {
    Assert.failDebug('Vibration plugin failed with: ${e.toString()}',
        inRelease: AssertInRelease.log);
  }
}
