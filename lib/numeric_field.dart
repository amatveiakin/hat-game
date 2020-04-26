import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/theme.dart';

class NumericField extends StatefulWidget {
  final TextEditingController controller;
  final List<int> goldenValues;
  final String suffixText;

  NumericField({
    @required this.controller,
    @required this.goldenValues,
    this.suffixText,
  }) {
    Assert.holds(goldenValues.isNotEmpty);
  }

  @override
  State<StatefulWidget> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<NumericField> {
  final _focusNode = FocusNode();

  void _incValue() {
    final int currentValue = int.tryParse(widget.controller.text);
    final int newValue = (currentValue != null)
        ? widget.goldenValues
            .firstWhere((v) => v > currentValue, orElse: () => currentValue)
        : widget.goldenValues.first;
    widget.controller.text = newValue.toString();
    FocusScope.of(context).unfocus();
  }

  void _decValue() {
    final int currentValue = int.tryParse(widget.controller.text);
    final int newValue = (currentValue != null)
        ? widget.goldenValues
            .lastWhere((v) => v < currentValue, orElse: () => currentValue)
        : widget.goldenValues.last;
    widget.controller.text = newValue.toString();
    FocusScope.of(context).unfocus();
  }

  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.controller.selection = TextSelection(
            baseOffset: 0, extentOffset: widget.controller.text.length);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 48;
    const double textFieldWidth = 68;
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
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  filled: true,
                  border: InputBorder.none,
                  suffixText: widget.suffixText,
                ),
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
