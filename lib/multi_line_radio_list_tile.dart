import 'package:flutter/material.dart';

// Flutter is not very good at rendering tall lists items.
// Out of the box it supports only items with one to three lines,
// and the number of line has to be specified explicitly.
// On the other hand, this solution supports and number of lines
// and is fully automatic. I honestly don't understand why
// Flutter doesn't do this by default.
class MultiLineRadioListTile<T> extends StatelessWidget {
  static const double padding = 8;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Color activeColor;
  final Widget title;
  final Widget subtitle;
  final Widget secondary;
  final bool isThreeLine;
  final bool dense;
  final bool selected;
  final ListTileControlAffinity controlAffinity;

  const MultiLineRadioListTile({
    Key key,
    @required this.value,
    @required this.groupValue,
    @required this.onChanged,
    this.activeColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      key: key,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor,
      title: Padding(
        padding: EdgeInsets.only(top: padding),
        child: title,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(bottom: padding),
        child: subtitle,
      ),
      isThreeLine: isThreeLine,
      dense: dense,
      secondary: secondary,
      selected: selected,
      controlAffinity: controlAffinity,
    );
  }
}
