import 'package:flutter/material.dart';

@immutable
class DialogChoice<T> {
  final T value;
  final String text;

  const DialogChoice(this.value, this.text);
}

Text? _textWidget(String? text) {
  return text == null ? null : Text(text);
}

Future<T> multipleChoiceDialog<T>({
  required BuildContext context,
  String? titleText,
  String? contentText,
  required List<DialogChoice> choices,
  required T defaultChoice, // returned when the dialog is dismissed
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: _textWidget(titleText),
      content: _textWidget(contentText),
      actions: choices
          .map(
            (c) => TextButton(
              child: Text(c.text),
              onPressed: () => Navigator.of(context).pop(c.value),
            ),
          )
          .toList(),
    ),
  ).then((value) => value ?? defaultChoice);
}

Future<void> simpleDialog(
    {required BuildContext context,
    String? titleText,
    String? contentText,
    required String closeButtonText}) {
  // TODO: Close on enter (try using RawKeyEvent).
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: _textWidget(titleText),
      content: _textWidget(contentText),
      actions: [
        TextButton(
          child: Text(closeButtonText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
