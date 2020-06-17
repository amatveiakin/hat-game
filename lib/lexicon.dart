import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';

class WordCollection {
  // TODO: Come up with a balanced strategy somewhere between 'take words
  // proportionally to dictionary size' and 'take words from all dictionaries
  // with the same probability'.
  final List<String> _words;

  WordCollection(this._words);

  String randomWord() {
    return _words[Random().nextInt(_words.length)];
  }
}

class Lexicon {
  static final _dictionaries = Map<String, List<String>>();

  static Future<void> init() async {
    for (final dict in [
      'russian_easy',
      'russian_medium',
      'russian_hard',
    ]) {
      _dictionaries[dict] =
          (await rootBundle.loadString('lexicon/$dict.txt')).split('\n');
      Assert.holds(_dictionaries[dict].isNotEmpty);
    }
  }

  static List<String> allDictionaries() {
    return _dictionaries.keys.toList();
  }

  static List<String> defaultDictionaries() {
    final List<String> result = ['russian_medium'];
    Assert.subset(result, allDictionaries().toSet());
    return result;
  }

  static List<String> fixDictionaries(List<String> dicts) {
    final existingDicts =
        (dicts ?? []).toSet().intersection(allDictionaries().toSet());
    return existingDicts.isEmpty
        ? defaultDictionaries()
        : existingDicts.toList();
  }

  static WordCollection wordCollection(List<String> dictionaries) {
    Assert.holds(dictionaries.isNotEmpty);
    final words = List<String>();
    for (final dict in dictionaries) {
      if (!_dictionaries.containsKey(dict)) {
        throw InvalidOperation(tr('cannot_find_dictionary', args: [dict]),
            isInternalError: true);
      }
      words.addAll(_dictionaries[dict]);
    }
    Assert.holds(words.isNotEmpty, lazyMessage: () => dictionaries.toString());
    return WordCollection(words);
  }

  // Collection that contains most words. May blacklist some categories,
  // e.g. obscene words.
  static WordCollection universalCollection() {
    return wordCollection(_dictionaries.keys);
  }
}
