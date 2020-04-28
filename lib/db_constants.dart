class DBColumns {
  static const String creationTimeUtc = 'creation_time_utc';
  static const String hostAppVersion = 'host_app_version';
  static const String config = 'config';
  static const String state = 'state';
  static String player(int playerID) => 'player-$playerID';
}
