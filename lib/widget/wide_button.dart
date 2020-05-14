import 'package:flutter/material.dart';

class WideButton extends StatelessWidget {
  static const EdgeInsets bottomButtonMargin =
      EdgeInsets.symmetric(vertical: 20.0);

  final Widget child;
  final Color color;
  final VoidCallback onPressed;
  final VoidCallback onPressedDisabled; // executed if onPressed is null
  final EdgeInsets margin;

  WideButton(
      {this.child,
      this.color,
      @required this.onPressed,
      this.onPressedDisabled,
      this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: GestureDetector(
          child: RaisedButton(
            onPressed: onPressed,
            color: color,
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 20),
              child: child,
            ),
          ),
          onTap: onPressed == null ? onPressedDisabled : null,
        ),
      ),
    );
  }
}
