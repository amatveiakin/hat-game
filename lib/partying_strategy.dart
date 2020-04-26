import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/assertion.dart';

// =============================================================================
// Team Generators

List<List<int>> generateTeamPlayers(List<int> teamSizes) {
  final List<List<int>> players = [];
  int playerIdx = 0;
  for (final s in teamSizes) {
    if (s == 0) {
      // TODO: Disallow when the UI allows to delete teams.
      continue;
    } else if (s == 1) {
      throw CannotMakePartyingStrategy('A team has only one player');
    }
    Assert.holds(s > 1);
    players.add([]);
    final List<int> playersInTeam = players.last;
    for (int i = 0; i < s; i++) {
      playersInTeam.add(playerIdx);
      playerIdx++;
    }
  }
  if (players.length == 0) {
    throw CannotMakePartyingStrategy('There are zero teams');
  } else if (players.length == 1) {
    throw CannotMakePartyingStrategy('There is only one team');
  }
  return players;
}

List<int> generateTeamSizes(
  int numPlayers,
  DesiredTeamSize desiredTeamSize,
  UnequalTeamSize unequalTeamSize,
) {
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
    case UnequalTeamSize.forbid:
    case UnequalTeamSize.dropPlayers:
      if (numPlayers % teamSize != 0) {
        // TODO: Discard some players on dropPlayers when we have a UI for it.
        throw CannotMakePartyingStrategy(
            'Players cannot be split into teams of desired size, ' +
                (unequalTeamSize == UnequalTeamSize.forbid
                    ? 'and unequally sized teams are disabled.'
                    : 'and support for dropping players isn\'t ready yet.'));
      }
      break;
  }

  int extraPlayers = numPlayers % teamSize;
  return List<int>.generate(numPlayers ~/ teamSize,
      (index) => teamSize + (index < extraPlayers ? 1 : 0));
}

// =============================================================================
// PartyingStrategy interface

abstract class PartyingStrategy {
  Party getParty(int turn);

  PartyingStrategy();

  factory PartyingStrategy.fromGame(GameData gameData) {
    if (gameData.state.teams != null) {
      return FixedTeamsStrategy(
          gameData.teams(), gameData.config.teaming.guessingInLargeTeam);
    } else {
      return IndividualStrategy(gameData.state.players.length,
          gameData.config.teaming.individualPlayStyle);
    }
  }
}

class CannotMakePartyingStrategy implements Exception {
  String message;
  CannotMakePartyingStrategy(this.message);
}

// =============================================================================
// IndividualStrategy

abstract class IndividualStrategy extends PartyingStrategy {
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
}

class ChainIndividualStrategy extends IndividualStrategy {
  ChainIndividualStrategy(int numPlayers) : super._internal(numPlayers);

  @override
  Party getParty(int turn) {
    final int performer = turn % numPlayers;
    final int recipient = (performer + 1) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class FluidPairsIndividualStrategy extends IndividualStrategy {
  FluidPairsIndividualStrategy(int numPlayers) : super._internal(numPlayers);

  @override
  Party getParty(int turn) {
    final int performer = turn % numPlayers;
    final int shift = turn ~/ numPlayers % (numPlayers - 1) + 1;
    final int recipient = (performer + shift) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class BroadcastIndividualStrategy extends IndividualStrategy {
  BroadcastIndividualStrategy(int numPlayers) : super._internal(numPlayers);

  @override
  Party getParty(int turn) {
    final int performer = turn % numPlayers;
    final recipients = Iterable<int>.generate(numPlayers)
        .where((p) => p != performer)
        .toList();
    return Party((b) => b
      ..performer = performer
      ..recipients.addAll(recipients));
  }
}

// =============================================================================
// FixedTeamsStrategy

class FixedTeamsStrategy extends PartyingStrategy {
  final List<List<int>> teamPlayers;
  final IndividualPlayStyle individualPlayStyle;

  FixedTeamsStrategy(this.teamPlayers, this.individualPlayStyle);

  @override
  Party getParty(int turn) {
    final int teamIdx = turn % teamPlayers.length;
    final team = teamPlayers[teamIdx];
    final int subturn = turn ~/ teamPlayers.length;
    final singleTeamStrategy =
        IndividualStrategy(team.length, individualPlayStyle);
    final subparty = singleTeamStrategy.getParty(subturn);
    return Party((b) => b
      ..performer = team[subparty.performer]
      ..recipients.addAll(subparty.recipients.map((idx) => team[idx])));
  }
}
