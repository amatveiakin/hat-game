import 'package:flutter/material.dart';
import 'package:hatgame/util/invalid_operation.dart';

Future<void> showInvalidOperationDialog(
    {@required BuildContext context, @required InvalidOperation error}) async {
  await showDialog(
    context: context,
    // TODO: Add context or replace with a SnackBar.
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
