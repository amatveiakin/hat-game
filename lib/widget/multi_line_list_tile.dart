import 'package:flutter/material.dart';

// Flutter is not very good at rendering tall lists items.
// Out of the box it supports only items with one to three lines,
// and the number of line has to be specified explicitly.
//
// On the other hand, this solution supports any number of lines and
// is fully automatic. The losses compared to vanilla ListTile-s are
// negligible:
//   - It doesn't add a tiny margin between title and subtitle when
//     subtitle is more than one line long.
//   - Radio button positioning in MultiLineRadioListTile is different
//     from RadioListTile (although personally I think the new positioning
//     is better).

const double _padding = 8;

class MultiLineListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final bool dense;
  final EdgeInsetsGeometry contentPadding;
  final bool enabled;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;
  final bool selected;

  const MultiLineListTile({
    Key key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.dense,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return subtitle == null
        ? ListTile(
            key: key,
            leading: leading,
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: _padding),
              child: title,
            ),
            subtitle: null,
            trailing: trailing,
            isThreeLine: false,
            dense: dense,
            contentPadding: contentPadding,
            enabled: enabled,
            onTap: onTap,
            onLongPress: onLongPress,
            selected: selected,
          )
        : ListTile(
            key: key,
            leading: leading,
            title: Padding(
              padding: EdgeInsets.only(top: _padding),
              child: title,
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(bottom: _padding),
              child: subtitle,
            ),
            trailing: trailing,
            isThreeLine: false,
            dense: dense,
            contentPadding: contentPadding,
            enabled: enabled,
            onTap: onTap,
            onLongPress: onLongPress,
            selected: selected,
          );
  }
}

class MultiLineSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color activeTrackColor;
  final Color inactiveThumbColor;
  final Color inactiveTrackColor;
  final ImageProvider activeThumbImage;
  final ImageProvider inactiveThumbImage;
  final Widget title;
  final Widget subtitle;
  final Widget secondary;
  final bool dense;
  final EdgeInsetsGeometry contentPadding;
  final bool selected;

  const MultiLineSwitchListTile({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.title,
    this.subtitle,
    this.dense,
    this.contentPadding,
    this.secondary,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return subtitle == null
        ? SwitchListTile(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeTrackColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
            activeThumbImage: activeThumbImage,
            inactiveThumbImage: inactiveThumbImage,
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: _padding),
              child: title,
            ),
            subtitle: null,
            secondary: secondary,
            isThreeLine: false,
            dense: dense,
            contentPadding: contentPadding,
            selected: selected,
          )
        : SwitchListTile(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeTrackColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
            activeThumbImage: activeThumbImage,
            inactiveThumbImage: inactiveThumbImage,
            title: Padding(
              padding: EdgeInsets.only(top: _padding),
              child: title,
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(bottom: _padding),
              child: subtitle,
            ),
            secondary: secondary,
            isThreeLine: false,
            dense: dense,
            contentPadding: contentPadding,
            selected: selected,
          );
  }
}

class MultiLineRadioListTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Color activeColor;
  final Widget title;
  final Widget subtitle;
  final Widget secondary;
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
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
  });

  @override
  Widget build(BuildContext context) {
    return subtitle == null
        ? RadioListTile<T>(
            key: key,
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: activeColor,
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: _padding),
              child: title,
            ),
            subtitle: null,
            isThreeLine: false,
            dense: dense,
            secondary: secondary,
            selected: selected,
            controlAffinity: controlAffinity,
          )
        : RadioListTile<T>(
            key: key,
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: activeColor,
            title: Padding(
              padding: EdgeInsets.only(top: _padding),
              child: title,
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(bottom: _padding),
              child: subtitle,
            ),
            isThreeLine: false,
            dense: dense,
            secondary: secondary,
            selected: selected,
            controlAffinity: controlAffinity,
          );
  }
}
