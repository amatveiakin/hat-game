import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:hatgame/util/local_str.dart';
import 'package:hatgame/widget/divider.dart';

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
    return ListTile(
        title: title,
        subtitle: subtitle,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap);
  }
}

// =============================================================================
// Selector page

sealed class OptionItem<E> {}

class OptionChoice<E> extends OptionItem<E> {
  final E value;
  final LocalStr title;
  final LocalStr? subtitle;
  final bool enabled;
  final void Function(BuildContext)? onInfo;

  OptionChoice({
    required this.value,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.onInfo,
  });
}

class OptionDivider<E> extends OptionItem<E> {}

OptionChoice<E>? optionWithValue<E>(List<OptionItem<E>> options, E value) {
  return options.firstWhereOrNull(
      (o) => o is OptionChoice<E> && o.value == value) as OptionChoice<E>?;
}

abstract class EnumOptionSelector<E> extends StatefulWidget {
  final LocalStr windowTitle;
  final List<OptionItem<E>> allValues;
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
        title: Text(widget.windowTitle.value(context)),
      ),
      // TODO: Add icons. Consider if the items should look like buttons or
      // still look like list items. In the latter case we could change icon
      // color and/or background color and/or border and/or add a vertical side
      // line for the active option. Note: background color could conflict with
      // keyboard navigation.
      body: ListView(
        children: widget.allValues
            .map((e) => switch (e) {
                  OptionDivider() => const ThinDivider(
                      height: 8.0,
                    ),
                  OptionChoice() => Row(
                      children: <Widget>[
                            Expanded(
                              child: RadioListTile<E?>(
                                title: Text(e.title.value(context)),
                                subtitle: e.subtitle == null
                                    ? null
                                    : Text(e.subtitle!.value(context)),
                                value: e.value,
                                isThreeLine: e.subtitle != null,
                                groupValue: currentValue,
                                // Enable `toggleable` so that we can close the dialog
                                // when the user clicks the current option.
                                toggleable: true,
                                onChanged: e.enabled
                                    ? (v) => _valueChanged(context, v)
                                    : null,
                              ),
                            )
                          ] +
                          (e.onInfo != null
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: e.onInfo == null
                                        ? null
                                        : () => e.onInfo!(context),
                                  )
                                ]
                              : []),
                    ),
                })
            .toList(),
      ),
    );
  }
}
