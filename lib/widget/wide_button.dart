import 'package:flutter/material.dart';

class WideButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onPressed;
  final VoidCallback onPressedDisabled; // executed if onPressed is null

  WideButton(
      {this.child,
      this.color,
      @required this.onPressed,
      this.onPressedDisabled});

  @override
  Widget build(BuildContext context) {
    // Get screen size using MediaQuery
    // TODO: Consider using LayoutBuilder with viewportConstraints.maxWidth
    // instead of MediaQuery.
    final double width = MediaQuery.of(context).size.width * 0.8;
    return SizedBox(
      width: width,
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
    );
  }
}
