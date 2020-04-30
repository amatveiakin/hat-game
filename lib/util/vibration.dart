import 'package:hatgame/util/assertion.dart';
import 'package:vibration/vibration.dart';

class MyVibration {
  static heavyVibration() async {
    try {
      if (!await Vibration.hasVibrator()) {
        return;
      }
      await Vibration.vibrate(duration: 500, amplitude: 255);
    } catch (e) {
      _logVibrationError(e);
    }
  }

  static mediumVibration() async {
    try {
      if (!await Vibration.hasVibrator()) {
        return;
      }
      if (await Vibration.hasAmplitudeControl()) {
        await Vibration.vibrate(duration: 300, amplitude: 192);
      } else {
        await Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      _logVibrationError(e);
    }
  }

  static void _logVibrationError(e) {
    Assert.fail('Vibration plugin failed with: ${e.toString()}',
        inRelease: AssertInRelease.log);
  }
}
