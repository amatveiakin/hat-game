import 'package:flutter/material.dart';

class Collapsible extends StatelessWidget {
  static const double expandButtonWidth = 36;

  final bool collapsed;
  final void Function(bool) onCollapsedChanged;
  final Widget child;

  const Collapsible({
    super.key,
    required this.collapsed,
    required this.onCollapsedChanged,
    required this.child,
  });

  // TODO: Consider adding AnimatedSize.
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: expandButtonWidth,
          child: TextButton(
            style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.zero),
                // TODO: Take colors from the theme.
                backgroundColor: MaterialStateProperty.resolveWith((states) =>
                    states.contains(MaterialState.hovered)
                        ? Colors.black.withOpacity(0.20)
                        : Colors.black.withOpacity(0.15))),
            child: collapsed
                ? const Icon(Icons.chevron_left)
                : const Icon(Icons.chevron_right),
            onPressed: () => onCollapsedChanged(!collapsed),
          ),
        ),
        if (!collapsed) child,
      ],
    );
  }
}
