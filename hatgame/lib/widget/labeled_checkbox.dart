import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget title;
  final EdgeInsets padding;
  final ShapeBorder? customInkWellBorder;

  const LabeledCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.padding = EdgeInsets.zero,
    this.customInkWellBorder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      customBorder: customInkWellBorder,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Checkbox(
              value: value,
              // `newValue` is guaranteed to be non-null because the
              // checkbox is not tristate.
              onChanged: (bool? newValue) => onChanged(newValue!),
            ),
            Expanded(child: title),
          ],
        ),
      ),
    );
  }
}
