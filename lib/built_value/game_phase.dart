library game_phase;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'game_phase.g.dart';

class GamePhase extends EnumClass {
  // Normal game phases.
  static const GamePhase configure = _$configure;
  static const GamePhase writeWords = _$writeWords;
  static const GamePhase composeTeams = _$composeTeams;
  static const GamePhase play = _$play;
  static const GamePhase gameOver = _$gameOver;

  // Special personal phases. Game cannot be in this phase.
  static const GamePhase kicked = _$kicked;

  const GamePhase._(String name) : super(name);

  static BuiltSet<GamePhase> get values => _$values;
  static GamePhase valueOf(String name) => _$valueOf(name);
  static Serializer<GamePhase> get serializer => _$gamePhaseSerializer;
}
