import 'package:hatgame/assertion.dart';
import 'package:hatgame/game_config.dart';

class Team {
  int performer;
  List<int> recipients;

  Team(this.performer, this.recipients);
}

abstract class TeamingStrategy {
  bool teamsAreFixed();
  Team getTeam(int turn);
}

class CannotMakeTeaming implements Exception {
  String message;
  CannotMakeTeaming(this.message);
}

// =============================================================================
// IndividualStrategy

abstract class IndividualStrategy extends TeamingStrategy {
  final int numPlayers;

  IndividualStrategy._internal(this.numPlayers);

  factory IndividualStrategy(int numPlayers, IndividualPlayStyle playStyle) {
    switch (playStyle) {
      case IndividualPlayStyle.chain:
        return ChainIndividualStrategy(numPlayers);
      case IndividualPlayStyle.fluidPairs:
        return FluidPairsIndividualStrategy(numPlayers);
      case IndividualPlayStyle.broadcast:
        return BroadcastIndividualStrategy(numPlayers);
    }
    Assert.fail('Unknown IndividualPlayStyle:' + playStyle.toString());
  }

  @override
  bool teamsAreFixed() => false;
}

class ChainIndividualStrategy extends IndividualStrategy {
  ChainIndividualStrategy(int numPlayers) : super._internal(numPlayers);

  @override
  Team getTeam(int turn) {
    final int performer = turn % numPlayers;
    final int guesser = (performer + 1) % numPlayers;
    return Team(performer, [guesser]);
  }
}

class FluidPairsIndividualStrategy extends IndividualStrategy {
  FluidPairsIndividualStrategy(int numPlayers) : super._internal(numPlayers);

  @override
  Team getTeam(int turn) {
    final int performer = turn % numPlayers;
    final int shift = turn ~/ numPlayers % (numPlayers - 1) + 1;
    final int guesser = (performer + shift) % numPlayers;
    return Team(performer, [guesser]);
  }
}

class BroadcastIndividualStrategy extends IndividualStrategy {
  BroadcastIndividualStrategy(int numPlayers) : super._internal(numPlayers);

  @override
  Team getTeam(int turn) {
    final int performer = turn % numPlayers;
    final guessers = Iterable<int>.generate(numPlayers)
        .where((p) => p != performer)
        .toList();
    return Team(performer, guessers);
  }
}

// =============================================================================
// FixedTeamsStrategy

class FixedTeamsStrategy extends TeamingStrategy {
  final List<List<int>> teamPlayers;
  final IndividualPlayStyle individualPlayStyle;

  FixedTeamsStrategy.manualTeams(List<int> teamSizes, this.individualPlayStyle)
      : teamPlayers = _generateTeamPlayers(teamSizes);

  FixedTeamsStrategy.generateTeams(
      int numPlayers,
      DesiredTeamSize desiredTeamSize,
      UnequalTeamSize unequalTeamSize,
      this.individualPlayStyle)
      : teamPlayers = _generateTeamPlayers(
            _generateTeamSizes(numPlayers, desiredTeamSize, unequalTeamSize));

  @override
  bool teamsAreFixed() => true;

  @override
  Team getTeam(int turn) {
    final int teamIdx = turn % teamPlayers.length;
    final team = teamPlayers[teamIdx];
    final int subturn = turn ~/ teamPlayers.length;
    final singleTeamStrategy =
        IndividualStrategy(team.length, individualPlayStyle);
    final indices = singleTeamStrategy.getTeam(subturn);
    return Team(team[indices.performer],
        indices.recipients.map((idx) => team[idx]).toList());
  }

  static List<List<int>> _generateTeamPlayers(List<int> teamSizes) {
    if (teamSizes.length == 0) {
      throw CannotMakeTeaming('There are zero teams');
    } else if (teamSizes.length == 1) {
      throw CannotMakeTeaming('There is only one team');
    }
    final List<List<int>> players = [];
    int playerIdx = 0;
    for (final s in teamSizes) {
      if (s == 0) {
        throw CannotMakeTeaming('A team has no players');
      } else if (s == 1) {
        throw CannotMakeTeaming('A team has only one player');
      }
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

  static List<int> _generateTeamSizes(int numPlayers,
      DesiredTeamSize desiredTeamSize, UnequalTeamSize unequalTeamSize) {
    int teamSize;
    switch (desiredTeamSize) {
      case DesiredTeamSize.teamsOf2:
        teamSize = 2;
        break;
      case DesiredTeamSize.teamsOf3:
        teamSize = 3;
        break;
      case DesiredTeamSize.teamsOf4:
        teamSize = 4;
        break;
      case DesiredTeamSize.twoTeams:
        teamSize = numPlayers ~/ 2;
        break;
    }
    Assert.holds(teamSize != null);

    switch (unequalTeamSize) {
      case UnequalTeamSize.expandTeams:
        break;
      case UnequalTeamSize.dropPlayers:
        if (numPlayers % teamSize != 0) {
          // TODO: Discard some player instead when we have a UI for it.
          throw CannotMakeTeaming(
              'Players cannot be split into teams of desired size, '
              'and unequally sized teams are diabled.');
        }
        break;
    }

    int extraPlayers = numPlayers % teamSize;
    return List<int>.generate(numPlayers ~/ teamSize,
        (index) => teamSize + (index < extraPlayers ? 1 : 0));
  }
}
