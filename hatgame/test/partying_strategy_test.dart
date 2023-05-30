// ignore_for_file: camel_case_types

import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:test/test.dart';

// TODO: Test all strategies.

class FluidPairsIndividualStrategy_Variant0 extends IndividualStrategyImpl {
  FluidPairsIndividualStrategy_Variant0(int numPlayers)
      : super.internal(numPlayers);

  @override
  Party getPartyImpl(int turn) {
    final int performer = turn % numPlayers;
    final int shift = turn ~/ numPlayers % (numPlayers - 1) + 1;
    final int recipient = (performer + shift) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class FluidPairsIndividualStrategy_Variant1 extends IndividualStrategyImpl {
  FluidPairsIndividualStrategy_Variant1(int numPlayers)
      : super.internal(numPlayers);

  @override
  Party getPartyImpl(int turn) {
    final int localIdx = turn % numPlayers;
    final int shift = turn ~/ numPlayers % (numPlayers - 1) + 1;
    final int seed = shift;
    final int performer = (localIdx + seed) % numPlayers;
    final int recipient = (performer + shift) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class FluidPairsIndividualStrategy_Variant2 extends IndividualStrategyImpl {
  FluidPairsIndividualStrategy_Variant2(int numPlayers)
      : super.internal(numPlayers);

  @override
  Party getPartyImpl(int turn) {
    final int localIdx = turn % numPlayers;
    final int shift = turn ~/ numPlayers % (numPlayers - 1) + 1;
    final int seed = shift % 2;
    final int performer = (localIdx + seed) % numPlayers;
    final int recipient = (performer + shift) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class FluidPairsIndividualStrategy_Variant3 extends IndividualStrategyImpl {
  FluidPairsIndividualStrategy_Variant3(int numPlayers)
      : super.internal(numPlayers);

  @override
  Party getPartyImpl(int turn) {
    final int shift = turn ~/ numPlayers % (numPlayers - 1) + 1;
    final int localIdx = turn % numPlayers;
    final int numSubcircles = numPlayers.gcd(shift);
    final int subsircleIdx = localIdx % numSubcircles;
    final int idxInSubsircle = localIdx ~/ numSubcircles;
    final int performer = (subsircleIdx + idxInSubsircle * shift) % numPlayers;
    final int recipient =
        (subsircleIdx + (idxInSubsircle + 1) * shift) % numPlayers;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

class FluidPairsIndividualStrategy_Variant4 extends IndividualStrategyImpl {
  FluidPairsIndividualStrategy_Variant4(int numPlayers)
      : super.internal(numPlayers);

  @override
  Party getPartyImpl(int turn) {
    final int halfRoundLength = numPlayers * (numPlayers - 1) ~/ 2;
    final int halfRoundIdx = turn ~/ halfRoundLength;
    final int idsInHalfRound = turn % halfRoundLength;
    final int shift = idsInHalfRound ~/ numPlayers % (numPlayers - 1) + 1;
    final int localIdx = idsInHalfRound % numPlayers;
    final int numSubcircles = numPlayers.gcd(shift);
    final int subsircleIdx = localIdx % numSubcircles;
    final int idxInSubsircle = localIdx ~/ numSubcircles;
    final int roleA = (subsircleIdx + idxInSubsircle * shift) % numPlayers;
    final int roleB =
        (subsircleIdx + (idxInSubsircle + 1) * shift) % numPlayers;
    final bool evenHalfRound = halfRoundIdx % 2 == 0;
    final int performer = evenHalfRound ? roleA : roleB;
    final int recipient = evenHalfRound ? roleB : roleA;
    return Party((b) => b
      ..performer = performer
      ..recipients.add(recipient));
  }
}

BuiltList<BuiltList<int>> toBuiltList(List<List<int>> list) {
  return BuiltList<BuiltList<int>>.from(list.map((t) => BuiltList<int>(t)));
}

class StrategyQuality {
  // Max time one player has to wait between two turns.
  //Less is better.
  final int maxIdleTime;

  // Max times being in the same role (when your turn comes) in a row.
  //Less is better.
  final int maxRoleStreak;

  StrategyQuality(this.maxIdleTime, this.maxRoleStreak);

  @override
  String toString() {
    return '($maxIdleTime, $maxRoleStreak)';
  }
}

partyEquals(int performer, List<int> recipients) => const TypeMatcher<Party>()
    .having((t) => t.performer, 'performer', equals(performer))
    .having((t) => t.recipients, 'recipients', equals(recipients));

qualEq(int maxIdleTime, int maxRoleStreak) =>
    const TypeMatcher<StrategyQuality>()
        .having((t) => t.maxIdleTime, 'maxIdleTime', equals(maxIdleTime))
        .having((t) => t.maxRoleStreak, 'maxRoleStreak', equals(maxRoleStreak));

StrategyQuality qual(IndividualStrategyImpl strategy) {
  final int numPlayers = strategy.numPlayers;
  final int fullRound = numPlayers * (numPlayers - 1);
  final int totalTurns = fullRound * 2;
  final waitTime = List<int>.filled(numPlayers, 0);
  final performingStreak = List<int>.filled(numPlayers, 0);
  final guessingStreak = List<int>.filled(numPlayers, 0);
  int maxWaitTime = 0;
  int maxPerformingStreak = 0;
  int maxGuessingStreak = 0;

  for (int turn = 0; turn < totalTurns; turn++) {
    for (int p = 0; p < numPlayers; p++) {
      maxWaitTime = max(maxWaitTime, waitTime[p]++);
      maxPerformingStreak = max(maxPerformingStreak, performingStreak[p]);
      maxGuessingStreak = max(maxGuessingStreak, guessingStreak[p]);
    }

    final party = strategy.getPartyImpl(turn);
    expect(party.recipients.length, equals(1));
    final int performer = party.performer;
    final int recipient = party.recipients.first;

    waitTime[performer] = 0;
    waitTime[recipient] = 0;
    performingStreak[performer]++;
    performingStreak[recipient] = 0;
    guessingStreak[performer] = 0;
    guessingStreak[recipient]++;
  }
  return StrategyQuality(
      maxWaitTime, max(maxPerformingStreak, maxGuessingStreak));
}

void checkCorrectness(IndividualStrategyImpl strategy) {
  final int numPlayers = strategy.numPlayers;
  final int fullRound = numPlayers * (numPlayers - 1);
  final int totalPairs = fullRound ~/ 2;
  final orderedPairs = <(int, int)>{};
  final unorderedPairs = <(int, int)>{};

  for (int turn = 0; turn < fullRound; turn++) {
    final party = strategy.getPartyImpl(turn);
    expect(party.recipients.length, equals(1));
    final int performer = party.performer;
    final int recipient = party.recipients.first;
    expect(performer, inClosedOpenRange(0, numPlayers));
    expect(recipient, inClosedOpenRange(0, numPlayers));

    final ordered = (performer, recipient);
    expect(orderedPairs, isNot(contains(ordered)));
    orderedPairs.add(ordered);

    final int playerA = min(performer, recipient);
    final int playerB = max(performer, recipient);
    final unordered = (playerA, playerB);
    if (turn < totalPairs) {
      expect(unorderedPairs, isNot(contains(unordered)));
      unorderedPairs.add(unordered);
    }
  }
}

void main() {
  group('generate team sizes', () {
    test('4 players in teams of 2', () {
      expect(
          generateTeamSizes(
              4, DesiredTeamSize.teamsOf2, UnequalTeamSize.expandTeams),
          equals([2, 2]));
    });

    test('5 players in teams of 2', () {
      expect(
          generateTeamSizes(
              5, DesiredTeamSize.teamsOf2, UnequalTeamSize.expandTeams),
          equals([3, 2]));
    });

    test('6 players in teams of 2', () {
      expect(
          generateTeamSizes(
              6, DesiredTeamSize.teamsOf2, UnequalTeamSize.expandTeams),
          equals([2, 2, 2]));
    });

    test('6 players in teams of 3', () {
      expect(
          generateTeamSizes(
              6, DesiredTeamSize.teamsOf3, UnequalTeamSize.expandTeams),
          equals([3, 3]));
    });

    test('10 players in teams of 4', () {
      expect(
          generateTeamSizes(
              10, DesiredTeamSize.teamsOf4, UnequalTeamSize.expandTeams),
          equals([5, 5]));
    });

    test('27 players, two teams', () {
      expect(
          generateTeamSizes(
              27, DesiredTeamSize.twoTeams, UnequalTeamSize.expandTeams),
          equals([14, 13]));
    });

    test('odd number of players forbidden', () {
      expect(
        () {
          generateTeamSizes(
              5, DesiredTeamSize.teamsOf2, UnequalTeamSize.forbid);
        },
        flutter_test.throwsA(isA<InvalidOperation>()),
      );
    });
  });

  group('generate team players', () {
    test('2 + 2', () {
      expect(
          generateTeamPlayers(playerIDs: [0, 1, 2, 3], teamSizes: [2, 2]),
          equals([
            [0, 1],
            [2, 3],
          ]));
    });

    test('2 + 3', () {
      expect(
          generateTeamPlayers(playerIDs: [0, 1, 2, 3, 4], teamSizes: [3, 2]),
          equals([
            [0, 1, 2],
            [3, 4],
          ]));
    });

    test('custom IDs', () {
      expect(
          generateTeamPlayers(playerIDs: [17, 0, 42, 100], teamSizes: [2, 2]),
          equals([
            [17, 0],
            [42, 100],
          ]));
    });
  });

  group('fixed teams strategy', () {
    test('2 + 2', () {
      final strategy = FixedTeamsStrategy(
          toBuiltList([
            [0, 1],
            [2, 3],
          ]),
          IndividualPlayStyle.fluidPairs);
      expect(strategy.getParty(0), partyEquals(0, [1]));
      expect(strategy.getParty(1), partyEquals(2, [3]));
      expect(strategy.getParty(2), partyEquals(1, [0]));
      expect(strategy.getParty(3), partyEquals(3, [2]));
      expect(strategy.getParty(4), partyEquals(0, [1]));
    });

    test('2 + 3', () {
      final strategy = FixedTeamsStrategy(
          toBuiltList([
            [0, 1, 2],
            [3, 4],
          ]),
          IndividualPlayStyle.fluidPairs);
      expect(strategy.getParty(0), partyEquals(0, [1]));
      expect(strategy.getParty(1), partyEquals(3, [4]));
      expect(strategy.getParty(2), partyEquals(1, [2]));
      expect(strategy.getParty(3), partyEquals(4, [3]));
      expect(strategy.getParty(4), partyEquals(2, [0]));
      expect(strategy.getParty(5), partyEquals(3, [4]));
      // ---------------------------------------------
      expect(strategy.getParty(6), partyEquals(1, [0]));
      expect(strategy.getParty(7), partyEquals(4, [3]));
      expect(strategy.getParty(8), partyEquals(2, [1]));
      expect(strategy.getParty(9), partyEquals(3, [4]));
      expect(strategy.getParty(10), partyEquals(0, [2]));
      expect(strategy.getParty(11), partyEquals(4, [3]));
      // ---------------------------------------------
      expect(strategy.getParty(12), partyEquals(0, [1]));
    });
  });

  group('fuild pair individual strategy', () {
    test('correctness', () {
      // Correctness is defined as: in one full cycle each pair plays
      // exactly once.
      for (int numPlayers = 2; numPlayers <= 10; numPlayers++) {
        checkCorrectness(FluidPairsIndividualStrategy_Variant0(numPlayers));
      }
      for (int numPlayers = 2; numPlayers <= 10; numPlayers++) {
        checkCorrectness(FluidPairsIndividualStrategy_Variant1(numPlayers));
      }
      for (int numPlayers = 2; numPlayers <= 10; numPlayers++) {
        checkCorrectness(FluidPairsIndividualStrategy_Variant2(numPlayers));
      }
      for (int numPlayers = 2; numPlayers <= 10; numPlayers++) {
        checkCorrectness(FluidPairsIndividualStrategy_Variant3(numPlayers));
      }
      for (int numPlayers = 2; numPlayers <= 10; numPlayers++) {
        checkCorrectness(FluidPairsIndividualStrategy(numPlayers));
      }
    });

    test('qual', () {
      // Strategy qual is defined by how evenly it spreads players.
      // Here we check a few simple qual markers.

      expect(qual(FluidPairsIndividualStrategy_Variant0(2)), qualEq(0, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant0(3)), qualEq(2, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant0(4)), qualEq(3, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant0(5)), qualEq(4, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant0(6)), qualEq(5, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant0(7)), qualEq(6, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant0(8)), qualEq(7, 2));

      expect(qual(FluidPairsIndividualStrategy_Variant1(2)), qualEq(0, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant1(3)), qualEq(1, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant1(4)), qualEq(3, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant1(5)), qualEq(5, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant1(6)), qualEq(7, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant1(7)), qualEq(9, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant1(8)), qualEq(11, 2));

      expect(qual(FluidPairsIndividualStrategy_Variant2(2)), qualEq(0, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant2(3)), qualEq(2, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant2(4)), qualEq(2, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant2(5)), qualEq(6, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant2(6)), qualEq(4, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant2(7)), qualEq(10, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant2(8)), qualEq(6, 2));

      expect(qual(FluidPairsIndividualStrategy_Variant3(2)), qualEq(0, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant3(3)), qualEq(2, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant3(4)), qualEq(4, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant3(5)), qualEq(6, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant3(6)), qualEq(8, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant3(7)), qualEq(10, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant3(8)), qualEq(12, 2));

      expect(qual(FluidPairsIndividualStrategy_Variant4(2)), qualEq(0, 1));
      expect(qual(FluidPairsIndividualStrategy_Variant4(3)), qualEq(1, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant4(4)), qualEq(3, 3));
      expect(qual(FluidPairsIndividualStrategy_Variant4(5)), qualEq(5, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant4(6)), qualEq(5, 3));
      expect(qual(FluidPairsIndividualStrategy_Variant4(7)), qualEq(9, 2));
      expect(qual(FluidPairsIndividualStrategy_Variant4(8)), qualEq(10, 3));

      expect(qual(FluidPairsIndividualStrategy(2)), qualEq(0, 1));
      expect(qual(FluidPairsIndividualStrategy(3)), qualEq(1, 2));
      expect(qual(FluidPairsIndividualStrategy(4)), qualEq(3, 2));
      expect(qual(FluidPairsIndividualStrategy(5)), qualEq(4, 2));
      expect(qual(FluidPairsIndividualStrategy(6)), qualEq(5, 2));
      expect(qual(FluidPairsIndividualStrategy(7)), qualEq(6, 2));
      expect(qual(FluidPairsIndividualStrategy(8)), qualEq(7, 2));

      // for (int i = 2; i <= 8; i++) {
      //   material.debugPrint('expect(qual(FluidPairsIndividualStrategy($i)), '
      //       'qualEq${qual(FluidPairsIndividualStrategy(i)).toString()});');
      // }
    });
  });
}
