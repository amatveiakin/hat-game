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
  static Duration _offset;

  static init() async {
    try {
      final int _offsetMilliseconds =
          await NTP.getNtpOffset().timeout(Duration(seconds: 3));
      _offset = Duration(milliseconds: _offsetMilliseconds);
      debugPrint('NTP time offset = $_offset');
    } catch (e) {
      // TODO: Firebase log.
      // TODO: Investigate how often this happens.
      _offset = Duration.zero;
      debugPrint("Couldn't get NTP time offset! In online game this "
          "could lead to weird timer behavior for inactive players. "
          "The actual time accounting is done locally on the device of "
          "the player who is explaining and should not be affected.");
      debugPrint('The error was: $e');
    }
  }

  static DateTime nowUtc() {
    return DateTime.now().toUtc().add(_offset);
  }
}
