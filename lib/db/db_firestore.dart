import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';

// TODO: Re-introduce caching.
//
// Cache:
//   - config on the host player during configuration phase.
//   - current turn status on teh active player while the game is on.
//
// Details.
// This app used to have a local cache on top of Firebase when it knew
// that it had the most relevant data (which is usually the case, because
// each column is owned by only one player, see 'DB usage philosophy' in
// db_columns.dart). This was necessary to avoid glitches when multiple
// updates were sent to Firebase quickly. In such situations Firebase
// returned back the updates back with a small delay. This caused weird
// behavior that was most easily seen in config page: if you clicked on
// '+' / '-' icons next to 'turn time' field, you could see how the value
// is updated and then older value pops up. I never understood why this
// happenes: Firebase is supposed to have local cache of it's own, but
// apparently it's not sufficient.

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
