class GameSettings {
  int explanationSeconds;

  GameSettings.defaults() : explanationSeconds = 15;

  // TODO: delete
  GameSettings.dev() : explanationSeconds = 5;
}
