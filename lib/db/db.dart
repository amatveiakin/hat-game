import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/db/db_local.dart';

String newFirestoreGameID(int length, String prefix) {
  return prefix +
      Random().nextInt(pow(10, length)).toString().padLeft(length, '0');
}

firestore.DocumentReference firestoreGameReference({@required String gameID}) {
  return firestore.Firestore.instance.collection('games').document(gameID);
}

LocalDocumentReference localGameReference() {
  return LocalDocumentReference(path: 'local');
}