import 'package:flutter/material.dart';

class MyColors {
  static black(int v) => Color.fromARGB(255, v, v, v);
}

Color toGrey(Color color) {
  return HSLColor.fromColor(color).withSaturation(0).toColor();
}
