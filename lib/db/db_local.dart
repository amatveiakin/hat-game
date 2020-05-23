import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:quiver/async.dart' as quiver_async;

class LocalDocumentReference extends DBDocumentReference {
  final LocalDB localDB;
  final String path;

  LocalDocumentReference({@required this.localDB, @required this.path});

  Future<void> setColumns(List<DBColumnData> columns) {
    localDB.setRow(path, dbData(columns));
    return Future<void>.value();
  }

  // Ignore LocalCacheBehavior, since this is already a local DB.
  Future<void> updateColumnsImpl(
      List<DBColumnData> columns, LocalCacheBehavior _) {
    localDB.setRow(
        path, Map.from(localDB.getRow(path))..addAll(dbData(columns)));
    return Future<void>.value();
  }

  LocalDocumentSnapshot instaGet() {
    return LocalDocumentSnapshot(this, localDB.getRow(path));
  }

  Future<LocalDocumentSnapshot> get() {
    return Future.value(instaGet());
  }

  Future<void> delete() {
    localDB.removeRow(path);
    return Future<void>.value();
  }

  Future<void> clearLocalCache() {
    // Ignore LocalCacheBehavior, since this is already a local DB.
    return Future<void>.value();
  }

  Future<void> assertLocalCacheIsEmpty() {
    // Ignore LocalCacheBehavior, since this is already a local DB.
    return Future<void>.value();
  }

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

// Firestore has offline mode, so it was tempting to use it instead, but
// that seems like a bad design choice:
//   - Firestore is designed for short periods of offline. It keeps the local
//     mutations in a queue until they've been committed:
//     https://stackoverflow.com/a/48871973/3092679
//   - Flutter Firestore plugin doesn't support disableNetwork:
//     https://github.com/FirebaseExtended/flutterfire/issues/211
//   - Flutter Firestore plugin is in bad shape in general (at the time of
//     writing, May 2020). Non-trivial features could be broken (e.g. there
//     are problems with basic transactions). It seems easier to re-implement
//     something simple than to debug Firestore/Flutter weirdness.
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

  LocalDocumentReference add() => document(newRowPath());

  Stream<LocalDocumentRawUpdate> snapshots() => _streamController.stream;
}
