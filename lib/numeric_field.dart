import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/theme.dart';

class NumericField extends StatelessWidget {
  final TextEditingController controller;
  final List<int> goldenValues;

  NumericField({
    @required this.controller,
    @required this.goldenValues,
  }) {
    Assert.holds(goldenValues.isNotEmpty);
  }

  void _incValue() {
    final int currentValue = int.tryParse(controller.text);
    final int newValue = (currentValue != null)
        ? goldenValues.firstWhere((v) => v > currentValue)
        : goldenValues.first;
    controller.text = newValue.toString();
  }

  void _decValue() {
    final int currentValue = int.tryParse(controller.text);
    final int newValue = (currentValue != null)
        ? goldenValues.lastWhere((v) => v < currentValue)
        : goldenValues.last;
    controller.text = newValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 30;
    const double textFieldWidth = 40;
    const double padding = 6;
    // TODO: Center text on +/- buttons.
    // TODO: Select on focus.
    return Row(
      children: [
        SizedBox(
          width: buttonWidth,
          child: RaisedButton(
            child: Text(
              '−', // note: this is a minus sign (U+2212)
              textAlign: TextAlign.center,
            ),
            color: MyTheme.accent,
            onPressed: _decValue,
          ),
        ),
        SizedBox(
          width: padding,
        ),
        SizedBox(
          width: textFieldWidth,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
          ),
        ),
        SizedBox(
          width: padding,
        ),
        SizedBox(
          width: buttonWidth,
          child: RaisedButton(
            child: Text(
              '+',
              textAlign: TextAlign.center,
            ),
            color: MyTheme.accent,
            onPressed: _incValue,
          ),
        ),
      ],
    );
  }
}
