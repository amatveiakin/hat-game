import 'package:flutter/material.dart';

class ImageAssetIcon extends StatelessWidget {
  final String name;

  ImageAssetIcon(this.name);

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return SizedBox.fromSize(
      size: Size.square(iconTheme.size),
      child: Image.asset(
        name,
        // Note: re-coloring doesn't work on web. This has already been fixed
        // in Flutter master: https://github.com/flutter/engine/pull/18111
        color: iconTheme.color,
      ),
    );
  }
}
