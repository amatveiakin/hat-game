// ignore_for_file: avoid_renaming_method_parameters

import 'dart:async';

import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:quiver/async.dart' as quiver_async;

class LocalDocumentReference extends DBDocumentReference {
  final LocalDB localDB;
  @override
  final String path;

  LocalDocumentReference({required this.localDB, required this.path});

  void syncSetColumns(List<DBColumnUpdate> columns) =>
      localDB.setRow(path, _applyUpdates({}, columns));
  @override
  Future<void> setColumns(List<DBColumnUpdate> columns) async =>
      syncSetColumns(columns);

  // Ignore LocalCacheBehavior, since this is already a local DB.
  void syncUpdateColumnsImpl(
          List<DBColumnUpdate> columns, LocalCacheBehavior _) =>
      localDB.setRow(path, _applyUpdates(localDB.getRow(path)!, columns));
  @override
  Future<void> updateColumnsImpl(
          List<DBColumnUpdate> columns, LocalCacheBehavior _) async =>
      syncUpdateColumnsImpl(columns, _);

  LocalDocumentSnapshot syncGet() =>
      LocalDocumentSnapshot(this, localDB.getRow(path));
  @override
  Future<LocalDocumentSnapshot> get() async => syncGet();

  void syncDelete() => localDB.removeRow(path);
  @override
  Future<void> delete() async => syncDelete();

  // Ignore LocalCacheBehavior, since this is already a local DB.
  @override
  void clearLocalCache() {}
  @override
  void assertLocalCacheIsEmpty() {}

  @override
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
  final Map<String, String?>? _data;

  LocalDocumentSnapshot(this._ref, this._data);

  @override
  LocalDocumentReference get reference => _ref;

  @override
  Map<String, String?>? get rawData => _data;
}

class LocalDocumentRawUpdate {
  String path;
  Map<String, String?>? data;

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
  final _rows = <String, Map<String, String?>?>{};
  int _newRowId = 0;
  final _streamController =
      StreamController<LocalDocumentRawUpdate>.broadcast();

  static LocalDB get instance => _instance;

  Map<String, String?>? getRow(String path) {
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

  void setRow(String path, Map<String, String?> value) {
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

Map<String, String?> _applyUpdates(
    Map<String, String?> row, List<DBColumnUpdate> updates) {
  final updatedRow = Map.of(row);
  for (final update in updates) {
    switch (update) {
      case DBColumnSetValue(:final value):
        updatedRow[update.column.name] = update.column.serialize(value);
        break;
      case DBColumnDelete():
        updatedRow.remove(update.column.name);
        break;
    }
  }
  return updatedRow;
}
