import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';

// This doesn't work on web for now. Error:
//     Unsupported operation: InternetAddress.lookup
// Related issue: https://github.com/flutter/flutter/issues/39998.
//
// Note: I've also tried the true_time package that claims to support web,
// but it hanged during TrueTime.init(), at least in debug web version.
//
class NtpTime {
  static Duration _ntpOffset;

  static init() async {
    try {
      final int _offsetMilliseconds =
          await NTP.getNtpOffset().timeout(Duration(seconds: 3));
      _ntpOffset = Duration(milliseconds: _offsetMilliseconds);
      debugPrint('NTP time offset = $_ntpOffset');
    } catch (e) {
      // TODO: Firebase log.
      // TODO: Investigate how often this happens.
      debugPrint("Couldn't get NTP time offset! This means, in online game "
          "you wouldn't see the timer when somebody else is explaining "
          "and nobody else will see the timer when you're explaining.");
      debugPrint('The error was: $e');
    }
  }

  static test_setInitialized(bool initialized) {
    _ntpOffset = initialized ? Duration.zero : null;
    debugPrint("NTP running in test mode, initialized = $initialized.");
  }

  static bool get initialized => _ntpOffset != null;

  static DateTime nowUtcOrNull() =>
      _ntpOffset == null ? null : DateTime.now().toUtc().add(_ntpOffset);

  static DateTime nowUtcOrThrow() => DateTime.now().toUtc().add(_ntpOffset);

  static DateTime nowUtcNoPrecisionGuarantee() =>
      DateTime.now().toUtc().add(_ntpOffset ?? Duration.zero);
}
