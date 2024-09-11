import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:hatgame/widget/divider.dart';
import 'package:hatgame/widget/multi_line_list_tile.dart';

// =============================================================================
// Auxiliary item suggest to use for opening selector page

class OptionSelectorHeader extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final GestureTapCallback? onTap;

  const OptionSelectorHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MultiLineListTile(
        title: title,
        subtitle: subtitle,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap);
  }
}

// =============================================================================
// Selector page

class OptionDescription<E> {
  final bool isDivider;
  final E? value;
  final String? title;
  final String? subtitle;

  OptionDescription({
    required this.value,
    required this.title,
    this.subtitle,
  }) : isDivider = false;

  OptionDescription.divider()
      : isDivider = true,
        value = null,
        title = null,
        subtitle = null;
}

OptionDescription<E>? optionWithValue<E>(
    List<OptionDescription<E>> options, E value) {
  return options.firstWhereOrNull((o) => !o.isDivider && o.value == value);
}

abstract class EnumOptionSelector<E> extends StatefulWidget {
  final String windowTitle;
  final List<OptionDescription<E>> allValues;
  final E initialValue;
  final Function changeCallback;

  const EnumOptionSelector({
    super.key,
    required this.windowTitle,
    required this.allValues,
    required this.initialValue,
    required this.changeCallback,
  });
}

class EnumOptionSelectorState<E, W extends EnumOptionSelector>
    extends State<W> {
  late E currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }

  void _valueChanged(BuildContext context, E? newValue) {
    if (newValue != null) {
      setState(() {
        currentValue = newValue;
      });
      widget.changeCallback(newValue);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.windowTitle),
      ),
      // TODO: Add icons. Consider if the items should look like buttons or
      // still look like list items. In the latter case we could change icon
      // color and/or background color and/or border and/or add a vertical side
      // line for the active option. Note: background color could conflict with
      // keyboard navigation.
      body: ListView(
        children: widget.allValues
            .map(
              (e) => e.isDivider
                  ? const ThinDivider(
                      height: 8.0,
                    )
                  : MultiLineRadioListTile<E?>(
                      title: Text(e.title!),
                      subtitle: e.subtitle == null ? null : Text(e.subtitle!),
                      value: e.value,
                      groupValue: currentValue,
                      // Enable `toggleable` so that we can close the dialog
                      // when the user clicks the current option.
                      toggleable: true,
                      onChanged: (v) => _valueChanged(context, v),
                    ),
            )
            .toList(),
      ),
    );
  }
}
