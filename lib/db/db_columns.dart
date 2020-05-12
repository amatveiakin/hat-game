import 'dart:convert';

import 'package:built_value/serializer.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/list_ext.dart';

// =============================================================================
// Column interface

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

// TODO: data -> value
class DBColumnData<T> {
  final DBColumn<T> column;
  final T data;

  DBColumnData(this.column, this.data);
}

abstract class DBColumnFamily<T> extends DBColumn<T> {
  final int id;
  DBColumnFamily(this.id);
}

abstract class DBColumnFamilyManager<T, ColumnT extends DBColumnFamily<T>> {
  ColumnT fromColumnName(String columnName);
  // TODO: Either remove or add ID to all such columns.
  int idFromData(T data);
}

class DBIndexedColumnData<T> {
  final int id;
  final T value;

  DBIndexedColumnData(this.id, this.value);
}

extension DBColumnDataIterableUtil<T> on Iterable<DBIndexedColumnData<T>> {
  Iterable<int> ids() => map((e) => e.id);
  Iterable<T> values() => map((e) => e.value);
}

// =============================================================================
// Getters and setters

bool dbContains<T>(Map<String, dynamic> data, DBColumn<T> column) {
  return data.containsKey(column.name);
}

T dbGet<T>(Map<String, dynamic> data, DBColumn<T> column,
    {@required String documentPath}) {
  Assert.holds(dbContains(data, column),
      lazyMessage: () => documentPath != null
          ? 'Column "${column.name}" not found in "$documentPath". '
              'Content: "$data"'
          : 'Column "${column.name}" not found. Content: "$data"');
  return column.deserialize(data[column.name]);
}

T dbTryGet<T>(Map<String, dynamic> data, DBColumn<T> column) {
  return dbContains(data, column)
      ? dbGet(data, column, documentPath: null)
      : null;
}

List<DBIndexedColumnData<T>> dbGetAll<T, ColumnT extends DBColumnFamily<T>>(
    Map<String, dynamic> data, DBColumnFamilyManager<T, ColumnT> columnManager,
    {@required String documentPath}) {
  final columns = List<DBIndexedColumnData<T>>();
  data.forEach((key, valueSerialized) {
    final ColumnT c = columnManager.fromColumnName(key);
    if (c != null) {
      final value = c.deserialize(valueSerialized);
      columns.add(DBIndexedColumnData(c.id, value));
      final int idFromValue = columnManager.idFromData(value);
      if (idFromValue != null) {
        Assert.eq(idFromValue, c.id,
            lazyMessage: () =>
                'ID mismatch between for column "${c.name}" in "$documentPath" '
                'Content: "$valueSerialized"');
      }
    }
  });
  columns.sort((a, b) => a.id.compareTo(b.id));
  _dbCheckContinuity(columns.ids().toList());
  return columns;
}

int dbNextIndex<T>(Iterable<DBIndexedColumnData<T>> columns) {
  _dbCheckContinuity(columns.ids().toList());
  return columns.length;
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

class DBColCreationTimeUtc extends DBColumn<String> with _SerializeString {
  String get name => 'creation_time_utc';
}

class DBColHostAppVersion extends DBColumn<String> with _SerializeString {
  String get name => 'host_app_version';
}

class DBColConfig extends DBColumn<GameConfig> with _SerializeBuiltValue {
  String get name => 'config';
}

class DBColInitialState extends DBColumn<InitialGameState>
    with _SerializeBuiltValue {
  String get name => 'initial_state';
}

class DBColTurnRecord extends DBColumnFamily<TurnRecord>
    with _SerializeBuiltValue {
  static const String prefix = 'turn-';
  DBColTurnRecord(int id) : super(id);
  String get name => '$prefix$id';
}

class DBColTurnRecordManager
    extends DBColumnFamilyManager<TurnRecord, DBColTurnRecord> {
  @override
  DBColTurnRecord fromColumnName(String columnName) {
    final int id = _getColumnID(columnName, prefix: DBColTurnRecord.prefix);
    return id == null ? null : DBColTurnRecord(id);
  }

  @override
  int idFromData(TurnRecord data) => null;
}

class DBColCurrentTurn extends DBColumn<TurnState> with _SerializeBuiltValue {
  String get name => 'turn_current';
}

// Per-player state in online mode.
class DBColPlayer extends DBColumnFamily<PersonalState>
    with _SerializeBuiltValue {
  static const String prefix = 'player-';
  DBColPlayer(int id) : super(id);
  String get name => '$prefix$id';
}

class DBColPlayerManager
    extends DBColumnFamilyManager<PersonalState, DBColPlayer> {
  @override
  DBColPlayer fromColumnName(String columnName) {
    final int id = _getColumnID(columnName, prefix: DBColPlayer.prefix);
    return id == null ? null : DBColPlayer(id);
  }

  @override
  int idFromData(PersonalState data) => data.id;
}

// Analog of DBColPlayer for offline mode. In offline mode there is no
// per-player state, so this column is separate from DBColState for the purely
// technical reason of trying to keep offline and online implementations close.
class DBColLocalPlayer extends DBColumn<PersonalState>
    with _SerializeBuiltValue {
  DBColLocalPlayer();
  String get name => 'additional_state';
}

// =============================================================================
// Implementation

mixin _SerializeBuiltValue<T> on DBColumn<T> {
  Serializer _serializer() => serializers.serializerForType(T);
  String serializeImpl(T value) =>
      json.encode(serializers.serializeWith(_serializer(), value));
  T deserializeImpl(String serialized) =>
      serializers.deserializeWith(_serializer(), json.decode(serialized));
}

mixin _SerializeString on DBColumn<String> {
  String serializeImpl(String value) => value;
  String deserializeImpl(String serialized) => serialized;
}

int _getColumnID(String columnName, {@required String prefix}) {
  final columnRegexp = RegExp('^$prefix([0-9]+)\$');
  final match = columnRegexp.firstMatch(columnName);
  return match == null ? null : int.tryParse(match.group(1));
}

void _dbCheckContinuity(List<int> ids) {
  ids.sorted().forEachWithIndex((index, value) => Assert.holds(value == index));
}
