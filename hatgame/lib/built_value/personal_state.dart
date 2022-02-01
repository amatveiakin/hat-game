library player_info;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'personal_state.g.dart';

// There is a difference between feedback and status. We allow several
// copies of the same word (in manual word writing mode) and store the
// status separately for each copy. This is entirely reasonable.
// For feedback it doesn't quite make sense ("This 'cat' is too easy, but
// this 'cat' is totally good"?) so I conisdered storing feedback as a map
// keys by word text rather than word ID. This is however likely to produce
// bad UX. Seeing the same word for the seconds time is already a mindfuck,
// and if it appears that you've already given feedback to it, that would
// make it look even more like a glitch in the app.
// TODO: Allow to also change word tags (when we have word tags).
class WordFeedback extends EnumClass {
  static const WordFeedback good = _$good;
  static const WordFeedback bad = _$bad;
  static const WordFeedback tooEasy = _$tooEasy;
  static const WordFeedback tooHard = _$tooHard;

  const WordFeedback._(String name) : super(name);
  static BuiltSet<WordFeedback> get values => _$valuesWordFeedback;
  static WordFeedback valueOf(String name) => _$valueOfWordFeedback(name);
  static Serializer<WordFeedback> get serializer => _$wordFeedbackSerializer;
}

// Combines:
//   - Player login information (relevant before the game has started)
//   - Various per-player information that is not core to the game.
//     GameState should never depend on it directly. Can be updated only
//     by the corresponding player.
// TODO: Split the two.
abstract class PersonalState
    implements Built<PersonalState, PersonalStateBuilder> {
  // TODO: Mark things that don't make sense in offline mode as nullable OR
  // move everything else to a separate class and reference it from here.
  int get id;
  String get name;

  bool? get kicked;

  // only with manual word-writing
  BuiltList<String>? get words;
  bool? get wordsReady;

  BuiltMap<int, WordFeedback> get wordFeedback;
  BuiltSet<int> get wordFlags;

  PersonalState._();
  factory PersonalState([updates(PersonalStateBuilder b)]) = _$PersonalState;
  static Serializer<PersonalState> get serializer => _$personalStateSerializer;
}
