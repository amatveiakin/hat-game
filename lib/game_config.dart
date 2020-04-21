class GameConfig {
  List<List<String>> teamPlayers;
  int explanationSeconds;

  GameConfig.defaults() : explanationSeconds = 15;

  // TODO: delete
  GameConfig.dev() : explanationSeconds = 5;
}
