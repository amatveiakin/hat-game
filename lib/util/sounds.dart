import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Sounds {
  static Soundpool _soundpool;

  static int timeOver;

  static Future<void> init() async {
    try {
      await _initImpl().timeout(Duration(seconds: 3));
      debugPrint('Sounds loaded successfully.');
    } catch (e) {
      // TODO: Firebase log.
      debugPrint("Couldn't initialize sounds!");
      debugPrint('The error was: $e');
    }
  }

  static Future<void> _initImpl() async {
    _soundpool = Soundpool();
    timeOver = await _load('sounds/time_over.ogg');
  }

  static void play(int sound) async {
    await _soundpool.play(sound);
  }

  static Future<int> _load(String path) async {
    final asset = await rootBundle.load(path);
    return await _soundpool.load(asset);
  }
}
