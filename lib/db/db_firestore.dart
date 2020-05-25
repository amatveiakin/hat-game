import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/db/db_local.dart';
import 'package:hatgame/util/assertion.dart';

class FirestoreDocumentReference extends DBDocumentReference {
  firestore.DocumentReference _ref;

  FirestoreDocumentReference(this._ref);

  firestore.DocumentReference get firestoreReference => _ref;

  String get path => _ref.path;

  Future<void> setColumns(List<DBColumnData> columns) =>
      _ref.setData(dbData(columns));

  Future<void> updateColumnsImpl(
      List<DBColumnData> columns, LocalCacheBehavior localCache) async {
    if (localCache == LocalCacheBehavior.cache) {
      _FirestoreLocalCache.singleton.updateColumns(this, columns);
    }
    return _ref.updateData(dbData(columns));
  }

  Future<FirestoreDocumentSnapshot> get() async => FirestoreDocumentSnapshot(
      await _ref.get(), _FirestoreLocalCache.singleton.get(this));

  Future<void> delete() => _ref.delete();

  Future<void> clearLocalCache() async {
    return _FirestoreLocalCache.singleton.clearCache(this);
  }

  Future<void> assertLocalCacheIsEmpty() async {
    final localCache = _FirestoreLocalCache.singleton.get(this);
    if (localCache?.rawData != null) {
      Assert.failDebug(
          'Local cache should be empty, but found: ${localCache.rawData}',
          inRelease: AssertInRelease.log);
      await clearLocalCache();
    }
  }

  Stream<DBDocumentSnapshot> snapshots() => _ref.snapshots().map((s) =>
      FirestoreDocumentSnapshot(s, _FirestoreLocalCache.singleton.get(this)));
}

class FirestoreDocumentSnapshot extends DBDocumentSnapshot {
  final firestore.DocumentSnapshot _snapshot;
  final LocalDocumentSnapshot _localCacheOverrides;

  FirestoreDocumentSnapshot(this._snapshot, this._localCacheOverrides);

  FirestoreDocumentSnapshot.fromFirestore(this._snapshot)
      : _localCacheOverrides = null;

  FirestoreDocumentReference get reference =>
      FirestoreDocumentReference(_snapshot.reference);

  Map<String, dynamic> get rawData =>
      _snapshot.data == null || _localCacheOverrides?.rawData == null
          ? _snapshot.data
          : (Map.from(_snapshot.data)..addAll(_localCacheOverrides.rawData));
}

// =============================================================================
// Local cache
//
// We use a local cache on top of Firebase when we know that we have the
// most relevant data (which is usually the case, because each column is
// owned by only one player, see 'DB usage philosophy' in db_columns.dart).
// This is necessary to avoid glitches when multiple updates were sent to
// Firebase quickly. In such situations Firebase returns back the updates
// back with a small delay. This causes weird behavior that is most easily
// seen in config page: if you clicked on '+' / '-' icons next to 'turn time'
// field, you could see how the value is updated and then an older value pops
// up. I never understood why this happenes: Firebase is supposed to have
// local cache of it's own, but apparently it's not sufficient. This might
// be a bug in the web version of the plugin, as I wasn't able to reproduce
// this in Android emulator.
//
// OPTIMIZATION POTENTIAL: Double-check whether caching is still required
// when Flutter web is out of beta.

class _FirestoreLocalCache {
  final cachePerInstance = Map<firestore.Firestore, LocalDB>();

  static final singleton = _FirestoreLocalCache();

  Future<void> updateColumns(
      FirestoreDocumentReference reference, List<DBColumnData> columns) async {
    final firestore.Firestore instance = reference.firestoreReference.firestore;
    if (cachePerInstance[instance] == null) {
      cachePerInstance[instance] = LocalDB();
    }
    final document = cachePerInstance[instance].document(reference.path);
    await document.setColumns([]);
    return document.updateColumns(columns);
  }

  LocalDocumentSnapshot get(FirestoreDocumentReference reference) {
    final firestore.Firestore instance = reference.firestoreReference.firestore;
    if (cachePerInstance[instance] == null) {
      return null;
    }
    return cachePerInstance[instance].document(reference.path).instaGet();
  }

  Future<void> clearCache(FirestoreDocumentReference reference) async {
    final firestore.Firestore instance = reference.firestoreReference.firestore;
    if (cachePerInstance[instance] == null) {
      return;
    }
    return cachePerInstance[instance].document(reference.path).delete();
  }
}
