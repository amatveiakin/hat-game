import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

class Lexion {
  static List<String> _words;

  static Future<void> init() async {
    _words =
        (await rootBundle.loadString('lexicon/russian_normal.txt')).split('\n');
  }

  static String randomWord() {
    return _words[Random().nextInt(_words.length)];
  }
}
