import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';

class NumericField extends StatelessWidget {
  final bool readOnly;
  final TextEditingController controller;
  final List<int> goldenValues;
  final String suffixText;

  NumericField({
    @required this.readOnly,
    @required this.controller,
    @required this.goldenValues,
    this.suffixText,
  }) {
    Assert.holds(goldenValues.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.black26),
            borderRadius: BorderRadius.circular(3.0),
          ),
        ),
        child: IntrinsicHeight(
          child: SizedBox(
            width: _NumericFieldImplState.textFieldWidth,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                // Don't use `border` here, as it makes the text box higher.
                filled: true,
                suffixText: suffixText,
              ),
              textAlign: TextAlign.center,
              enabled: false,
            ),
          ),
        ),
      );
    } else {
      return NumericFieldImpl(
          controller: controller,
          goldenValues: goldenValues,
          suffixText: suffixText);
    }
  }
}

class NumericFieldImpl extends StatefulWidget {
  final TextEditingController controller;
  final List<int> goldenValues;
  final String suffixText;

  NumericFieldImpl({
    @required this.controller,
    @required this.goldenValues,
    this.suffixText,
  }) {
    Assert.holds(goldenValues.isNotEmpty);
  }

  @override
  State<StatefulWidget> createState() => _NumericFieldImplState();
}

class _NumericFieldImplState extends State<NumericFieldImpl> {
  static const double buttonWidth = 48;
  static const double textFieldWidth = 68;

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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
