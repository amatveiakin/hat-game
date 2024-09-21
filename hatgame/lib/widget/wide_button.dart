import 'package:flutter/material.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/colors.dart';
import 'package:hatgame/util/widget_state_property.dart';

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

enum WideButtonColoring { neutral, secondary, secondaryAlwaysActive }

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

  static WidgetStateProperty<Color> _getBackgroundColor(Color color) {
    return WidgetStateProperty.resolveWith(
        (states) => greyOutDisabled(states, color));
  }

  static WidgetStateProperty<Color> _getForegroundColor(Color color) {
    return WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.disabled)
            ? toGrey(color).withAlpha(0xa0)
            : color);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ButtonStyle colorStyle = switch (coloring) {
      WideButtonColoring.neutral => ButtonStyle(
          backgroundColor: _getBackgroundColor(MyTheme.primaryPale),
          foregroundColor: _getForegroundColor(Colors.black)),
      WideButtonColoring.secondary => ButtonStyle(
          backgroundColor: _getBackgroundColor(colorScheme.secondary),
          foregroundColor: _getForegroundColor(colorScheme.onSecondary)),
      WideButtonColoring.secondaryAlwaysActive => ButtonStyle(
          backgroundColor: WidgetStateProperty.all(colorScheme.secondary),
          foregroundColor: WidgetStateProperty.all(colorScheme.onSecondary)),
    };
    return Padding(
      padding: margin,
      child: WideWidget(
        child: GestureDetector(
          onTap: onPressed == null ? onPressedDisabled : null,
          child: ElevatedButton(
            onPressed: onPressed,
            style: colorStyle.copyWith(
                padding: WidgetStateProperty.all(
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
