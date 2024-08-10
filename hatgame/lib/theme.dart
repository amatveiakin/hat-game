import 'package:flutter/material.dart';

final buttonBorderRadius = BorderRadius.circular(8.0);

class MyTheme {
  static const primary = MaterialColor(0xff4b0082, {
    50: Color(0xffdaa8ff),
    100: Color(0xffdaa8ff),
    200: Color(0xffbf68ff),
    300: Color(0xffbf68ff),
    400: Color(0xff882acc),
    500: Color(0xff4b0082),
    600: Color(0xff4b0082),
    700: Color(0xff310062),
    800: Color(0xff310062),
    900: Color(0xff210041),
  });
  static const primaryPale = Color(0xffccb8db);
  static const onPrimary = Color(0xffffffff);
  static const secondary = Color(0xffafc3c4);
  static const secondaryIntense = Color(0xff78b8bc);
}
