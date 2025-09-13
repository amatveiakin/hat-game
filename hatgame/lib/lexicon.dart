import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hatgame/built_value/word.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:hatgame/util/local_str.dart';
import 'package:yaml/yaml.dart';

enum DictionaryKind {
  standard,
  taboo,
}

class DictionaryMetadata {
  final String key;
  final String uiName;
  final DictionaryKind kind;
  final int numWords;

  DictionaryMetadata(
      {required this.key,
      required this.uiName,
      required this.kind,
      required this.numWords});
}

class Dictionary {
  final DictionaryMetadata metadata;
  final List<WordContent> words;

  Dictionary(this.metadata, this.words);
}

class WordCollection {
  // TODO: Come up with a balanced strategy somewhere between 'take words
  // proportionally to dictionary size' and 'take words from all dictionaries
  // with the same probability'.
  final List<WordContent> _words;
  final List<double>? _cumulativeWeights;

  WordCollection(this._words, {List<double>? weights})
      : _cumulativeWeights =
            weights == null ? null : computeCumulativeWeights(weights);

  WordContent randomWord() {
    if (_cumulativeWeights == null) {
      return _words[Random().nextInt(_words.length)];
    } else {
      final double r = Random().nextDouble();
      int i = lowerBound(_cumulativeWeights!, r);
      Assert.lt(i, _words.length, inRelease: AssertInRelease.log);
      i = min(i, _words.length - 1);
      return _words[i];
    }
  }
}

List<double> computeCumulativeWeights(List<double> weights) {
  double sum = 0.0;
  final List<double> cumulativeWeights = [];
  for (final w in weights) {
    sum += w;
    cumulativeWeights.add(sum);
  }
  Assert.holds(sum > 0);
  for (int i = 0; i < cumulativeWeights.length; i++) {
    cumulativeWeights[i] /= sum;
  }
  return cumulativeWeights;
}

class _DoubleWord {
  final String first;
  final String second;
  final String intersection;
  final String union;

  _DoubleWord(
      {required this.first,
      required this.second,
      required this.intersection,
      required this.union});
}

// TODO: Make dataclass when https://dart.dev/language/macros is stable.
class _WordCollectionKey {
  final BuiltList<String> dictionaries;
  final bool pluralias;

  _WordCollectionKey(this.dictionaries, this.pluralias);

  @override
  bool operator ==(Object other) {
    return other is _WordCollectionKey &&
        dictionaries == other.dictionaries &&
        pluralias == other.pluralias;
  }

  @override
  int get hashCode => Object.hash(dictionaries.hashCode, pluralias.hashCode);
}

class Lexicon {
  static final _dictionaries = <String, Dictionary>{};
  static final _wordCollectionCache = <_WordCollectionKey, WordCollection>{};

  static Future<void> init() async {
    for (final dictKey in [
      'russian_easy',
      'russian_medium',
      'russian_hard',
      'russian_neo',
      'russian_taboo_easy',
      'english_easy',
      'english_medium',
      'english_hard',
      'english_taboo_easy',
    ]) {
      _dictionaries[dictKey] = _parseDictionary(
        key: dictKey,
        yaml: await rootBundle.loadString('lexicon/$dictKey.yaml'),
      );
      Assert.holds(_dictionaries[dictKey]!.words.isNotEmpty);
    }
  }

  static Dictionary dictionary(String dictKey) {
    if (!_dictionaries.containsKey(dictKey)) {
      throw InvalidOperation(
          LocalStr.tr('cannot_find_dictionary', args: [dictKey]),
          isInternalError: true);
    }
    return _dictionaries[dictKey]!;
  }

  static DictionaryMetadata dictionaryMetadata(String dictKey) {
    return dictionary(dictKey).metadata;
  }

  static List<String> allDictionaries({DictionaryKind? kind}) {
    return kind == null
        ? _dictionaries.keys.toList()
        : _dictionaries.keys
            .where((d) => dictionaryMetadata(d).kind == kind)
            .toList();
  }

  static List<String> defaultStandardDictionaries() {
    final List<String> result = ['russian_medium'];
    Assert.subset(result, allDictionaries().toSet());
    Assert.holds(result
        .every((d) => dictionaryMetadata(d).kind == DictionaryKind.standard));
    return result;
  }

  static List<String> defaultTabooDictionaries() {
    final List<String> result = ['russian_taboo_easy'];
    Assert.subset(result, allDictionaries().toSet());
    Assert.holds(result
        .every((d) => dictionaryMetadata(d).kind == DictionaryKind.taboo));
    return result;
  }

  // TODO: Pre-compute relevant WordCollection when words are generated on the
  // flight (i.e. when extent is not fixedWordSet). Consider if we should do the
  // pre-computation in background and store `Futures` in the cache.
  static WordCollection wordCollection(
      Iterable<String> dictionaries, bool pluralias) {
    final key = _WordCollectionKey(BuiltList(dictionaries), pluralias);
    return _wordCollectionCache.putIfAbsent(key, () {
      final stopwatch = Stopwatch()..start();
      final collection = pluralias
          ? _makePluraliasCollection(dictionaries)
          : _makeUnionCollection(dictionaries);
      debugPrint("Took ${stopwatch.elapsed} to build WordCollection "
          "for $dictionaries, pluralias=$pluralias");
      return collection;
    });
  }

