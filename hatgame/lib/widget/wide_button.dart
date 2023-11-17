import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/colors.dart';

class GoNextButtonCaption extends StatelessWidget {
  final String text;

  const GoNextButtonCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container()),
        Text(text),
        const Icon(Icons.arrow_right),
        Expanded(child: Container()),
      ],
    );
  }
}

class WideWidget extends StatelessWidget {
  final Widget child;

  const WideWidget({
    super.key,
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

  const WideButton({
    super.key,
    required this.child,
    required this.coloring,
    required this.onPressed,
    this.onPressedDisabled,
    this.margin = EdgeInsets.zero,
  });

  static MaterialStateProperty<Color> _getBackgroundColor(Color color) {
    return MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.disabled) ? toGrey(color) : color);
  }

  static MaterialStateProperty<Color> _getForegroundColor(Color color) {
    return MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.disabled)
            ? toGrey(color).withAlpha(0xa0)
            : color);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    late final ButtonStyle colorStyle;
    switch (coloring) {
      case WideButtonColoring.neutral:
        colorStyle = ButtonStyle(
            backgroundColor: _getBackgroundColor(MyTheme.primary[100]!),
            foregroundColor: _getForegroundColor(Colors.black));
        break;
      case WideButtonColoring.secondary:
        colorStyle = ButtonStyle(
            backgroundColor: _getBackgroundColor(colorScheme.secondary),
            foregroundColor: _getForegroundColor(colorScheme.onSecondary));
        break;
    }
    return Padding(
      padding: margin,
      child: WideWidget(
        child: GestureDetector(
          onTap: onPressed == null ? onPressedDisabled : null,
          child: ElevatedButton(
            onPressed: onPressed,
            style: colorStyle.copyWith(
                padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12.0)),
                visualDensity: VisualDensity.standard),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
