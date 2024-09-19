import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/lexicon.dart';

// Similar to EnumOptionSelectorState, but allows multiple choice
class DictionarySelector extends StatefulWidget {
  final List<String> allValues;
  final List<String> initialValues;
  final ValueChanged<List<String>> onChanged;

  const DictionarySelector({
    super.key,
    required this.allValues,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  createState() => DictionarySelectorState();
}

class DictionarySelectorState extends State<DictionarySelector> {
  late Set<String> currentValues;

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
        title: Text(tr('dictionaries')),
      ),
      body: ListView(
        children: widget.allValues.map((d) {
          final metadata = Lexicon.dictionaryMetadata(d);
          return CheckboxListTile(
            title: Text(metadata.uiName),
            subtitle: Text('Words: ${metadata.numWords}'),
            controlAffinity: ListTileControlAffinity.leading,
            value: currentValues.contains(d),
            onChanged: (enabled) => _valueChanged(d, enabled!),
          );
        }).toList(),
      ),
    );
  }
}
