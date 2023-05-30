import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  final bool value;
  final Function onChanged;
  final Widget title;
  final EdgeInsets padding;
  final ShapeBorder? customInkWellBorder;

  const LabeledCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.padding = EdgeInsets.zero,
    this.customInkWellBorder,
  }) : super(key: key);

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
              onChanged: (bool? newValue) => onChanged(newValue),
            ),
            Expanded(child: title),
          ],
        ),
      ),
    );
  }
}
