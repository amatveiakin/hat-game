import 'dart:io';

import 'english.dart';
import 'russian.dart';

Never wrongUsage() {
  stderr.write('Usage:\n'
      '  <app>  en  <google-10000-english-no-swears.txt>  <index.noun>  <nounlist>\n'
      '  <app>  ru  <freqrnc2011.csv>\n');
  exit(1);
}

// Parser for http://dict.ruslang.ru/freq.php
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    wrongUsage();
  }
  final String language = arguments[0];
  if (language == 'en') {
    if (arguments.length != 4) {
      wrongUsage();
    }
    await makeEnglishDictionaries(arguments[1], arguments[2], arguments[3]);
  } else if (language == 'ru') {
    if (arguments.length != 2) {
      wrongUsage();
    }
    await makeRussianDictionaries(arguments[1]);
  } else {
    wrongUsage();
  }
  exit(0);
}
