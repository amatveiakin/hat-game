import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';

const borderWidth = 1.0;

class NumericField extends StatelessWidget {
  final bool readOnly;
  final TextEditingController controller;
  final List<int>? goldenValues;
  final int? minValue;
  final int? maxValue;
  final String? suffixText;

  NumericField({
    super.key,
    required this.readOnly,
    required this.controller,
    this.goldenValues,
    this.minValue,
    this.maxValue,
    this.suffixText,
  }) {
    if (goldenValues != null) {
      Assert.holds(goldenValues!.isNotEmpty);
      Assert.holds(goldenValues!.isSorted((a, b) => a.compareTo(b)));
      Assert.holds(minValue == null && maxValue == null);
    } else {
      Assert.holds(minValue != null);
      if (maxValue != null) {
        Assert.le(minValue!, maxValue!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (readOnly) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black26, width: borderWidth),
            borderRadius: buttonBorderRadius,
          ),
        ),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 0, vertical: borderWidth),
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
        ),
      );
    } else {
      return NumericFieldImpl(
          controller: controller,
          goldenValues: goldenValues,
          minValue: minValue,
          maxValue: maxValue,
          suffixText: suffixText);
    }
  }
}

class NumericFieldImpl extends StatefulWidget {
  final TextEditingController controller;
  final List<int>? goldenValues;
  final int? minValue;
  final int? maxValue;
  final String? suffixText;

  const NumericFieldImpl({
    super.key,
    required this.controller,
    required this.goldenValues,
    required this.minValue,
    required this.maxValue,
    this.suffixText,
  });

  @override
  State<StatefulWidget> createState() => _NumericFieldImplState();
}

class _NumericFieldImplState extends State<NumericFieldImpl> {
  static const double buttonWidth = 48;
  static const double textFieldWidth = 68;

  final _focusNode = FocusNode();

  int _fixBounds(int value) {
    final clampMax =
        widget.maxValue != null ? min(value, widget.maxValue!) : value;
    return max(clampMax, widget.minValue!);
  }

  void _incValue() {
    final int? currentValue = int.tryParse(widget.controller.text);
    final int newValue;
    if (widget.goldenValues != null) {
      newValue = (currentValue != null)
          ? widget.goldenValues!
              .firstWhere((v) => v > currentValue, orElse: () => currentValue)
          : widget.goldenValues!.first;
    } else {
      newValue = (currentValue != null)
          ? _fixBounds(currentValue + 1)
          : widget.minValue!;
    }
    widget.controller.text = newValue.toString();
    FocusScope.of(context).unfocus();
  }

  void _decValue() {
    final int? currentValue = int.tryParse(widget.controller.text);
    final int newValue;
    if (widget.goldenValues != null) {
      newValue = (currentValue != null)
          ? widget.goldenValues!
              .lastWhere((v) => v < currentValue, orElse: () => currentValue)
          : widget.goldenValues!.last;
    } else {
      newValue = (currentValue != null)
          ? _fixBounds(currentValue - 1)
          : (widget.maxValue ?? widget.minValue!);
    }
    widget.controller.text = newValue.toString();
    FocusScope.of(context).unfocus();
  }

  @override
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
    final colorScheme = Theme.of(context).colorScheme;
    final buttonStyle = ButtonStyle(
        backgroundColor: WidgetStateProperty.all(colorScheme.secondary),
        foregroundColor: WidgetStateProperty.all(colorScheme.onSecondary));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black26, width: borderWidth),
          borderRadius: buttonBorderRadius,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: buttonWidth,
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: _decValue,
                child: const Text(
                  '−', // minus sign (U+2212)
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 0, vertical: borderWidth),
              child: SizedBox(
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
            ),
            SizedBox(
              width: buttonWidth,
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: _incValue,
                child: const Text(
                  '+',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
