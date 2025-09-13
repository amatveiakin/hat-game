library word;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'word.g.dart';

// Unique word ID throughout a game.
//
// When GameExtent is fixedWordSet, `round` in null and `index` is the index in
// `InitialGameState.words`. Otherwise, `round` is the round number and `index`
// starts from 0 each round.
abstract class WordId implements Built<WordId, WordIdBuilder> {
  int? get turnIndex;
  int get index;

  WordId._();
  factory WordId([void Function(WordIdBuilder) updates]) = _$WordId;
  static Serializer<WordId> get serializer => _$wordIdSerializer;
}

abstract class WordContent implements Built<WordContent, WordContentBuilder> {
  String get text;
  BuiltList<String>? get forbiddenWords; // for taboo
  int? get highlightFirst; // for pluralias
  int? get highlightLast; // for pluralias

  factory WordContent.standard(String text) {
    return WordContent((b) => b..text = text);
  }

  factory WordContent.taboo(String text, BuiltList<String> forbiddenWords) {
    return WordContent((b) => b
      ..text = text
      ..forbiddenWords.replace(forbiddenWords));
  }

  factory WordContent.pluralias(String text, int firstLen, int secondLen) {
    return WordContent((b) => b
      ..text = text
      ..highlightFirst = firstLen
      ..highlightLast = secondLen);
  }

  WordContent._();
  factory WordContent([void Function(WordContentBuilder) updates]) =
      _$WordContent;
  static Serializer<WordContent> get serializer => _$wordContentSerializer;
}
