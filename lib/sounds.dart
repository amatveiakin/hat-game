import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Sounds {
  static Soundpool _soundpool;

  static Future<int> timeOver;

  // TODO: Can we wait until init is finished before starting the app?
  static void init() {
    _soundpool = Soundpool();
    timeOver = _load('sounds/time_over.wav');
  }

  static void play(Future<int> sound) async {
    await _soundpool.play(await sound);
  }

  static Future<int> _load(String path) async {
    final asset = await rootBundle.load(path);
    return await _soundpool.load(asset);
  }
}
