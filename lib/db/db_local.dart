import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:quiver/async.dart' as quiver_async;

class LocalDocumentReference extends DBDocumentReference {
  final String _path;

  LocalDocumentReference({@required String path}) : _path = path;

  String get path => _path;

  Future<void> setColumns(List<DBColumn> columns) {
    _localDB.setRow(path, dbData(columns));
    return Future<void>.value();
  }

  Future<void> updateColumnsImpl(List<DBColumn> columns) {
    _localDB.setRow(
        path, Map.from(_localDB.getRow(path))..addAll(dbData(columns)));
    return Future<void>.value();
  }

  Future<LocalDocumentSnapshot> get() {
    return Future.value(LocalDocumentSnapshot(this, _localDB.getRow(path)));
  }

  Future<void> delete() {
    _localDB.removeRow(path);
    return Future<void>.value();
  }

  Stream<LocalDocumentSnapshot> snapshots() {
    return quiver_async.concat([
      Stream.fromFuture(get()),
      _localDB
          .snapshots()
          .where((update) => update.path == path)
          .map((update) => LocalDocumentSnapshot(this, update.data))
    ]);
  }

  LocalDB get _localDB => LocalDB.instance;
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
  final _streamController =
      StreamController<LocalDocumentRawUpdate>.broadcast();

  static LocalDB get instance => _instance;

  Stream<LocalDocumentRawUpdate> snapshots() => _streamController.stream;

  Map<String, dynamic> getRow(String path) {
    return _rows[path];
  }

  void setRow(String path, Map<String, dynamic> value) {
    _rows[path] = Map.unmodifiable(value);
    _streamController.add(LocalDocumentRawUpdate(path, value));
  }

  void removeRow(String path) {
    _rows.remove(path);
    _streamController.add(LocalDocumentRawUpdate(path, null));
  }
}
