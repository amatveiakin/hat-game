import 'dart:math';

import 'package:hatgame/teaming_strategy.dart';
import 'package:russian_words/russian_words.dart' as russian_words;

class Player {
  final String name;

  Player(this.name);
}

class TeamViewData {
  final Player performer;
  final List<Player> recipients;

  TeamViewData(this.performer, this.recipients);
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
  TurnPhase _turnPhase;
  Team _currentTeam;
  int _turn = 0;

  GameState(this._players)
      : _teamingStrategy = TeamsOfTwoStrategy(_players.length) {
    final words = Set<String>();
    while (words.length < 20) {
      words.add(
          russian_words.nouns[Random().nextInt(russian_words.nouns.length)]);
    }
    _wordsInHat.addAll(words);
    _initTurn();
  }

  void _initTurn() {
    _turnPhase = TurnPhase.prepare;
    _currentTeam = _teamingStrategy.getTeam(_turn);
  }

  void newTurn() {
    _turn++;
    _initTurn();
  }

  TeamViewData currentTeamViewData() {
    return TeamViewData(_players[_currentTeam.performer],
        _currentTeam.recipients.map((id) => _players[id]).toList());
  }

  // TODO: delete
  String someWord() {
    return _wordsInHat.first;
  }

  GameState.example()
      : this([
          Player('Vasya'),
          Player('Petya'),
          Player('Masha'),
          Player('Dasha'),
        ]);
}
