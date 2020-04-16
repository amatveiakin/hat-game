import 'dart:math';

import 'package:russian_words/russian_words.dart' as russian_words;

class Player {
  final String name;

  Player(this.name);
}

class Team {
  int performer;
  List<int> recipients;

  Team(this.performer, this.recipients);
}

abstract class TeamingStrategy {
  final int numPlayers;

  TeamingStrategy(this.numPlayers);

  Team getTeam(int turn);
}

class TeamsOfTwoTeamingStrategy extends TeamingStrategy {
  TeamsOfTwoTeamingStrategy(int numPlayers) : super(numPlayers) {
    assert(numPlayers % 2 == 0);
  }

  @override
  Team getTeam(int turn) {
    final performer = turn % numPlayers;
    final recipient = (performer + numPlayers ~/ 2) % numPlayers;
    return Team(performer, [recipient]);
  }
}

enum TurnPhase {
  prepare,
  explain,
  review,
}

class GameState {
  final List<Player> _players;
  final TeamingStrategy _teamingStrategy;
  final _wordsInHat = <String>[];
  final _turnPhase = TurnPhase.prepare;

  GameState(this._players)
      : _teamingStrategy = TeamsOfTwoTeamingStrategy(_players.length) {
    final words = Set<String>();
    while (words.length < 20) {
      words.add(
          russian_words.nouns[Random().nextInt(russian_words.nouns.length)]);
    }
    _wordsInHat.addAll(words);
  }

  // TODO: delete
  String someWord() { return _wordsInHat.first; }
  GameState.example()
      : this([
          Player('Vasya'),
          Player('Petya'),
          Player('Masha'),
          Player('Dasha'),
        ]);
}
