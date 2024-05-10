import 'package:flutter/foundation.dart';
import 'package:hatgame/git_version.dart';
import 'package:hatgame/util/strings.dart';

const _buildModeSuffix = kReleaseMode
    ? ''
    : kDebugMode
        ? '-debug'
        : kProfileMode
            ? '-profile'
            : '-unknownbuild';
const String appVersion = gitVersion + _buildModeSuffix;

String? _extractMainVersionPart(String v) {
  final re = RegExp(r'(v[0-9]+\.[0-9]+)');
  return re.matchAsPrefix(v)?.group(0);
}

versionsCompatible(String v1, String v2) {
  final String? v1Main = _extractMainVersionPart(v1);
  final String? v2Main = _extractMainVersionPart(v2);
  return !isNullOrEmpty(v1Main) && !isNullOrEmpty(v2Main) && v1Main == v2Main;
}
