import 'dart:ui' as ui;

import 'package:flutter/services.dart';

Future<ui.Image> loadAssetImage(String path) async {
  final ByteData data = await rootBundle.load(path);
  final ui.Codec codec =
      await ui.instantiateImageCodec(data.buffer.asUint8List());
  final ui.FrameInfo fi = await codec.getNextFrame();
  return fi.image;
}
