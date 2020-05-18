import 'package:hatgame/util/invalid_operation.dart';
import 'package:unicode/unicode.dart' as unicode;

InvalidOperation checkPlayerName(String name) {
  if (name.isEmpty) {
    return InvalidOperation('Player name is empty');
  }
  if (name.length > 50) {
    return InvalidOperation('Player name too long');
  }
  for (final c in name.codeUnits) {
    if (unicode.isControl(c) || unicode.isFormat(c)) {
      return InvalidOperation('Player name contans invalid character: '
          '${String.fromCharCode(c)} (code $c)');
    }
  }
  return null;
}

// TODO: Save to some persistent storage.
class LocalConfig {
  static final singleton = LocalConfig();

  String lastPlayerName;
}
