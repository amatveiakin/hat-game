library game_config;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:hatgame/util/assertion.dart';

part 'game_config.g.dart';

// =============================================================================
// Rules

class GameVariant extends EnumClass {
  static const GameVariant standard = _$standard;
  static const GameVariant writeWords = _$writeWords;
  static const GameVariant pluralias = _$pluralias;

  const GameVariant._(String name) : super(name);
  static BuiltSet<GameVariant> get values => _$valuesGameVariant;
  static GameVariant valueOf(String name) => _$valueOfGameVariant(name);
  static Serializer<GameVariant> get serializer => _$gameVariantSerializer;
}

abstract class RulesConfig implements Built<RulesConfig, RulesConfigBuilder> {
  int get turnSeconds;
  int get bonusSeconds;
  int get wordsPerPlayer;
  GameVariant get variant;
  BuiltList<String> get dictionaries; // used if variant != manual

  RulesConfig._();
  factory RulesConfig([void Function(RulesConfigBuilder) updates]) =
      _$RulesConfig;
  static Serializer<RulesConfig> get serializer => _$rulesConfigSerializer;
}

// =============================================================================
// Teaming

class TeamingStyle extends EnumClass {
  static const TeamingStyle individual = _$individual;
  static const TeamingStyle oneToAll = _$oneToAll;
  static const TeamingStyle randomPairs = _$randomPairs;
  static const TeamingStyle randomTeams = _$randomTeams;
  static const TeamingStyle manualTeams = _$manualTeams;
  // TODO:
  // static const TeamingStyle namedTeams = _$namedTeams;

  const TeamingStyle._(String name) : super(name);
  static BuiltSet<TeamingStyle> get values => _$valuesTeamingStyle;
  static TeamingStyle valueOf(String name) => _$valueOfTeamingStyle(name);
  static Serializer<TeamingStyle> get serializer => _$teamingStyleSerializer;

  bool teamPlay() {
    return switch (this) {
      TeamingStyle.individual => false,
      TeamingStyle.oneToAll => false,
      TeamingStyle.randomPairs => true,
      TeamingStyle.randomTeams => true,
      TeamingStyle.manualTeams => true,
      _ => Assert.unexpectedValue(this),
    };
  }
}

abstract class TeamingConfig
    implements Built<TeamingConfig, TeamingConfigBuilder> {
  // TODO: Add "Randomize order" option when it's not implied, i.e. for:
  // individual, oneToAll, manualTeams.
  TeamingStyle get teamingStyle;
  int get numTeams; // used if teamingStyle == randomTeams

  TeamingConfig._();
  factory TeamingConfig([void Function(TeamingConfigBuilder) updates]) =
      _$TeamingConfig;
  static Serializer<TeamingConfig> get serializer => _$teamingConfigSerializer;
}

// =============================================================================
// Players

abstract class PlayersConfig
    implements Built<PlayersConfig, PlayersConfigBuilder> {
  // Maps to player ID to player name.
  BuiltMap<int, String> get names;
  // Set only if manual teaming.
  BuiltList<BuiltList<int>>? get teams;

  PlayersConfig._();
  factory PlayersConfig([void Function(PlayersConfigBuilder) updates]) =
      _$PlayersConfig;
  static Serializer<PlayersConfig> get serializer => _$playersConfigSerializer;

  void checkInvariant() {
    if (teams != null) {
      for (final t in teams!) {
        for (final p in t) {
          Assert.holds(names.containsKey(p), lazyMessage: () => toString());
        }
      }
    }
  }
}

// =============================================================================
// All together

abstract class GameConfig implements Built<GameConfig, GameConfigBuilder> {
  RulesConfig get rules;
  TeamingConfig get teaming;
  PlayersConfig? get players;

  GameConfig._();
  factory GameConfig([void Function(GameConfigBuilder) updates]) = _$GameConfig;
  static Serializer<GameConfig> get serializer => _$gameConfigSerializer;
}
