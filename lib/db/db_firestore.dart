import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';

class FirestoreDocumentReference extends DBDocumentReference {
  firestore.DocumentReference _ref;

  FirestoreDocumentReference(this._ref);

  firestore.DocumentReference get firestoreReference => _ref;

  String get path => _ref.path;

  Future<void> setColumns(List<DBColumnData> columns) =>
      _ref.setData(dbData(columns));

  Future<void> updateColumnsImpl(List<DBColumnData> columns) =>
      _ref.updateData(dbData(columns));

  Future<FirestoreDocumentSnapshot> get() async =>
      FirestoreDocumentSnapshot(await _ref.get());

  Future<void> delete() => _ref.delete();

  Stream<DBDocumentSnapshot> snapshots() =>
      _ref.snapshots().map((s) => FirestoreDocumentSnapshot(s));
}

class FirestoreDocumentSnapshot extends DBDocumentSnapshot {
  firestore.DocumentSnapshot _snapshot;

  FirestoreDocumentSnapshot(this._snapshot);

  FirestoreDocumentReference get reference =>
      FirestoreDocumentReference(_snapshot.reference);

  Map<String, dynamic> get rawData => _snapshot.data;
}
