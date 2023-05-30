import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:yaml/yaml.dart';

class DictionaryMetadata {
  final String key;
  final String uiName;
  final int numWords;

  DictionaryMetadata(
      {required this.key, required this.uiName, required this.numWords});
}

class Dictionary {
  final DictionaryMetadata metadata;
  final List<String> words;

  Dictionary(this.metadata, this.words);
}

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
  static final _dictionaries = <String, Dictionary>{};

  static Future<void> init() async {
    for (final dictKey in [
      'russian_easy',
      'russian_medium',
      'russian_hard',
      'english_easy',
      'english_medium',
      'english_hard',
    ]) {
      _dictionaries[dictKey] = _parseDictionary(
        key: dictKey,
        yaml: await rootBundle.loadString('lexicon/$dictKey.yaml'),
      );
      Assert.holds(_dictionaries[dictKey]!.words.isNotEmpty);
    }
  }

  static DictionaryMetadata dictionaryMetadata(String dict) {
    return _dictionaries[dict]!.metadata;
  }

  static List<String> allDictionaries() {
    return _dictionaries.keys.toList();
  }

  static List<String> defaultDictionaries() {
    final List<String> result = ['russian_medium'];
    Assert.subset(result, allDictionaries().toSet());
    return result;
  }

  static List<String> fixDictionaries(List<String>? dicts) {
    final existingDicts =
        (dicts ?? []).toSet().intersection(allDictionaries().toSet());
    return existingDicts.isEmpty
        ? defaultDictionaries()
        : existingDicts.toList();
  }

  static WordCollection wordCollection(Iterable<String> dictionaries) {
    Assert.holds(dictionaries.isNotEmpty);
    final List<String> words = [];
    for (final dictKey in dictionaries) {
      if (!_dictionaries.containsKey(dictKey)) {
        throw InvalidOperation(tr('cannot_find_dictionary', args: [dictKey]),
            isInternalError: true);
      }
      words.addAll(_dictionaries[dictKey]!.words);
    }
    Assert.holds(words.isNotEmpty, lazyMessage: () => dictionaries.toString());
    return WordCollection(words);
  }

  // Collection that contains most words. May blacklist some categories,
  // e.g. obscene words.
  static WordCollection universalCollection() {
    return wordCollection(_dictionaries.keys);
  }

  static Dictionary _parseDictionary(
      {required String key, required String yaml}) {
    final List<YamlDocument> docs =
        loadYamlDocuments(yaml, sourceUrl: Uri.file(key));
    Assert.holds(docs.isNotEmpty);
    Assert.le(docs.length, 2);

    final YamlDocument dataDoc = docs.last;
    Assert.holds(dataDoc.contents is YamlList);
    final dataList = dataDoc.contents as YamlList;
    final int numWords = dataList.length;

    DictionaryMetadata metadata;
    if (docs.length == 2) {
      final YamlDocument metadataDoc = docs.first;
      Assert.holds(metadataDoc.contents is YamlMap);
      final metadataMap = metadataDoc.contents as YamlMap;
      metadata = DictionaryMetadata(
        key: key,
        uiName: metadataMap['name'] ?? key,
        numWords: numWords,
      );
    } else {
      metadata = DictionaryMetadata(
        key: key,
        uiName: key,
        numWords: numWords,
      );
    }

    return Dictionary(metadata, List.from(dataList.value));
  }
}
