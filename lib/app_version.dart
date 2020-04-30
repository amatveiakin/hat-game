import 'package:flutter/foundation.dart';
import 'package:hatgame/git_version.dart';

String get appVersion => gitVersion + _buildModeSuffix();

String buildMode() {
  if (kReleaseMode) {
    return 'release';
  } else if (kDebugMode) {
    return 'debug';
  } else if (kProfileMode) {
    return 'profile';
  } else {
    return 'unknown_built_type';
  }
}

String _buildModeSuffix() {
  return kReleaseMode ? '' : ':' + buildMode();
}
