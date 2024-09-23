import 'package:built_collection/built_collection.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/team_compositions.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/util/local_str.dart';
import 'package:quiver/iterables.dart' as quiver;

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
  if (teams.isEmpty) {
    throw InvalidOperation(LocalStr.tr('there_are_zero_teams'));
  } else if (teams.length == 1) {
    throw InvalidOperation(LocalStr.tr('there_is_only_one_team'));
  }
  for (final t in teams) {
    if (t.isEmpty) {
      throw InvalidOperation(LocalStr.tr('team_is_empty'));
    } else if (t.length == 1) {
      throw InvalidOperation(LocalStr.tr('team_has_only_one_player'));
    }
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
          LocalStr.tr('cannot_make_teams'),
          comment: LocalStr.raw(
              'Odd number of players cannot be divided into pairs.'),
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
        throw InvalidOperation(LocalStr.tr('at_least_two_players_required'));
      }
      return;
    case TeamingStyle.oneToAll:
      if (numPlayers < 1) {
        throw InvalidOperation(LocalStr.tr('at_least_one_player_required'));
      }
      return;
  }
  Assert.unexpectedValue(teaming.teamingStyle);
}

// =============================================================================
// PartyingStrategy interface

class RoundsProgress {
  final int roundIndex;
  final int roundTurnIndex;
  final int numTurnsPerRound;

  RoundsProgress(this.roundIndex, this.roundTurnIndex, this.numTurnsPerRound);
}

abstract class PartyingStrategy {
  Party getParty(int turn);

  int get numTurnsPerRound;
  RoundsProgress getRoundsProgress(int turn) {
    final turnsPerRound = numTurnsPerRound;
    final roundIndex = turn ~/ turnsPerRound;
    final roundTurnIndex = turn % turnsPerRound;
    return RoundsProgress(roundIndex, roundTurnIndex, turnsPerRound);
  }

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

  @override
  int get numTurnsPerRound => _impl.numTurnsPerRoundImpl;
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
  int get numTurnsPerRoundImpl;
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

  @override
  int get numTurnsPerRoundImpl => numPlayers * (numPlayers - 1);
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

  @override
  int get numTurnsPerRoundImpl => numPlayers;
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

  // In each round each player must explain at least one. Therefore we cannot
  // simply divide the turn index by the total number of players. For example,
  // imagine we have teams {A, B} and {C, D, E}. Then the first 5 turns might
  // be: A, C, B, D, A. Here player E hasn't explained yet.
  @override
  int get numTurnsPerRound {
    final maxTeamSize =
        quiver.max(teamPlayers.map((players) => players.length))!;
    return teamPlayers.length * maxTeamSize;
  }
}
