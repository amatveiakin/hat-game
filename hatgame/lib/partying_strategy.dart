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
  TeamingConfig teaming,
) {
  switch (teaming.teamingStyle) {
    case TeamingStyle.randomPairs:
      if (numPlayers % 2 != 0) {
        // TODO: Discard some players on dropPlayers when we have a UI for it.
        throw InvalidOperation(
          tr('cannot_make_teams'),
          comment: 'Odd number of players cannot be divided into pairs.',
        );
      }
      return List.filled(numPlayers ~/ 2, 2);
    case TeamingStyle.randomTeams:
      int numTeams = teaming.numTeams;
      int baseTeamSize = numPlayers ~/ numTeams;
      int extraPlayers = numPlayers % numTeams;
      return List<int>.generate(
          numTeams, (i) => baseTeamSize + (i < extraPlayers ? 1 : 0));
  }
  Assert.unexpectedValue(teaming.teamingStyle);
}

void checkNumPlayersForIndividualPlay(int numPlayers, TeamingConfig teaming) {
  switch (teaming.teamingStyle) {
    case TeamingStyle.individual:
      if (numPlayers < 2) {
        throw InvalidOperation(tr('at_least_two_players_required'));
      }
      return;
    case TeamingStyle.oneToAll:
      if (numPlayers < 1) {
        throw InvalidOperation(tr('at_least_one_player_required'));
      }
      return;
  }
  Assert.unexpectedValue(teaming.teamingStyle);
}

// =============================================================================
// PartyingStrategy interface

abstract class PartyingStrategy {
  Party getParty(int turn);

  PartyingStrategy();

  factory PartyingStrategy.fromGame(
      GameConfig config, TeamCompositions teamCompositions) {
    switch (config.teaming.teamingStyle) {
      case TeamingStyle.individual:
        return IndividualStrategy(teamCompositions.individualOrder!, false);
      case TeamingStyle.oneToAll:
        return IndividualStrategy(teamCompositions.individualOrder!, true);
      case TeamingStyle.randomPairs:
      case TeamingStyle.randomTeams:
      case TeamingStyle.manualTeams:
        return FixedTeamsStrategy(teamCompositions.teams!);
    }
    Assert.unexpectedValue(config.teaming.teamingStyle);
  }
}

// =============================================================================
// IndividualStrategy

class IndividualStrategy extends PartyingStrategy {
  final BuiltList<int> players;
  final IndividualStrategyImpl _impl;

  IndividualStrategy(this.players, bool broadcast)
      : _impl = IndividualStrategyImpl(players.length, broadcast);

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

  factory IndividualStrategyImpl(int numPlayers, bool broadcast) {
    return broadcast
        ? BroadcastIndividualStrategy(numPlayers)
        : FluidPairsIndividualStrategy(numPlayers);
  }

  Party getPartyImpl(int turn);
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

  FixedTeamsStrategy(this.teamPlayers);

  @override
  Party getParty(int turn) {
    final int teamIdx = turn % teamPlayers.length;
    final team = teamPlayers[teamIdx];
    final int subturn = turn ~/ teamPlayers.length;
    final singleTeamStrategy = IndividualStrategy(team, true);
    return singleTeamStrategy.getParty(subturn);
  }
}
