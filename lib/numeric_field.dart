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
    const double buttonWidth = 48;
    const double textFieldWidth = 68;
    // TODO: Select all on focus.
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black26),
          borderRadius: BorderRadius.circular(3.0),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: buttonWidth,
              child: RaisedButton(
                child: Text(
                  '−', // minus sign (U+2212)
                  textAlign: TextAlign.center,
                ),
                color: MyTheme.accent,
                onPressed: _decValue,
              ),
            ),
            SizedBox(
              width: textFieldWidth,
              child: TextField(
                controller: controller,
                decoration:
                    InputDecoration(filled: true, border: InputBorder.none),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              ),
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
        ),
      ),
    );
  }
}
