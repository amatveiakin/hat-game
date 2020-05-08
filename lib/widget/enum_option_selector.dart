import 'package:flutter/material.dart';
import 'package:hatgame/widget/multi_line_list_tile.dart';

// =============================================================================
// Auxiliary item suggest to use for opening selector page

class OptionSelectorHeader extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final GestureTapCallback onTap;

  OptionSelectorHeader({
    @required this.title,
    this.subtitle,
    @required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MultiLineListTile(
        title: title,
        subtitle: subtitle,
        trailing: onTap == null ? null : Icon(Icons.chevron_right),
        onTap: onTap);
  }
}

// =============================================================================
// Selector page

class OptionDescription<E> {
  final E value;
  final String title;
  final String subtitle;

  OptionDescription({
    @required this.value,
    @required this.title,
    this.subtitle,
  });
}

abstract class EnumOptionSelector<E> extends StatefulWidget {
  final String windowTitle;
  final List<OptionDescription<E>> allValues;
  final E initialValue;
  final Function changeCallback;

  EnumOptionSelector({
    @required this.windowTitle,
    @required this.allValues,
    @required this.initialValue,
    @required this.changeCallback,
  });
}

class EnumOptionSelectorState<E, W extends EnumOptionSelector>
    extends State<W> {
  E currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }

  void _valueChanged(E newValue) {
    setState(() {
      currentValue = newValue;
    });
    widget.changeCallback(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.windowTitle),
      ),
      body: ListView(
        children: widget.allValues
            .map(
              (e) => MultiLineRadioListTile<E>(
                title: Text(e.title),
                subtitle: e.subtitle == null ? null : Text(e.subtitle),
                value: e.value,
                groupValue: currentValue,
                onChanged: _valueChanged,
              ),
            )
            .toList(),
      ),
    );
  }
}
