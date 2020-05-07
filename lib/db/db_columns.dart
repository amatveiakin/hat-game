import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/util/assertion.dart';

// =============================================================================
// API

abstract class DBColumn<T> {
  String get name;

  String serialize(T value) => value == null ? null : serializeImpl(value);
  T deserialize(String serialized) =>
      serialized == null ? null : deserializeImpl(serialized);

  @protected
  String serializeImpl(T value);
  @protected
  T deserializeImpl(String serialized);

  // Note: `data` can be null, in which case null is written to the DB.
  // This is similar, but not equivalent to removing the column (`dbTryGet`
  // doesn't distinguish between the two, but `dbContains` does).
  DBColumnData<T> withData(T data) {
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

class DBColInitialState extends DBColumnBuiltValue<InitialGameState> {
  String get name => 'initial_state';
}

class DBColTurnRecord extends DBColumnBuiltValue<TurnRecord> {
  final int turnID;
  DBColTurnRecord(this.turnID);
  String get name => 'turn-$turnID';
}

class DBColCurrentTurn extends DBColumnBuiltValue<TurnState> {
  String get name => 'turn_current';
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
  String serializeImpl(T value) =>
      json.encode(serializers.serializeWith(_serializer(), value));
  T deserializeImpl(String serialized) =>
      serializers.deserializeWith(_serializer(), json.decode(serialized));
}

abstract class DBColumnString extends DBColumn<String> {
  String serializeImpl(String value) => value;
  String deserializeImpl(String serialized) => serialized;
}
