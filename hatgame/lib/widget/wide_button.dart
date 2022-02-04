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
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: child,
    );
  }
}

enum WideButtonColoring { neutral, secondary }

class WideButton extends StatelessWidget {
  static const EdgeInsets bottomButtonMargin =
      EdgeInsets.symmetric(vertical: 20.0);

  final Widget child;
  final WideButtonColoring coloring;
  final VoidCallback? onPressed;
  final VoidCallback? onPressedDisabled; // executed if onPressed is null
  final EdgeInsets margin;

  WideButton({
    required this.child,
    required this.coloring,
    required this.onPressed,
    this.onPressedDisabled,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    late final ButtonStyle colorStyle;
    switch (coloring) {
      case WideButtonColoring.neutral:
        colorStyle = ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.grey[300]),
            foregroundColor: MaterialStateProperty.all(Colors.black));
        break;
      case WideButtonColoring.secondary:
        colorStyle = ButtonStyle(
            backgroundColor: MaterialStateProperty.all(colorScheme.secondary),
            foregroundColor:
                MaterialStateProperty.all(colorScheme.onSecondary));
        break;
    }
    return Padding(
      padding: margin,
      child: WideWidget(
        child: GestureDetector(
          child: ElevatedButton(
            onPressed: onPressed,
            style: colorStyle.copyWith(
                padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12.0))),
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
