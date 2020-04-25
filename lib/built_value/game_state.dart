library game_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'game_state.g.dart';

// TODO: Add @nullable or default

abstract class PlayerState implements Built<PlayerState, PlayerStateBuilder> {
  int get id;
  String get name;
  BuiltList<int> get wordsExplained;
  BuiltList<int> get wordsGuessed;

  PlayerState._();
  factory PlayerState([updates(PlayerStateBuilder b)]) = _$PlayerState;
  static Serializer<PlayerState> get serializer => _$playerStateSerializer;
}

// A set of player that participate in a given turn.
// In the classic mode this is a synonym of a team, but it can be more
// (in individual mode) or less (in case of big team with one recipient).
abstract class Party implements Built<Party, PartyBuilder> {
  int get performer;
  BuiltList<int> get recipients;

  Party._();
  factory Party([void Function(PartyBuilder) updates]) = _$Party;
  static Serializer<Party> get serializer => _$partySerializer;
}

class TurnPhase extends EnumClass {
  static const TurnPhase prepare = _$prepare;
  static const TurnPhase explain = _$explain;
  static const TurnPhase review = _$review;

  const TurnPhase._(String name) : super(name);

  static BuiltSet<TurnPhase> get values => _$valuesTurnPhase;
  static TurnPhase valueOf(String name) => _$valueOfTurnPhase(name);
  static Serializer<TurnPhase> get serializer => _$turnPhaseSerializer;
}

class WordStatus extends EnumClass {
  static const WordStatus notExplained = _$notExplained;
  static const WordStatus explained = _$explained;
  static const WordStatus discarded = _$discarded;

  const WordStatus._(String name) : super(name);

  static BuiltSet<WordStatus> get values => _$valuesWordStatus;
  static WordStatus valueOf(String name) => _$valueOfWordStatus(name);
  static Serializer<WordStatus> get serializer => _$wordStatusSerializer;
}

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

// TODO: -> WordState? (OR PlayerState -> Player)
abstract class Word implements Built<Word, WordBuilder> {
  int get id;
  String get text;
  WordStatus get status;
  // There is a difference between feedback and status. We allow several
  // copies of the same word (in manual word writing mode) and store the
  // status separately for each copy. This is entirely reasonable.
  // For feedback it doesn't quite make sense ("This 'cat' is too easy, but
  // this 'cat' is totally good"?) so I conisdered storing feedback as a map
  // keys by word text rather than word ID. This is however likely to produce
  // bad UX. Seeing the same word for the seconds time is already a mindfuck,
  // and if it appears that you've already given feedback to it, that would
  // make it look even more like a glitch in the app.
  // TODO: Make feedback per-player in online mode.
  // TODO: Allow to also change word tags (when we have word tags).
  @nullable
  WordFeedback get feedback;

  Word._();
  factory Word([void Function(WordBuilder) updates]) = _$Word;
  static Serializer<Word> get serializer => _$wordSerializer;
}

abstract class GameState implements Built<GameState, GameStateBuilder> {
  BuiltList<PlayerState> get players;
  @nullable
  BuiltList<BuiltList<int>> get teams;
  @nullable
  Party get currentParty;

  // Store word IDs rather than words themselves for disambigution in case
  // two words are equal.
  BuiltList<Word> get words;
  BuiltList<int> get wordsInHat;
  @nullable
  BuiltList<int> get wordsInThisTurn;
  @nullable
  int get currentWord;

  @nullable
  int get turn;
  @nullable
  TurnPhase get turnPhase;
  bool get gameFinished;

  GameState._();

  factory GameState([void Function(GameStateBuilder) updates]) = _$GameState;
  static Serializer<GameState> get serializer => _$gameStateSerializer;
}

@SerializersFor([
  GameState,
])
final Serializers serializers = _$serializers;
