import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/db/db_local.dart';

String newFirestoreGameID(int length, String prefix) {
  return prefix +
      Random().nextInt(pow(10, length) as int).toString().padLeft(length, '0');
}

firestore.DocumentReference firestoreGameReference(
    {required firestore.FirebaseFirestore firestoreInstance,
    required String gameID}) {
  return firestoreInstance.collection('games').doc(gameID);
}

String newLocalGameID() {
  return LocalDB.instance.newRowPath();
}

LocalDocumentReference localGameReference({required String gameID}) {
  return LocalDB.instance.document(gameID);
}
