import 'dart:async';

import 'package:hatgame/built_value/game_config.dart';

class GameConfigController {
  // Don't get the config from here - get it from the stream!
  GameConfig _config;
  final _streamController = StreamController<GameConfig>(sync: true);

  Stream<GameConfig> get stateUpdatesStream => _streamController.stream;

  static GameConfig _defaultConfig() {
    return GameConfig(
      (b) => b
        ..rules.turnSeconds = 15
        ..rules.bonusSeconds = 5
        ..rules.wordsPerPlayer = 5
        ..teaming.teamPlay = true
        ..teaming.randomizeTeams = true
        ..teaming.individualPlayStyle = IndividualPlayStyle.fluidPairs
        ..teaming.desiredTeamSize = DesiredTeamSize.teamsOf2
        ..teaming.unequalTeamSize = UnequalTeamSize.forbid
        ..teaming.guessingInLargeTeam = IndividualPlayStyle.fluidPairs,
    );
  }

  GameConfigController.defaultConfig() {
    update(_defaultConfig());
  }
  GameConfigController.devConfig() {
    update(_defaultConfig().rebuild(
      (b) => b
        ..rules.turnSeconds = 5
        ..rules.bonusSeconds = 3
        ..rules.wordsPerPlayer = 1
        ..players.names.replace(['Vasya', 'Petya', 'Masha', 'Dasha']),
    ));
  }

  void update(GameConfig newConfig) {
    _config = newConfig;
    _streamController.sink.add(newConfig);
  }

  void updateRules(RulesConfig newRules) {
    update(_config.rebuild(
      (b) => b..rules.replace(newRules),
    ));
  }

  void updateTeaming(TeamingConfig newTeaming) {
    update(_config.rebuild(
      (b) => b..teaming.replace(newTeaming),
    ));
  }

  void updatePlayers(PlayersConfig newPlayers) {
    update(_config.rebuild(
      (b) => b..players.replace(newPlayers),
    ));
  }
}
