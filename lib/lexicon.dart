import 'dart:math';

import 'package:russian_words/russian_words.dart' as russian_words;

class Lexion {
  static String randomWord() {
    while (true) {
      final String word =
          russian_words.nouns[Random().nextInt(russian_words.nouns.length)];
      // This dictionary contains a lot of words with diminutive sufficies -
      // try to filter them out. This will also throw away some legit words,
      // but that's ok. Eventually we'll find a better dictionary.
      if (word.toLowerCase() == word &&
          !word.endsWith('ик') &&
          !word.endsWith('ек') &&
          !word.endsWith('ок')) {
        return word;
      }
    }
  }
}
