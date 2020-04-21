class RulesConfig {
  int explanationSeconds;

  RulesConfig.defaults() : explanationSeconds = 15;

  RulesConfig.dev() : explanationSeconds = 5;
}

class TeamingConfig {
}

class PlayersConfig {
  List<List<String>> teamPlayers;
}

class GameConfig {
  RulesConfig rules;
  var teaming = TeamingConfig();
  var players = PlayersConfig();

  GameConfig.defaults() : rules = RulesConfig.defaults();

  // TODO: delete
  GameConfig.dev() : rules = RulesConfig.dev();
}
