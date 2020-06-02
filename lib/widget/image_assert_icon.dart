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
        color: iconTheme.color,
      ),
    );
  }
}
