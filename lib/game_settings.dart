class GameSettings {
  List<List<String>> teamPlayers;
  int explanationSeconds;

  GameSettings.defaults() : explanationSeconds = 15;

  // TODO: delete
  GameSettings.dev() : explanationSeconds = 5;
}
