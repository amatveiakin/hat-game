import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/util/assertion.dart';

// =============================================================================
// API

abstract class DBColumn<T> {
  String get name;

  String serialize(T value);
  T deserialize(String serialized);

  DBColumnData<T> withData(T data) {
    Assert.holds(data != null);
    return DBColumnData<T>(this, data);
  }
}

class DBColumnData<T> {
  final DBColumn<T> column;
  final T data;

  DBColumnData(this.column, this.data);
}

bool dbContains<T>(Map<String, dynamic> data, DBColumn<T> column) {
  return data.containsKey(column.name);
}

T dbGet<T>(Map<String, dynamic> data, DBColumn<T> column,
    {String documentPath}) {
  Assert.holds(dbContains(data, column),
      lazyMessage: () => documentPath != null
          ? 'Column "${column.name}" not found in "$documentPath". '
              'Content: "$data"'
          : 'Column "${column.name}" not found. Content: "$data"');
  return column.deserialize(data[column.name]);
}

T dbTryGet<T>(Map<String, dynamic> data, DBColumn<T> column) {
  return dbContains(data, column) ? dbGet(data, column) : null;
}

Map<String, dynamic> dbData(List<DBColumnData> columns) {
  final result = Map<String, dynamic>();
  for (final c in columns) {
    result[c.column.name] = c.column.serialize(c.data);
  }
  return result;
}

// =============================================================================
// Columns

class DBColCreationTimeUtc extends DBColumnString {
  String get name => 'creation_time_utc';
}

class DBColHostAppVersion extends DBColumnString {
  String get name => 'host_app_version';
}

class DBColConfig extends DBColumnBuiltValue<GameConfig> {
  String get name => 'config';
}

class DBColState extends DBColumnBuiltValue<GameState> {
  String get name => 'state';
}

// Per-player state in online mode.
class DBColPlayer extends DBColumnBuiltValue<PersonalState> {
  final int playerID;
  DBColPlayer(this.playerID);
  String get name => 'player-$playerID';
}

// Analog of DBColPlayer for offline mode. In offline mode there is no
// per-player state, so this column is separate from DBColState for the purely
// technical reason of trying to keep offline and online implementations close.
class DBColLocalPlayer extends DBColumnBuiltValue<PersonalState> {
  DBColLocalPlayer();
  String get name => 'additional_state';
}

// =============================================================================
// Implementation

abstract class DBColumnBuiltValue<T> extends DBColumn<T> {
  Serializer _serializer() => serializers.serializerForType(T);
  String serialize(T value) =>
      json.encode(serializers.serializeWith(_serializer(), value));
  T deserialize(String serialized) =>
      serializers.deserializeWith(_serializer(), json.decode(serialized));
}

abstract class DBColumnString extends DBColumn<String> {
  String serialize(String value) => value;
  String deserialize(String serialized) => serialized;
}
