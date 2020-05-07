import 'package:flutter/material.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:hatgame/util/assertion.dart';

abstract class DBDocumentReference {
  String get path;

  Future<void> setColumns(List<DBColumnData> columns);

  // Set new content for each column. Doesn't support nested updates
  // (in contrast to Firestore).
  Future<void> updateColumns(List<DBColumnData> columns) {
    checkNoNestedOverrides(columns);
    return updateColumnsImpl(columns);
  }

  Future<DBDocumentSnapshot> get();

  Future<void> delete();

  Stream<DBDocumentSnapshot> snapshots();

  @protected
  Future<void> updateColumnsImpl(List<DBColumnData> columns);

  @protected
  void checkNoNestedOverrides(List<DBColumnData> columns) {
    for (final col in columns) {
      if (col.data is firestore.DocumentReference ||
          col.data is List ||
          col.data is Map<dynamic, dynamic>) {
        // Forbid Firestore-like nested updates, because they are not supported
        // by LocalDB.
        Assert.fail('Nested updates are not allowed. '
            'Document: "$path". Update: "$columns"');
      }
    }
  }
}

abstract class DBDocumentSnapshot {
  DBDocumentReference get reference;

  bool get exists => rawData != null;

  bool contains(DBColumn col) => dbContains(rawData, col);

  T get<T>(DBColumn<T> col) =>
      dbGet(rawData, col, documentPath: reference.path);

  T tryGet<T>(DBColumn<T> col) => dbTryGet(rawData, col);

  @protected
  Map<String, dynamic> get rawData;
}
