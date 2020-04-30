import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/util/assertion.dart';

// =============================================================================
// API

abstract class DBColumn<T> {
  T data;

  String get name;

  String serialize(T value);
  T deserialize(String serialized);

  setData(T newData) {
    Assert.holds(data == null);
    Assert.holds(newData != null);
    data = newData;
    return this;
  }
}

bool dbContains<T>(DocumentSnapshot snapshot, DBColumn<T> column) {
  return snapshot.data.containsKey(column.name);
}

T dbGet<T>(DocumentSnapshot snapshot, DBColumn<T> column) {
  Assert.holds(dbContains(snapshot, column),
      lazyMessage: () => 'Column ${column.name} not found in '
          '${snapshot.reference.path}. Content: ${snapshot.data.toString()}');
  return column.deserialize(snapshot.data[column.name]);
}

T dbTryGet<T>(DocumentSnapshot snapshot, DBColumn<T> column) {
  return dbContains(snapshot, column) ? dbGet(snapshot, column) : null;
}

Map<String, dynamic> dbData(List<DBColumn> columns) {
  final result = Map<String, dynamic>();
  for (final c in columns) {
    result[c.name] = c.serialize(c.data);
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

class DBColPlayer extends DBColumnBuiltValue<PersonalState> {
  final int playerID;
  DBColPlayer(this.playerID);
  String get name => 'player-$playerID';
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
