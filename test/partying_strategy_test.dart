import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:test/test.dart';

// TODO: Test all strategies.

partyEquals(int performer, List<int> recipients) => TypeMatcher<Party>()
    .having((t) => t.performer, 'performer', equals(performer))
    .having((t) => t.recipients, 'recipients', equals(recipients));

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
          generateTeamPlayers([2, 2]),
          equals([
            [0, 1],
            [2, 3],
          ]));
    });

    test('2 + 3', () {
      expect(
          generateTeamPlayers([3, 2]),
          equals([
            [0, 1, 2],
            [3, 4],
          ]));
    });
  });

  group('fixed teams strategy', () {
    test('2 + 2', () {
      final strategy = FixedTeamsStrategy([
        [0, 1],
        [2, 3],
      ], IndividualPlayStyle.fluidPairs);
      expect(strategy.getParty(0), partyEquals(0, [1]));
      expect(strategy.getParty(1), partyEquals(2, [3]));
      expect(strategy.getParty(2), partyEquals(1, [0]));
      expect(strategy.getParty(3), partyEquals(3, [2]));
      expect(strategy.getParty(4), partyEquals(0, [1]));
    });

    test('2 + 3', () {
      final strategy = FixedTeamsStrategy([
        [0, 1, 2],
        [3, 4],
      ], IndividualPlayStyle.fluidPairs);
      expect(strategy.getParty(0), partyEquals(0, [1]));
      expect(strategy.getParty(1), partyEquals(3, [4]));
      expect(strategy.getParty(2), partyEquals(1, [2]));
      expect(strategy.getParty(3), partyEquals(4, [3]));
      expect(strategy.getParty(4), partyEquals(2, [0]));
      expect(strategy.getParty(5), partyEquals(3, [4]));
      // ---------------------------------------------
      expect(strategy.getParty(6), partyEquals(0, [2]));
      expect(strategy.getParty(7), partyEquals(4, [3]));
      expect(strategy.getParty(8), partyEquals(1, [0]));
      expect(strategy.getParty(9), partyEquals(3, [4]));
      expect(strategy.getParty(10), partyEquals(2, [1]));
      expect(strategy.getParty(11), partyEquals(4, [3]));
      // ---------------------------------------------
      expect(strategy.getParty(12), partyEquals(0, [1]));
    });
  });
}
