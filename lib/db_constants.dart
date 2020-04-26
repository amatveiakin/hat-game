class DBColumns {
  static const String config = 'config';
  static const String state = 'state';
  static String player(int playerID) => 'player-$playerID';
}
