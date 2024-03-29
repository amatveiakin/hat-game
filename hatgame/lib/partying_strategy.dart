import 'package:built_collection/built_collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/team_compositions.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';

// =============================================================================
// Team Generators

List<List<int>> generateTeamPlayers(
    {required List<int> playerIDs, required List<int> teamSizes}) {
  final List<List<int>> teams = [];
  int playerIdx = 0;
  for (final s in teamSizes) {
    teams.add([]);
    final List<int> playersInTeam = teams.last;
    for (int i = 0; i < s; i++) {
      playersInTeam.add(playerIDs[playerIdx]);
      playerIdx++;
    }
  }
  return teams;
}

void checkTeamSizes(BuiltList<BuiltList<int>> teams) {
  for (final t in teams) {
    if (t.isEmpty) {
      // TODO: Disallow when the UI allows to delete teams.
    } else if (t.length == 1) {
      throw InvalidOperation(tr('team_has_only_one_player'));
    }
  }
  if (teams.isEmpty) {
    throw InvalidOperation(tr('there_are_zero_teams'));
  } else if (teams.length == 1) {
    throw InvalidOperation(tr('there_is_only_one_team'));
  }
}

List<int> generateTeamSizes(
  int numPlayers,
  DesiredTeamSize desiredTeamSize,
  UnequalTeamSize unequalTeamSize,
) {
  late final int teamSize;
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

  switch (unequalTeamSize) {
    case UnequalTeamSize.expandTeams:
      break;
    case UnequalTeamSize.forbid:
    case UnequalTeamSize.dropPlayers:
      if (numPlayers % teamSize != 0) {
        // TODO: Discard some players on dropPlayers when we have a UI for it.
        throw InvalidOperation(
          tr('cannot_make_teams'),
          // TODO: tr
          comment: 'Players cannot be split into teams of desired size, ' +
              (unequalTeamSize == UnequalTeamSize.forbid
                  ? 'and unequally sized teams are disabled.'
                  : 'and support for dropping players isn\'t ready yet.'),
        );
      }
      break;
  }

  int extraPlayers = numPlayers % teamSize;
  return List<int>.generate(numPlayers ~/ teamSize,
      (index) => teamSize + (index < extraPlayers ? 1 : 0));
}

void checkNumPlayersForIndividualPlay(
    int numPlayers, IndividualPlayStyle playStyle) {
  switch (playStyle) {
    case IndividualPlayStyle.chain:
    case IndividualPlayStyle.fluidPairs:
      if (numPlayers < 2) {
        throw InvalidOperation(tr('at_least_two_players_required'));
      }
      return;
    case IndividualPlayStyle.broadcast:
      if (numPlayers < 1) {
        throw InvalidOperation(tr('at_least_one_player_required'));
      }
      return;
  }
  Assert.fail('Unknown IndividualPlayStyle: $playStyle');
}

// =============================================================================
// PartyingStrategy interface

abstract class PartyingStrategy {
  Party getParty(int turn);

  PartyingStrategy();

  factory PartyingStrategy.fromGame(
      GameConfig config, TeamCompositions teamCompositions) {
    if (teamCompositions.teams != null) {
      return FixedTeamsStrategy(
          teamCompositions.teams!, config.teaming.guessingInLargeTeam);
    } else {
      return IndividualStrategy(teamCompositions.individualOrder!,
          config.teaming.individualPlayStyle);
    }
  }
}

// =============================================================================
// IndividualStrategy

class IndividualStrategy extends PartyingStrategy {
  final BuiltList<int> players;
  final IndividualStrategyImpl _impl;

  IndividualStrategy(this.players, IndividualPlayStyle playStyle)
      : _impl = IndividualStrategyImpl(players.length, playStyle);

  @override
  Party getParty(int turn) {
    final Party p = _impl.getPartyImpl(turn);
    return Party((b) => b
      ..performer = players[p.performer]
      ..recipients.addAll(p.recipients.map((idx) => players[idx])));
  }
}

abstract class IndividualStrategyImpl {
  final int numPlayers;

  IndividualStrategyImpl.internal(this.numPlayers);

  factory IndividualStrategyImpl(
      int numPlayers, IndividualPlayStyle playStyle) {
    switch (playStyle) {
      case IndividualPlayStyle.chain:
        return ChainIndividualStrategy(numPlayers);
      case IndividualPlayStyle.fluidPairs:
        return FluidPairsIndividualStrategy(numPlayers);
      case IndividualPlayStyle.broadcast:
        return BroadcastIndividualStrategy(numPlayers);
    }
    Assert.fail('Unknown IndividualPlayStyle:$playStyle');
  }

  Party getPartyImpl(int turn);
}

class ChainIndividualStrategy extends IndividualStrategyImpl {
  ChainIndividualStrategy(super.numPlayers) : super.internal();

  @override
  Party getPartyImpl(int turn) {
    final int performer = turn % numPlayers;
    final int recipient = (performer + 1) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class FluidPairsIndividualStrategy extends IndividualStrategyImpl {
  FluidPairsIndividualStrategy(super.numPlayers) : super.internal();

  @override
  Party getPartyImpl(int turn) {
    final int localIdx = turn % numPlayers;
    final int shift = turn ~/ numPlayers % (numPlayers - 1) + 1;
    // Any function of `shift` and `numPlayers` is a valid seed, although
    // only seed non-trivially depending on `shift` is meaningful.
    // To estimate which seed gives best results, check out the metrics
    // in partying_strategy_test.dart.
    final int seed = numPlayers == 3 ? (shift - 1) : 0;
    final int performer = (localIdx + seed) % numPlayers;
    final int recipient = (performer + shift) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class BroadcastIndividualStrategy extends IndividualStrategyImpl {
  BroadcastIndividualStrategy(super.numPlayers) : super.internal();

  @override
  Party getPartyImpl(int turn) {
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
  final BuiltList<BuiltList<int>> teamPlayers;
  final IndividualPlayStyle individualPlayStyle;

  FixedTeamsStrategy(this.teamPlayers, this.individualPlayStyle);

  @override
  Party getParty(int turn) {
    final int teamIdx = turn % teamPlayers.length;
    final team = teamPlayers[teamIdx];
    final int subturn = turn ~/ teamPlayers.length;
    final singleTeamStrategy = IndividualStrategy(team, individualPlayStyle);
    return singleTeamStrategy.getParty(subturn);
  }
}
