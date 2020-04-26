import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/util/assertion.dart';

class FirestoreUtil {
  // TODO: Make sure all users await on this, or we can get race conditions
  // with ourselves !!!
  static void atomicUpdateColumn<T>(
      DocumentReference reference, String field, T oldValue, T newValue) async {
    final String oldValueSerialized =
        json.encode(serializers.serialize(oldValue));
    final String newValueSerialized =
        json.encode(serializers.serialize(newValue));
    Assert.holds(reference != null);
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot snapshot = await tx.get(reference);
      final dbValue = snapshot.data[field];
      Assert.holds(dbValue == oldValueSerialized,
          lazyMessage: () =>
              "Race condition in field '$field' detected!" +
              ('\nValue in DB:\n' + dbValue) +
              ('\nOld value in the App:\n' + oldValueSerialized) +
              ('\nNew value in the App:\n' + newValueSerialized),
          inRelease: AssertInRelease.log);
      await tx.update(reference, <String, dynamic>{field: newValueSerialized});
    });
  }
}
