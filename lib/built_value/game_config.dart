library game_config;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'game_config.g.dart';

// =============================================================================
// Rules

abstract class RulesConfig implements Built<RulesConfig, RulesConfigBuilder> {
  int get turnSeconds;
  int get bonusSeconds;
  int get wordsPerPlayer;

  RulesConfig._();

  factory RulesConfig([void Function(RulesConfigBuilder) updates]) =
      _$RulesConfig;

  static Serializer<RulesConfig> get serializer => _$rulesConfigSerializer;
}

// =============================================================================
// Teaming

class IndividualPlayStyle extends EnumClass {
  static const IndividualPlayStyle chain = _$chain;
  static const IndividualPlayStyle fluidPairs = _$fluidPairs;
  // TODO: Expose "each to all" (non-competitive) mode publicly (?)
  static const IndividualPlayStyle broadcast = _$broadcast;

  const IndividualPlayStyle._(String name) : super(name);

  static BuiltSet<IndividualPlayStyle> get values =>
      _$valuesIndividualPlayStyle;
  static IndividualPlayStyle valueOf(String name) =>
      _$valueOfIndividualPlayStyle(name);
  static Serializer<IndividualPlayStyle> get serializer =>
      _$individualPlayStyleSerializer;
}

class DesiredTeamSize extends EnumClass {
  static const DesiredTeamSize teamsOf2 = _$teamsOf2;
  static const DesiredTeamSize teamsOf3 = _$teamsOf3;
  static const DesiredTeamSize teamsOf4 = _$teamsOf4;
  static const DesiredTeamSize twoTeams = _$twoTeams;

  const DesiredTeamSize._(String name) : super(name);

  static BuiltSet<DesiredTeamSize> get values => _$valuesDesiredTeamSize;
  static DesiredTeamSize valueOf(String name) => _$valueOfDesiredTeamSize(name);
  static Serializer<DesiredTeamSize> get serializer =>
      _$desiredTeamSizeSerializer;
}

class UnequalTeamSize extends EnumClass {
  static const UnequalTeamSize forbid = _$forbid;
  static const UnequalTeamSize expandTeams = _$expandTeams;
  static const UnequalTeamSize dropPlayers = _$dropPlayers;

  const UnequalTeamSize._(String name) : super(name);

  static BuiltSet<UnequalTeamSize> get values => _$valuesUnequalTeamSize;
  static UnequalTeamSize valueOf(String name) => _$valueOfUnequalTeamSize(name);
  static Serializer<UnequalTeamSize> get serializer =>
      _$unequalTeamSizeSerializer;
}

abstract class TeamingConfig
    implements Built<TeamingConfig, TeamingConfigBuilder> {
  bool get teamPlay;
  bool get randomizeTeams;
  IndividualPlayStyle get individualPlayStyle;
  DesiredTeamSize get desiredTeamSize;
  UnequalTeamSize get unequalTeamSize;
  IndividualPlayStyle get guessingInLargeTeam;

  TeamingConfig._();

  factory TeamingConfig([void Function(TeamingConfigBuilder) updates]) =
      _$TeamingConfig;

  static Serializer<TeamingConfig> get serializer => _$teamingConfigSerializer;
}

// =============================================================================
// Players

abstract class PlayersConfig
    implements Built<PlayersConfig, PlayersConfigBuilder> {
  // Exactly one of `names` and `namesByTeam` must be set.
  @nullable BuiltList<String> get names;
  @nullable BuiltList<BuiltList<String>> get namesByTeam;

  PlayersConfig._();

  factory PlayersConfig([void Function(PlayersConfigBuilder) updates]) =
      _$PlayersConfig;

  static Serializer<PlayersConfig> get serializer => _$playersConfigSerializer;
}

// =============================================================================
// All together

abstract class GameConfig implements Built<GameConfig, GameConfigBuilder> {
  RulesConfig get rules;
  TeamingConfig get teaming;
  PlayersConfig get players;

  GameConfig._();

  factory GameConfig([void Function(GameConfigBuilder) updates]) = _$GameConfig;

  static Serializer<GameConfig> get serializer => _$gameConfigSerializer;
}
