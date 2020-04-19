import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:hatgame/teaming_strategy.dart';
import 'package:test/test.dart';

teamEquals(int performer, List<int> recipients) => TypeMatcher<Team>()
    .having((t) => t.performer, 'performer', equals(performer))
    .having((t) => t.recipients, 'recipients', equals(recipients));

void main() {
  group('teams of two', () {
    test('2 players', () {
      final strategy = FixedTeamsStrategy.teamsOfTwo(2);
      expect(strategy.getTeam(0), teamEquals(0, [1]));
      expect(strategy.getTeam(1), teamEquals(1, [0]));
      expect(strategy.getTeam(10), teamEquals(0, [1]));
    });

    test('4 players', () {
      final strategy = FixedTeamsStrategy.teamsOfTwo(4);
      expect(strategy.getTeam(0), teamEquals(0, [1]));
      expect(strategy.getTeam(1), teamEquals(2, [3]));
      expect(strategy.getTeam(2), teamEquals(1, [0]));
      expect(strategy.getTeam(3), teamEquals(3, [2]));
      expect(strategy.getTeam(4), teamEquals(0, [1]));
    });

    test('6 players', () {
      final strategy = FixedTeamsStrategy.teamsOfTwo(6);
      expect(strategy.getTeam(0), teamEquals(0, [1]));
      expect(strategy.getTeam(1), teamEquals(2, [3]));
      expect(strategy.getTeam(2), teamEquals(4, [5]));
      expect(strategy.getTeam(3), teamEquals(1, [0]));
      expect(strategy.getTeam(4), teamEquals(3, [2]));
      expect(strategy.getTeam(5), teamEquals(5, [4]));
      expect(strategy.getTeam(6), teamEquals(0, [1]));
    });

    test('odd number of players', () {
      expect(() => FixedTeamsStrategy.teamsOfTwo(3),
          flutter_test.throwsAssertionError);
    });
  });
}
