import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:hatgame/teaming_strategy.dart';
import 'package:test/test.dart';

teamEquals(int performer, List<int> recipients) => TypeMatcher<Team>()
    .having((t) => t.performer, 'performer', equals(performer))
    .having((t) => t.recipients, 'recipients', equals(recipients));

void main() {
  group('TeamsOfTwoStrategy', () {
    test('2 players', () {
      final strategy = TeamsOfTwoStrategy(2);
      expect(strategy.getTeam(0), teamEquals(0, [1]));
      expect(strategy.getTeam(1), teamEquals(1, [0]));
      expect(strategy.getTeam(10), teamEquals(0, [1]));
    });

    test('4 players', () {
      final strategy = TeamsOfTwoStrategy(4);
      expect(strategy.getTeam(0), teamEquals(0, [2]));
      expect(strategy.getTeam(1), teamEquals(1, [3]));
      expect(strategy.getTeam(2), teamEquals(2, [0]));
      expect(strategy.getTeam(3), teamEquals(3, [1]));
      expect(strategy.getTeam(4), teamEquals(0, [2]));
    });

    test('6 players', () {
      final strategy = TeamsOfTwoStrategy(6);
      expect(strategy.getTeam(0), teamEquals(0, [3]));
      expect(strategy.getTeam(1), teamEquals(1, [4]));
      expect(strategy.getTeam(2), teamEquals(2, [5]));
      expect(strategy.getTeam(3), teamEquals(3, [0]));
      expect(strategy.getTeam(4), teamEquals(4, [1]));
      expect(strategy.getTeam(5), teamEquals(5, [2]));
      expect(strategy.getTeam(6), teamEquals(0, [3]));
    });

    test('odd number of players', () {
      expect(() => TeamsOfTwoStrategy(3), flutter_test.throwsAssertionError);
    });
  });
}
