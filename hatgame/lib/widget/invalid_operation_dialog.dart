import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/dialog.dart';

Future<void> showInvalidOperationDialog(
    {required BuildContext context, required InvalidOperation error}) async {
  await simpleDialog(
    context: context,
    titleText: (error.isInternalError ? context.tr('internal_error') : '') +
        error.message.value(context),
    contentText: error.comment?.value(context),
    closeButtonText: context.tr('ok'),
  );
}
