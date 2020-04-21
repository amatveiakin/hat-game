import 'package:hatgame/assertion.dart';

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

abstract class FixedTeamsStrategy extends TeamingStrategy {
  final List<List<int>> teamPlayers;

  FixedTeamsStrategy(List<int> teamSizes)
      : teamPlayers = _generateTeamPlayers(teamSizes),
        super(teamSizes.fold(0, (a, b) => a + b));

  // TODO: Do we need this?
  static teamsOfTwo(int numPlayers) {
    return FixedTeamsEverybodyRecipientStrategy(
        _generateTeamsOfTwo(numPlayers));
  }

  @override
  bool teamsAreFixed() => true;

  static List<List<int>> _generateTeamPlayers(List<int> teamSizes) {
    final List<List<int>> players = [];
    int playerIdx = 0;
    for (final s in teamSizes) {
      Assert.holds(s > 1);
      players.add([]);
      final List<int> playersInTeam = players.last;
      for (int i = 0; i < s; i++) {
        playersInTeam.add(playerIdx);
        playerIdx++;
      }
    }
    return players;
  }

  static List<int> _generateTeamsOfTwo(int numPlayers) {
    Assert.holds(numPlayers % 2 == 0);
    return List<int>.generate(numPlayers ~/ 2, (index) => 2);
  }
}

class FixedTeamsEverybodyRecipientStrategy extends FixedTeamsStrategy {
  FixedTeamsEverybodyRecipientStrategy(List<int> teamSizes) : super(teamSizes);

  @override
  Team getTeam(int turn) {
    final int teamIdx = turn % teamPlayers.length;
    final team = teamPlayers[teamIdx];
    final int performerIdx = (turn ~/ teamPlayers.length) % team.length;
    final int performer = team[performerIdx];
    return Team(performer, team.where((p) => p != performer).toList());
  }
}
