import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_phase.dart';

class AsyncSnapshotError extends StatelessWidget {
  final String errorMessage;
  final GamePhase gamePhase;

  AsyncSnapshotError(
    AsyncSnapshot<dynamic> snapshot, {
    @required this.gamePhase,
  }) : errorMessage = snapshot.error.toString() {
    // TODO: Log to firebase.
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error getting data at $gamePhase:\n' + errorMessage,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
    );
  }
}