  static WordCollection _makeUnionCollection(Iterable<String> dictionaries) {
    return WordCollection(
        dictionaries.map((d) => dictionary(d).words).flattened.toList());
  }

  static WordCollection _makePluraliasCollection(
      Iterable<String> dictionaries) {
    Assert.holds(dictionaries.isNotEmpty);
    final List<String> words = [];
    for (final dictKey in dictionaries) {
      for (final w in dictionary(dictKey).words) {
        Assert.eq(w.highlightFirst, null);
        Assert.eq(w.highlightLast, null);
        words.add(w.text);
      }
    }
    Assert.holds(words.isNotEmpty, lazyMessage: () => dictionaries.toString());

    // TODO: Reduce to 2, but boost longer intersections.
    const minIntersectionLength = 3;
    final Set<String> allWordsSet =
        universalCollection()._words.map((word) => word.text).toSet();
    final Map<String, List<String>> prefixToWords = {};
    for (final w in words) {
      for (int i = minIntersectionLength; i <= w.length - 1; i++) {
        final prefix = w.substring(0, i);
        prefixToWords.putIfAbsent(prefix, () => []).add(w);
      }
    }
    final List<_DoubleWord> doubleWords = [];
    for (final first in words) {
      for (int i = 1; i <= first.length - minIntersectionLength; i++) {
        final intersection = first.substring(i);
        for (final second in prefixToWords[intersection].orEmpty()) {
          final union = first.substring(0, i) + second;
          // If the word could be constructed as a one-letter-intersection
          // pluralias or as a pure concatenation, it is likely to be misread.
          bool confusing = false;
          for (int j = 1; j < union.length - 2; j++) {
            if (allWordsSet.contains(union.substring(0, j + 1)) &&
                allWordsSet.contains(union.substring(j))) {
              confusing = true;
              break;
            }
          }
          for (int j = 1; j < union.length - 1; j++) {
            if (allWordsSet.contains(union.substring(0, j)) &&
                allWordsSet.contains(union.substring(j))) {
              confusing = true;
              break;
            }
          }
          if (!confusing) {
            doubleWords.add(_DoubleWord(
                first: first,
                second: second,
                intersection: intersection,
                union: union));
          }
        }
      }
    }
    // Some words are easier to combine than others and they tend to overwhelm
    // the distribution as the result. We fix this by promoting words and ways
    // of combining words that appear less often.
    final Map<String, int> wordFreq = {};
    final Map<String, int> intersectionFreq = {};
    for (final w in doubleWords) {
      wordFreq.update(w.first, (x) => x + 1, ifAbsent: () => 1);
      wordFreq.update(w.second, (x) => x + 1, ifAbsent: () => 1);
      intersectionFreq.update(w.intersection, (x) => x + 1, ifAbsent: () => 1);
    }
    final weights = doubleWords.map((w) {
      // Power 1/3 was chosen empirically.
      // Min ensures that unique pairings do not get overpromoted.
      return min(
          0.1,
          1.0 /
              pow(
                  wordFreq[w.first]! *
                      wordFreq[w.second]! *
                      intersectionFreq[w.intersection]!,
                  1.0 / 3.0));
    }).toList();
    return WordCollection(
        doubleWords
            .map((w) =>
                WordContent.pluralias(w.union, w.first.length, w.second.length))
            .toList(),
        weights: weights);
  }

  // Collection that contains most words. May blacklist some categories,
  // e.g. obscene words.
  static WordCollection universalCollection() {
    return wordCollection(_dictionaries.keys, false);
  }

  static Dictionary _parseDictionary(
      {required String key, required String yaml}) {
    final List<YamlDocument> docs =
        loadYamlDocuments(yaml, sourceUrl: Uri.file(key));
    Assert.eq(docs.length, 2);

    DictionaryMetadata metadata;
    final YamlDocument metadataDoc = docs[0];
    Assert.holds(metadataDoc.contents is YamlMap);
    final metadataMap = metadataDoc.contents as YamlMap;
    final uiName = metadataMap['name'] as String;
    final kind = DictionaryKind.values.byName(metadataMap['kind'] as String);

    final YamlDocument dataDoc = docs[1];
    final List<WordContent> words;
    switch (kind) {
      case DictionaryKind.standard:
        words = (Assert.type<YamlList>(dataDoc.contents))
            .map((e) => WordContent.standard(e as String))
            .toList();
        break;
      case DictionaryKind.taboo:
        words = Assert.type<YamlMap>(dataDoc.contents)
            .entries
            .map((e) => WordContent.taboo(
                e.key as String,
                Assert.type<YamlList>(e.value)
                    .map((e) => e as String)
                    .toBuiltList()))
            .toList();
        break;
    }

    metadata = DictionaryMetadata(
      key: key,
      uiName: uiName,
      kind: kind,
      numWords: words.length,
    );
    return Dictionary(metadata, words);
  }
}
