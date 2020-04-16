import 'dart:math';

import 'package:hatgame/teaming_strategy.dart';
import 'package:russian_words/russian_words.dart' as russian_words;

class Player {
  final String name;

  Player(this.name);
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
      : _teamingStrategy = TeamsOfTwoStrategy(_players.length) {
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
