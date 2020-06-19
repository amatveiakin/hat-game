library game_state;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:hatgame/built_value/team_compositions.dart';

part 'game_state.g.dart';

// A set of player that participate in a given turn.
// In the classic teams-of-two mode this is a synonym of a team, but it can be
// more (in individual mode) or less (in case of big team with one recipient).
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

abstract class Word implements Built<Word, WordBuilder> {
  int get id;
  String get text;

  Word._();
  factory Word([void Function(WordBuilder) updates]) = _$Word;
  static Serializer<Word> get serializer => _$wordSerializer;
}

abstract class WordInTurn implements Built<WordInTurn, WordInTurnBuilder> {
  int get id;
  WordStatus get status;

  WordInTurn._();
  factory WordInTurn([void Function(WordInTurnBuilder) updates]) = _$WordInTurn;
  static Serializer<WordInTurn> get serializer => _$wordInTurnSerializer;
}

// Generated only in the beginning of the game and immutable since then.
// To decide whether something does into InitialGameState or into GameConfig,
// ask the question: "Will this data be copied as-is for a rematch?"
abstract class InitialGameState
    implements Built<InitialGameState, InitialGameStateBuilder> {
  TeamCompositions get teamCompositions;

  // Store word IDs rather than words themselves for disambigution in case
  // two words are equal.
  BuiltList<Word> get words;

  InitialGameState._();
  factory InitialGameState([void Function(InitialGameStateBuilder) updates]) =
      _$InitialGameState;
  static Serializer<InitialGameState> get serializer =>
      _$initialGameStateSerializer;
}

abstract class TurnRecord implements Built<TurnRecord, TurnRecordBuilder> {
  Party get party;
  BuiltList<WordInTurn> get wordsInThisTurn;

  TurnRecord._();
  factory TurnRecord([void Function(TurnRecordBuilder) updates]) = _$TurnRecord;
  static Serializer<TurnRecord> get serializer => _$turnRecordSerializer;
}

abstract class TurnState implements Built<TurnState, TurnStateBuilder> {
  Party get party;
  BuiltList<WordInTurn> get wordsInThisTurn;

  TurnPhase get turnPhase;

  @nullable
  bool get turnPaused;
  @nullable
  Duration get turnTimeBeforePause;
  @nullable
  DateTime get turnTimeStart;
  @nullable
  DateTime get bonusTimeStart;

  TurnState._();
  factory TurnState([void Function(TurnStateBuilder) updates]) = _$TurnState;
  static Serializer<TurnState> get serializer => _$turnStateSerializer;
}
