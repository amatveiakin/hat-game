import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/widget/labeled_checkbox.dart';

class CheckboxButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget title;

  const CheckboxButton({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final borderShape = RoundedRectangleBorder(
      side: BorderSide(color: value ? MyTheme.secondary : Colors.black12),
      borderRadius: buttonBorderRadius,
    );
    return DecoratedBox(
      decoration: ShapeDecoration(shape: borderShape),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelLarge!,
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
