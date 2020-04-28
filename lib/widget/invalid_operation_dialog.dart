import 'package:flutter/material.dart';
import 'package:hatgame/util/invalid_operation.dart';

Future<void> showInvalidOperationDialog(
    {@required BuildContext context, @required InvalidOperation error}) async {
  // TODO: Close on enter (try using RawKeyEvent).
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
            (error.isInternalError ? 'Internal error! ' : '') + error.message),
        content: error.comment != null ? Text(error.comment) : null,
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
