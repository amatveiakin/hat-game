import 'package:flutter/material.dart';

class ImageAssetIcon extends StatelessWidget {
  final String name;

  ImageAssetIcon(this.name);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      name,
      color: IconTheme.of(context).color,
    );
  }
}
