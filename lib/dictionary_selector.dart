import 'package:flutter/material.dart';
import 'package:hatgame/widget/multi_line_list_tile.dart';

// Similar to EnumOptionSelectorState, but allows multiple choice
class DictionarySelector extends StatefulWidget {
  final List<String> allValues;
  final List<String> initialValues;
  final ValueChanged<List<String>> onChanged;

  DictionarySelector({
    @required this.allValues,
    @required this.initialValues,
    @required this.onChanged,
  });

  @override
  createState() => DictionarySelectorState();
}

class DictionarySelectorState extends State<DictionarySelector> {
  Set<String> currentValues;

  @override
  void initState() {
    super.initState();
    currentValues = widget.initialValues.toSet();
  }

  void _valueChanged(String value, bool enabled) {
    setState(() {
      if (enabled) {
        currentValues.add(value);
      } else {
        currentValues.remove(value);
      }
    });
    // Don't simply use `currentValues.toList()` to get standardized sorting.
    widget.onChanged(
        widget.allValues.where((e) => currentValues.contains(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dictionaries'),
      ),
      body: ListView(
        children: widget.allValues
            .map(
              (e) => MultiLineCheckboxListTile(
                title: Text(e),
                controlAffinity: ListTileControlAffinity.leading,
                value: currentValues.contains(e),
                onChanged: (enabled) => _valueChanged(e, enabled),
              ),
            )
            .toList(),
      ),
    );
  }
}
