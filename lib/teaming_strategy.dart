class Team {
  int performer;
  List<int> recipients;

  Team(this.performer, this.recipients);
}

abstract class TeamingStrategy {
  final int numPlayers;

  TeamingStrategy(this.numPlayers);

  bool teamsAreFixed();
  Team getTeam(int turn);
}

class TeamsOfTwoStrategy extends TeamingStrategy {
  TeamsOfTwoStrategy(int numPlayers) : super(numPlayers) {
    assert(numPlayers % 2 == 0);
  }

  @override
  bool teamsAreFixed() => true;

  @override
  Team getTeam(int turn) {
    final performer = turn % numPlayers;
    final recipient = (performer + numPlayers ~/ 2) % numPlayers;
    return Team(performer, [recipient]);
  }
}
