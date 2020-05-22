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
  // TODO: Consider: forbid null; add 'delete column' sentinel; delete
  // `dbContainsNonNull`.
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

bool dbContainsNonNull<T>(Map<String, dynamic> data, DBColumn<T> column) {
  return dbTryGet(data, column) != null;
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
//
// DB usage philosophy. At any point in time each column can we updated by at
// most one player, called 'owner'. This allows to mostly avoid transactions.
// Transactions are used only to generate unique IDs for games, players, etc.
// Some columns are 'immutable' meaning that they cannot be updated or deleted
// after they were initially writter.

// Written when game lobby is created. Immutable.
class DBColCreationTimeUtc extends DBColumn<String> with DBColSerializeString {
  String get name => 'creation_time_utc';
}

// Written when game lobby is created. Immutable.
class DBColHostAppVersion extends DBColumn<String> with DBColSerializeString {
  String get name => 'host_app_version';
}

// Owned by the host during configuration phase. Immutable afterwards.
class DBColConfig extends DBColumn<GameConfig> with DBColSerializeBuiltValue {
  String get name => 'config';
}

// Written when game starts. Immutable.
class DBColInitialState extends DBColumn<InitialGameState>
    with DBColSerializeBuiltValue {
  String get name => 'initial_state';
}

// Written after turn. Immutable. Uses sequential numeration.
class DBColTurnRecord extends DBColumnFamily<TurnRecord>
    with DBColSerializeBuiltValue {
  static const String prefix = 'turn-';
  DBColTurnRecord(int id) : super(id);
  String get name => '$prefix$id';
}

// Exists while the game is in progress, i.e. started but not finished.
// Owned by the active player (the performer). For a new player to become
// active, the previous active player must write an update handing over
// the active player status.
class DBColCurrentTurn extends DBColumn<TurnState>
    with DBColSerializeBuiltValue {
  String get name => 'turn_current';
}

// Per-player state in online mode. Owned by the corresponding player.
class DBColPlayer extends DBColumnFamily<PersonalState>
    with DBColSerializeBuiltValue {
  static const String prefix = 'player-';
  DBColPlayer(int id) : super(id);
  String get name => '$prefix$id';
}

// Analog of DBColPlayer for offline mode. In offline mode there is no
// per-player state, so this column is separate from DBColState for the purely
// technical reason of trying to keep offline and online implementations close.
class DBColLocalPlayer extends DBColumn<PersonalState>
    with DBColSerializeBuiltValue {
  DBColLocalPlayer();
  String get name => 'additional_state';
}

// =============================================================================
// Column managers
//
// These are helper classes used to work around the fact that Dart doesn't
// allow to instantiate a generic type.

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

// =============================================================================
// Implementation

mixin DBColSerializeBuiltValue<T> on DBColumn<T> {
  Serializer _serializer() => serializers.serializerForType(T);
  String serializeImpl(T value) =>
      json.encode(serializers.serializeWith(_serializer(), value));
  T deserializeImpl(String serialized) =>
      serializers.deserializeWith(_serializer(), json.decode(serialized));
}

mixin DBColSerializeString on DBColumn<String> {
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
