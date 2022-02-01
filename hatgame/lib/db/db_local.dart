import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:quiver/async.dart' as quiver_async;

class LocalDocumentReference extends DBDocumentReference {
  final LocalDB localDB;
  final String/*!*/ path;

  LocalDocumentReference({@required this.localDB, @required this.path});

  void syncGetColumns(List<DBColumnData> columns) =>
      localDB.setRow(path, dbData(columns));
  Future<void> setColumns(List<DBColumnData> columns) async =>
      syncGetColumns(columns);

  // Ignore LocalCacheBehavior, since this is already a local DB.
  void syncUpdateColumnsImpl(
          List<DBColumnData> columns, LocalCacheBehavior _) =>
      localDB.setRow(
          path, Map.from(localDB.getRow(path))..addAll(dbData(columns)));
  Future<void> updateColumnsImpl(
          List<DBColumnData> columns, LocalCacheBehavior _) async =>
      syncUpdateColumnsImpl(columns, _);

  LocalDocumentSnapshot syncGet() =>
      LocalDocumentSnapshot(this, localDB.getRow(path));
  Future<LocalDocumentSnapshot> get() async => syncGet();

  void syncDelete() => localDB.removeRow(path);
  Future<void> delete() async => syncDelete();

  // Ignore LocalCacheBehavior, since this is already a local DB.
  void clearLocalCache() {}
  void assertLocalCacheIsEmpty() {}

  Stream<LocalDocumentSnapshot> snapshots() {
    return quiver_async.concat([
      Stream.fromFuture(get()),
      localDB
          .snapshots()
          .where((update) => update.path == path)
          .map((update) => LocalDocumentSnapshot(this, update.data))
    ]);
  }
}

class LocalDocumentSnapshot extends DBDocumentSnapshot {
  final LocalDocumentReference _ref;
  final Map<String, dynamic> _data;

  LocalDocumentSnapshot(this._ref, this._data);

  LocalDocumentReference get reference => _ref;

  Map<String, dynamic> get rawData => _data;
}

class LocalDocumentRawUpdate {
  String path;
  Map<String, dynamic> data;

  LocalDocumentRawUpdate(this.path, this.data);
}

// FirebaseFirestore has offline mode, so it was tempting to use it instead, but
// that seems like a bad design choice:
//   - FirebaseFirestore is designed for short periods of offline. It keeps the
//     local mutations in a queue until they've been committed:
//     https://stackoverflow.com/a/48871973/3092679
//   - Flutter FirebaseFirestore plugin doesn't support disableNetwork:
//     https://github.com/FirebaseExtended/flutterfire/issues/211
//   - Flutter FirebaseFirestore plugin is in bad shape in general (at the time
//     of writing, May 2020). Non-trivial features could be broken (e.g. there
//     are problems with basic transactions). It seems easier to re-implement
//     something simple than to debug FirebaseFirestore/Flutter weirdness.
class LocalDB {
  static final LocalDB _instance = LocalDB();

  // TODO: Back up to some persistent local storage.
  final _rows = Map<String, Map<String, dynamic>>();
  int _newRowId = 0;
  final _streamController =
      StreamController<LocalDocumentRawUpdate>.broadcast();

  static LocalDB get instance => _instance;

  Map<String, dynamic> getRow(String path) {
    return _rows[path];
  }

  String newRowPath() {
    while (true) {
      final String path = _newRowId.toString();
      if (!_rows.containsKey(path)) {
        _rows[path] = null;
        return path;
      }
      _newRowId++;
    }
  }

  void setRow(String path, Map<String, dynamic> value) {
    _rows[path] = Map.unmodifiable(value);
    _streamController.add(LocalDocumentRawUpdate(path, value));
  }

  void removeRow(String path) {
    // Keep the row to name sure IDs are unique.
    _rows[path] = null;
    _streamController.add(LocalDocumentRawUpdate(path, null));
  }

  LocalDocumentReference document(String path) =>
      LocalDocumentReference(localDB: this, path: path);

  Stream<LocalDocumentRawUpdate> snapshots() => _streamController.stream;
}
