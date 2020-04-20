import 'package:flutter/material.dart';
import 'package:hatgame/multi_line_list_tile.dart';

class OptionDescription<E> {
  final E value;
  final String title;
  final String subtitle;

  OptionDescription({
    @required this.value,
    @required this.title,
    @required this.subtitle,
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
                subtitle: Text(e.subtitle),
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
