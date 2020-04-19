import 'dart:math';

import 'package:hatgame/game_settings.dart';
import 'package:hatgame/teaming_strategy.dart';
import 'package:russian_words/russian_words.dart' as russian_words;

class Player {
  final String name;
  var wordsExplained = <int>[];
  var wordsGuessed = <int>[];

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

class Word {
  final int id;
  final String text;

  Word(this.id, this.text);
}

enum WordInTurnStatus {
  notExplained,
  explained,
  discarded,
}

enum WordFeedback {
  none,
  good,
  bad,
  tooEasy,
  tooHard,
}

class WordInTurn {
  int id;
  WordInTurnStatus status = WordInTurnStatus.notExplained;
  WordFeedback feedback = WordFeedback.none;

  WordInTurn(this.id);
}

class WordInTurnViewData {
  int id;
  String text;
  WordInTurnStatus status;
  WordFeedback feedback;

  WordInTurnViewData(this.id, this.text, this.status, this.feedback);
}

class GameState {
  final List<Player> _players;
  final TeamingStrategy _teamingStrategy;
  Team _currentTeam;

  // Store word IDs rather than words themselves for disambigution in case
  // two words are equal.
  final _words = <Word>[];
  final _wordsInHat = <int>[];
  final _wordsInThisTurn = <WordInTurn>[];
  int _currentWord;

  int _turn = 0;
  TurnPhase _turnPhase;

  GameState(GameSettings settings)
      : _players = settings.teamPlayers
            .expand((t) => t)
            .map((p) => Player(p))
            .toList(),
        _teamingStrategy = FixedTeamsEverybodyRecipientStrategy(
            settings.teamPlayers.map((t) => t.length).toList()) {
    for (int i = 0; i < 5; ++i) {
      _words.add(Word(i,
          russian_words.nouns[Random().nextInt(russian_words.nouns.length)]));
      _wordsInHat.add(i);
    }
    _initTurn();
  }

  void _initTurn() {
    _turnPhase = TurnPhase.prepare;
    _currentTeam = _teamingStrategy.getTeam(_turn);
  }

  void _finishTurn() {
    _turnPhase = null;
    for (final w in _wordsInThisTurn) {
      if (w.status == WordInTurnStatus.notExplained) {
        assert(!_wordsInHat.contains(w.id));
        _wordsInHat.add(w.id);
      }
    }
    final List<int> wordsExplained = _wordsInThisTurn
        .where((w) => w.status == WordInTurnStatus.explained)
        .map((w) => w.id)
        .toList();
    _players[_currentTeam.performer].wordsExplained.addAll(wordsExplained);
    for (final recipient in _currentTeam.recipients) {
      _players[recipient].wordsGuessed.addAll(wordsExplained);
    }
    _wordsInThisTurn.clear();
  }

  void _drawNextWord() {
    assert(_turnPhase == TurnPhase.explain);
    if (_wordsInHat.isEmpty) {
      finishExplanation();
      return;
    }
    _currentWord = _wordsInHat[Random().nextInt(_wordsInHat.length)];
    _wordsInThisTurn.add(WordInTurn(_currentWord));
    final removed = _wordsInHat.remove(_currentWord);
    assert(removed);
  }

  int currentTurn() => _turn;

  TurnPhase turnPhase() => _turnPhase;

  int numWordsInHat() => _wordsInHat.length;

  String currentWord() {
    assert(_turnPhase == TurnPhase.explain);
    return _words[_currentWord].text;
  }

  List<WordInTurnViewData> wordsInThisTurnViewData() {
    return _wordsInThisTurn
        .map((w) =>
            WordInTurnViewData(w.id, _words[w.id].text, w.status, w.feedback))
        .toList();
  }

  void newTurn() {
    assert(_turnPhase == TurnPhase.review);
    _finishTurn();
    _turn++;
    _initTurn();
  }

  void startExplaning() {
    assert(_turnPhase == TurnPhase.prepare);
    _turnPhase = TurnPhase.explain;
    _drawNextWord();
  }

  void wordGuessed() {
    assert(_turnPhase == TurnPhase.explain);
    assert(_wordsInThisTurn.isNotEmpty);
    assert(_wordsInThisTurn.last.id == _currentWord);
    _wordsInThisTurn.last.status = WordInTurnStatus.explained;
    _drawNextWord();
  }

  void finishExplanation({int turnRestriction}) {
    if (turnRestriction != null) {
      if (turnRestriction != _turn || _turnPhase != TurnPhase.explain) return;
    } else {
      assert(_turnPhase == TurnPhase.explain);
    }
    _turnPhase = TurnPhase.review;
  }

  void setWordStatus(int wordId, WordInTurnStatus newStatus) {
    assert(_turnPhase == TurnPhase.review);
    _wordsInThisTurn.singleWhere((w) => w.id == wordId).status = newStatus;
  }

  void setWordFeedback(int wordId, WordFeedback newFeedback) {
    assert(_turnPhase == TurnPhase.review);
    _wordsInThisTurn.singleWhere((w) => w.id == wordId).feedback = newFeedback;
  }

  TeamViewData currentTeamViewData() {
    return TeamViewData(_players[_currentTeam.performer],
        _currentTeam.recipients.map((id) => _players[id]).toList());
  }
}
