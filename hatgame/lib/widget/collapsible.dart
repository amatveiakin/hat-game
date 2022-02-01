import 'package:flutter/material.dart';

class Collapsible extends StatelessWidget {
  static const double expandButtonWidth = 36;

  final bool collapsed;
  final void Function(bool) onCollapsedChanged;
  final Widget child;

  Collapsible({
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
        Container(
          width: expandButtonWidth,
          child: FlatButton(
            padding: EdgeInsets.zero,
            // TODO: Take colors from the theme.
            color: Colors.black.withOpacity(0.15),
            hoverColor: Colors.black.withOpacity(0.20),
            child: collapsed
                ? Icon(Icons.chevron_left)
                : Icon(Icons.chevron_right),
            onPressed: () => onCollapsedChanged(!collapsed),
          ),
        ),
        if (!collapsed) child,
      ],
    );
  }
}
