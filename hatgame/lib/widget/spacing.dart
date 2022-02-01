import 'package:flutter/material.dart';

List<Widget> addSpacing(
    {required List<Widget> tiles, double? horizontal, double? vertical}) {
  return tiles.isEmpty
      ? tiles
      : tiles.skip(1).fold(
          [tiles.first],
          (list, tile) =>
              list + [SizedBox(width: horizontal, height: vertical), tile]);
}
