import 'package:flutter/material.dart';
import 'package:hatgame/util/colors.dart';

Color greyOutDisabled(Set<WidgetState> states, Color color) {
  return states.contains(WidgetState.disabled) ? toGrey(color) : color;
}
