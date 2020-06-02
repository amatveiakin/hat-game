import 'package:flutter/material.dart';

class GoNextButtonCaption extends StatelessWidget {
  final String text;

  GoNextButtonCaption(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container()),
        Text(text),
        Icon(Icons.arrow_right),
        Expanded(child: Container()),
      ],
    );
  }
}

class WideWidget extends StatelessWidget {
  final Widget child;

  WideWidget({
    @required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: child,
    );
  }
}

class WideButton extends StatelessWidget {
  static const EdgeInsets bottomButtonMargin =
      EdgeInsets.symmetric(vertical: 20.0);

  final Widget child;
  final Color color;
  final VoidCallback onPressed;
  final VoidCallback onPressedDisabled; // executed if onPressed is null
  final EdgeInsets margin;

  WideButton({
    @required this.child,
    this.color,
    @required this.onPressed,
    this.onPressedDisabled,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: WideWidget(
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
