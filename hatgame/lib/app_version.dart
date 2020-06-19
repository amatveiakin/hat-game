import 'package:flutter/foundation.dart';
import 'package:hatgame/git_version.dart';
import 'package:hatgame/util/strings.dart';

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

String _extractMainVersionPart(String v) {
  final re = RegExp(r'(v[0-9]+\.[0-9]+)');
  return re.matchAsPrefix(v)?.group(0);
}

versionsCompatibile(String v1, String v2) {
  final String v1Main = _extractMainVersionPart(v1);
  final String v2Main = _extractMainVersionPart(v2);
  return !isNullOrEmpty(v1Main) && !isNullOrEmpty(v2Main) && v1Main == v2Main;
}
