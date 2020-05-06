library game_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'game_state.g.dart';

// TODO: Add @nullable or default

abstract class PlayerState implements Built<PlayerState, PlayerStateBuilder> {
  int get id;
  String get name; // TODO: Fetch name from the config.
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

// TODO: -> WordState?
abstract class Word implements Built<Word, WordBuilder> {
  int get id;
  String get text;
  WordStatus get status;

  Word._();
  factory Word([void Function(WordBuilder) updates]) = _$Word;
  static Serializer<Word> get serializer => _$wordSerializer;
}

abstract class GameState implements Built<GameState, GameStateBuilder> {
  BuiltList<PlayerState> get players;
  // Exactly one of `individualOrder` and `teams` must be set.
  @nullable
  BuiltList<int> get individualOrder;
  // == PlayersConfig.teams, but teams and players within a team are shuffled.
  @nullable
  BuiltList<BuiltList<int>> get teams;
  @nullable
  Party get currentParty;

  // Store word IDs rather than words themselves for disambigution in case
  // two words are equal.
  BuiltList<Word> get words;
  BuiltList<int> get wordsInHat;
  BuiltList<int> get wordsInThisTurn;
  @nullable
  int get currentWord;

  @nullable
  int get turn;
  @nullable
  TurnPhase get turnPhase;

  @nullable
  bool get turnPaused;
  @nullable
  Duration get turnTimeBeforePause;
  @nullable
  DateTime get turnTimeStart;
  @nullable
  DateTime get bonusTimeStart;

  bool get gameFinished;

  GameState._();

  factory GameState([void Function(GameStateBuilder) updates]) = _$GameState;
  static Serializer<GameState> get serializer => _$gameStateSerializer;
}
