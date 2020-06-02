import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/widget/labeled_checkbox.dart';
import 'package:hatgame/widget/wide_button.dart';

class CheckboxButton extends StatelessWidget {
  final bool value;
  final Function onChanged;
  final Widget title;

  CheckboxButton({
    @required this.value,
    @required this.onChanged,
    @required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final borderShape = RoundedRectangleBorder(
      side: BorderSide(color: value ? MyTheme.accent : Colors.black12),
      borderRadius: BorderRadius.circular(3.0),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(shape: borderShape),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.button,
        child: LabeledCheckbox(
          value: value,
          onChanged: onChanged,
          title: title,
          customInkWellBorder: borderShape,
        ),
      ),
    );
  }
}
