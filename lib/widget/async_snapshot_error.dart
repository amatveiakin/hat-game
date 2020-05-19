import 'package:flutter/material.dart';

class AsyncSnapshotError extends StatelessWidget {
  final String errorMessage;
  final String dataName;

  AsyncSnapshotError(
    AsyncSnapshot<dynamic> snapshot, {
    @required this.dataName,
  }) : errorMessage = snapshot.error.toString() {
    // TODO: Log to firebase.
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error getting $dataName:\n' + errorMessage,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
    );
  }
}
