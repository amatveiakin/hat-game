import 'package:flutter/material.dart';

class WideButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onPressed;

  WideButton({this.child, this.color, @required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Get screen size using MediaQuery
    // TODO: Consider using LayoutBuilder with viewportConstraints.maxWidth
    // instead of MediaQuery.
    final double width = MediaQuery.of(context).size.width * 0.8;
    return SizedBox(
      width: width,
      child: RaisedButton(
        onPressed: onPressed,
        color: color,
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: child,
      ),
    );
  }
}
