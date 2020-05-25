import 'package:flutter/material.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/dialog.dart';

Future<void> showInvalidOperationDialog(
    {@required BuildContext context, @required InvalidOperation error}) async {
  await simpleDialog(
    context: context,
    titleText:
        (error.isInternalError ? 'Internal error! ' : '') + error.message,
    contentText: error.comment,
    closeButtonText: 'OK',
  );
}
