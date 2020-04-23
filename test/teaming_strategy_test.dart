import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:hatgame/game_config.dart';
import 'package:hatgame/teaming_strategy.dart';
import 'package:test/test.dart';

// TODO: Test all strategies.

teamEquals(int performer, List<int> recipients) => TypeMatcher<Team>()
    .having((t) => t.performer, 'performer', equals(performer))
    .having((t) => t.recipients, 'recipients', equals(recipients));

void main() {
  group('teams of two', () {
    test('4 players', () {
      final strategy = FixedTeamsStrategy.generateTeams(
          4,
          DesiredTeamSize.teamsOf2,
          UnequalTeamSize.dropPlayers,
          IndividualPlayStyle.fluidPairs);
      expect(strategy.getTeam(0), teamEquals(0, [1]));
      expect(strategy.getTeam(1), teamEquals(2, [3]));
      expect(strategy.getTeam(2), teamEquals(1, [0]));
      expect(strategy.getTeam(3), teamEquals(3, [2]));
      expect(strategy.getTeam(4), teamEquals(0, [1]));
    });

    test('6 players', () {
      final strategy = FixedTeamsStrategy.generateTeams(
          6,
          DesiredTeamSize.teamsOf2,
          UnequalTeamSize.dropPlayers,
          IndividualPlayStyle.fluidPairs);
      expect(strategy.getTeam(0), teamEquals(0, [1]));
      expect(strategy.getTeam(1), teamEquals(2, [3]));
      expect(strategy.getTeam(2), teamEquals(4, [5]));
      expect(strategy.getTeam(3), teamEquals(1, [0]));
      expect(strategy.getTeam(4), teamEquals(3, [2]));
      expect(strategy.getTeam(5), teamEquals(5, [4]));
      expect(strategy.getTeam(6), teamEquals(0, [1]));
    });

    test('odd number of players forbidden', () {
      expect(
        () {
          FixedTeamsStrategy.generateTeams(5, DesiredTeamSize.teamsOf2,
              UnequalTeamSize.dropPlayers, IndividualPlayStyle.fluidPairs);
        },
        flutter_test.throwsA(isA<CannotMakeTeaming>()),
      );
    });

    test('odd number of players allowed', () {
      final strategy = FixedTeamsStrategy.generateTeams(
          5,
          DesiredTeamSize.teamsOf2,
          UnequalTeamSize.expandTeams,
          IndividualPlayStyle.fluidPairs);
      // teams: {0, 1, 2}, {3, 4}
      expect(strategy.getTeam(0), teamEquals(0, [1]));
      expect(strategy.getTeam(1), teamEquals(3, [4]));
      expect(strategy.getTeam(2), teamEquals(1, [2]));
      expect(strategy.getTeam(3), teamEquals(4, [3]));
      expect(strategy.getTeam(4), teamEquals(2, [0]));
      expect(strategy.getTeam(5), teamEquals(3, [4]));
      // ---------------------------------------------
      expect(strategy.getTeam(6), teamEquals(0, [2]));
      expect(strategy.getTeam(7), teamEquals(4, [3]));
      expect(strategy.getTeam(8), teamEquals(1, [0]));
      expect(strategy.getTeam(9), teamEquals(3, [4]));
      expect(strategy.getTeam(10), teamEquals(2, [1]));
      expect(strategy.getTeam(11), teamEquals(4, [3]));
      // ---------------------------------------------
      expect(strategy.getTeam(12), teamEquals(0, [1]));
    });
  });
}
