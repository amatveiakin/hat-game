// GENERATED CODE - DO NOT MODIFY BY HAND

part of game_state;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TurnPhase _$prepare = const TurnPhase._('prepare');
const TurnPhase _$explain = const TurnPhase._('explain');
const TurnPhase _$review = const TurnPhase._('review');

TurnPhase _$valueOfTurnPhase(String name) {
  switch (name) {
    case 'prepare':
      return _$prepare;
    case 'explain':
      return _$explain;
    case 'review':
      return _$review;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<TurnPhase> _$valuesTurnPhase =
    new BuiltSet<TurnPhase>(const <TurnPhase>[
  _$prepare,
  _$explain,
  _$review,
]);

const WordStatus _$notExplained = const WordStatus._('notExplained');
const WordStatus _$explained = const WordStatus._('explained');
const WordStatus _$discarded = const WordStatus._('discarded');

WordStatus _$valueOfWordStatus(String name) {
  switch (name) {
    case 'notExplained':
      return _$notExplained;
    case 'explained':
      return _$explained;
    case 'discarded':
      return _$discarded;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<WordStatus> _$valuesWordStatus =
    new BuiltSet<WordStatus>(const <WordStatus>[
  _$notExplained,
  _$explained,
  _$discarded,
]);

const WordFeedback _$good = const WordFeedback._('good');
const WordFeedback _$bad = const WordFeedback._('bad');
const WordFeedback _$tooEasy = const WordFeedback._('tooEasy');
const WordFeedback _$tooHard = const WordFeedback._('tooHard');

WordFeedback _$valueOfWordFeedback(String name) {
  switch (name) {
    case 'good':
      return _$good;
    case 'bad':
      return _$bad;
    case 'tooEasy':
      return _$tooEasy;
    case 'tooHard':
      return _$tooHard;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<WordFeedback> _$valuesWordFeedback =
    new BuiltSet<WordFeedback>(const <WordFeedback>[
  _$good,
  _$bad,
  _$tooEasy,
  _$tooHard,
]);

class _$PlayerState extends PlayerState {
  @override
  final int id;
  @override
  final String name;
  @override
  final BuiltList<int> wordsExplained;
  @override
  final BuiltList<int> wordsGuessed;

  factory _$PlayerState([void Function(PlayerStateBuilder) updates]) =>
      (new PlayerStateBuilder()..update(updates)).build();

  _$PlayerState._({this.id, this.name, this.wordsExplained, this.wordsGuessed})
      : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('PlayerState', 'id');
    }
    if (name == null) {
      throw new BuiltValueNullFieldError('PlayerState', 'name');
    }
    if (wordsExplained == null) {
      throw new BuiltValueNullFieldError('PlayerState', 'wordsExplained');
    }
    if (wordsGuessed == null) {
      throw new BuiltValueNullFieldError('PlayerState', 'wordsGuessed');
    }
  }

  @override
  PlayerState rebuild(void Function(PlayerStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayerStateBuilder toBuilder() => new PlayerStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayerState &&
        id == other.id &&
        name == other.name &&
        wordsExplained == other.wordsExplained &&
        wordsGuessed == other.wordsGuessed;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, id.hashCode), name.hashCode), wordsExplained.hashCode),
        wordsGuessed.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PlayerState')
          ..add('id', id)
          ..add('name', name)
          ..add('wordsExplained', wordsExplained)
          ..add('wordsGuessed', wordsGuessed))
        .toString();
  }
}

class PlayerStateBuilder implements Builder<PlayerState, PlayerStateBuilder> {
  _$PlayerState _$v;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  ListBuilder<int> _wordsExplained;
  ListBuilder<int> get wordsExplained =>
      _$this._wordsExplained ??= new ListBuilder<int>();
  set wordsExplained(ListBuilder<int> wordsExplained) =>
      _$this._wordsExplained = wordsExplained;

  ListBuilder<int> _wordsGuessed;
  ListBuilder<int> get wordsGuessed =>
      _$this._wordsGuessed ??= new ListBuilder<int>();
  set wordsGuessed(ListBuilder<int> wordsGuessed) =>
      _$this._wordsGuessed = wordsGuessed;

  PlayerStateBuilder();

  PlayerStateBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _name = _$v.name;
      _wordsExplained = _$v.wordsExplained?.toBuilder();
      _wordsGuessed = _$v.wordsGuessed?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayerState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PlayerState;
  }

  @override
  void update(void Function(PlayerStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PlayerState build() {
    _$PlayerState _$result;
    try {
      _$result = _$v ??
          new _$PlayerState._(
              id: id,
              name: name,
              wordsExplained: wordsExplained.build(),
              wordsGuessed: wordsGuessed.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'wordsExplained';
        wordsExplained.build();
        _$failedField = 'wordsGuessed';
        wordsGuessed.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'PlayerState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$Party extends Party {
  @override
  final int performer;
  @override
  final BuiltList<int> recipients;

  factory _$Party([void Function(PartyBuilder) updates]) =>
      (new PartyBuilder()..update(updates)).build();

  _$Party._({this.performer, this.recipients}) : super._() {
    if (performer == null) {
      throw new BuiltValueNullFieldError('Party', 'performer');
    }
    if (recipients == null) {
      throw new BuiltValueNullFieldError('Party', 'recipients');
    }
  }

  @override
  Party rebuild(void Function(PartyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PartyBuilder toBuilder() => new PartyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Party &&
        performer == other.performer &&
        recipients == other.recipients;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, performer.hashCode), recipients.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Party')
          ..add('performer', performer)
          ..add('recipients', recipients))
        .toString();
  }
}

class PartyBuilder implements Builder<Party, PartyBuilder> {
  _$Party _$v;

  int _performer;
  int get performer => _$this._performer;
  set performer(int performer) => _$this._performer = performer;

  ListBuilder<int> _recipients;
  ListBuilder<int> get recipients =>
      _$this._recipients ??= new ListBuilder<int>();
  set recipients(ListBuilder<int> recipients) =>
      _$this._recipients = recipients;

  PartyBuilder();

  PartyBuilder get _$this {
    if (_$v != null) {
      _performer = _$v.performer;
      _recipients = _$v.recipients?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Party other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Party;
  }

  @override
  void update(void Function(PartyBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Party build() {
    _$Party _$result;
    try {
      _$result = _$v ??
          new _$Party._(performer: performer, recipients: recipients.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'recipients';
        recipients.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Party', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$Word extends Word {
  @override
  final int id;
  @override
  final String text;
  @override
  final WordStatus status;
  @override
  final WordFeedback feedback;

  factory _$Word([void Function(WordBuilder) updates]) =>
      (new WordBuilder()..update(updates)).build();

  _$Word._({this.id, this.text, this.status, this.feedback}) : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('Word', 'id');
    }
    if (text == null) {
      throw new BuiltValueNullFieldError('Word', 'text');
    }
    if (status == null) {
      throw new BuiltValueNullFieldError('Word', 'status');
    }
  }

  @override
  Word rebuild(void Function(WordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WordBuilder toBuilder() => new WordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Word &&
        id == other.id &&
        text == other.text &&
        status == other.status &&
        feedback == other.feedback;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, id.hashCode), text.hashCode), status.hashCode),
        feedback.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Word')
          ..add('id', id)
          ..add('text', text)
          ..add('status', status)
          ..add('feedback', feedback))
        .toString();
  }
}

class WordBuilder implements Builder<Word, WordBuilder> {
  _$Word _$v;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _text;
  String get text => _$this._text;
  set text(String text) => _$this._text = text;

  WordStatus _status;
  WordStatus get status => _$this._status;
  set status(WordStatus status) => _$this._status = status;

  WordFeedback _feedback;
  WordFeedback get feedback => _$this._feedback;
  set feedback(WordFeedback feedback) => _$this._feedback = feedback;

  WordBuilder();

  WordBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _text = _$v.text;
      _status = _$v.status;
      _feedback = _$v.feedback;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Word other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Word;
  }

  @override
  void update(void Function(WordBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Word build() {
    final _$result = _$v ??
        new _$Word._(id: id, text: text, status: status, feedback: feedback);
    replace(_$result);
    return _$result;
  }
}

class _$GameState extends GameState {
  @override
  final BuiltList<PlayerState> players;
  @override
  final BuiltList<BuiltList<int>> teams;
  @override
  final Party currentParty;
  @override
  final BuiltList<Word> words;
  @override
  final BuiltList<int> wordsInHat;
  @override
  final BuiltList<int> wordsInThisTurn;
  @override
  final int currentWord;
  @override
  final int turn;
  @override
  final TurnPhase turnPhase;
  @override
  final bool gameFinished;

  factory _$GameState([void Function(GameStateBuilder) updates]) =>
      (new GameStateBuilder()..update(updates)).build();

  _$GameState._(
      {this.players,
      this.teams,
      this.currentParty,
      this.words,
      this.wordsInHat,
      this.wordsInThisTurn,
      this.currentWord,
      this.turn,
      this.turnPhase,
      this.gameFinished})
      : super._() {
    if (players == null) {
      throw new BuiltValueNullFieldError('GameState', 'players');
    }
    if (words == null) {
      throw new BuiltValueNullFieldError('GameState', 'words');
    }
    if (wordsInHat == null) {
      throw new BuiltValueNullFieldError('GameState', 'wordsInHat');
    }
    if (gameFinished == null) {
      throw new BuiltValueNullFieldError('GameState', 'gameFinished');
    }
  }

  @override
  GameState rebuild(void Function(GameStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GameStateBuilder toBuilder() => new GameStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GameState &&
        players == other.players &&
        teams == other.teams &&
        currentParty == other.currentParty &&
        words == other.words &&
        wordsInHat == other.wordsInHat &&
        wordsInThisTurn == other.wordsInThisTurn &&
        currentWord == other.currentWord &&
        turn == other.turn &&
        turnPhase == other.turnPhase &&
        gameFinished == other.gameFinished;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc($jc(0, players.hashCode),
                                        teams.hashCode),
                                    currentParty.hashCode),
                                words.hashCode),
                            wordsInHat.hashCode),
                        wordsInThisTurn.hashCode),
                    currentWord.hashCode),
                turn.hashCode),
            turnPhase.hashCode),
        gameFinished.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('GameState')
          ..add('players', players)
          ..add('teams', teams)
          ..add('currentParty', currentParty)
          ..add('words', words)
          ..add('wordsInHat', wordsInHat)
          ..add('wordsInThisTurn', wordsInThisTurn)
          ..add('currentWord', currentWord)
          ..add('turn', turn)
          ..add('turnPhase', turnPhase)
          ..add('gameFinished', gameFinished))
        .toString();
  }
}

class GameStateBuilder implements Builder<GameState, GameStateBuilder> {
  _$GameState _$v;

  ListBuilder<PlayerState> _players;
  ListBuilder<PlayerState> get players =>
      _$this._players ??= new ListBuilder<PlayerState>();
  set players(ListBuilder<PlayerState> players) => _$this._players = players;

  ListBuilder<BuiltList<int>> _teams;
  ListBuilder<BuiltList<int>> get teams =>
      _$this._teams ??= new ListBuilder<BuiltList<int>>();
  set teams(ListBuilder<BuiltList<int>> teams) => _$this._teams = teams;

  PartyBuilder _currentParty;
  PartyBuilder get currentParty => _$this._currentParty ??= new PartyBuilder();
  set currentParty(PartyBuilder currentParty) =>
      _$this._currentParty = currentParty;

  ListBuilder<Word> _words;
  ListBuilder<Word> get words => _$this._words ??= new ListBuilder<Word>();
  set words(ListBuilder<Word> words) => _$this._words = words;

  ListBuilder<int> _wordsInHat;
  ListBuilder<int> get wordsInHat =>
      _$this._wordsInHat ??= new ListBuilder<int>();
  set wordsInHat(ListBuilder<int> wordsInHat) =>
      _$this._wordsInHat = wordsInHat;

  ListBuilder<int> _wordsInThisTurn;
  ListBuilder<int> get wordsInThisTurn =>
      _$this._wordsInThisTurn ??= new ListBuilder<int>();
  set wordsInThisTurn(ListBuilder<int> wordsInThisTurn) =>
      _$this._wordsInThisTurn = wordsInThisTurn;

  int _currentWord;
  int get currentWord => _$this._currentWord;
  set currentWord(int currentWord) => _$this._currentWord = currentWord;

  int _turn;
  int get turn => _$this._turn;
  set turn(int turn) => _$this._turn = turn;

  TurnPhase _turnPhase;
  TurnPhase get turnPhase => _$this._turnPhase;
  set turnPhase(TurnPhase turnPhase) => _$this._turnPhase = turnPhase;

  bool _gameFinished;
  bool get gameFinished => _$this._gameFinished;
  set gameFinished(bool gameFinished) => _$this._gameFinished = gameFinished;

  GameStateBuilder();

  GameStateBuilder get _$this {
    if (_$v != null) {
      _players = _$v.players?.toBuilder();
      _teams = _$v.teams?.toBuilder();
      _currentParty = _$v.currentParty?.toBuilder();
      _words = _$v.words?.toBuilder();
      _wordsInHat = _$v.wordsInHat?.toBuilder();
      _wordsInThisTurn = _$v.wordsInThisTurn?.toBuilder();
      _currentWord = _$v.currentWord;
      _turn = _$v.turn;
      _turnPhase = _$v.turnPhase;
      _gameFinished = _$v.gameFinished;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GameState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$GameState;
  }

  @override
  void update(void Function(GameStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$GameState build() {
    _$GameState _$result;
    try {
      _$result = _$v ??
          new _$GameState._(
              players: players.build(),
              teams: _teams?.build(),
              currentParty: _currentParty?.build(),
              words: words.build(),
              wordsInHat: wordsInHat.build(),
              wordsInThisTurn: _wordsInThisTurn?.build(),
              currentWord: currentWord,
              turn: turn,
              turnPhase: turnPhase,
              gameFinished: gameFinished);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'players';
        players.build();
        _$failedField = 'teams';
        _teams?.build();
        _$failedField = 'currentParty';
        _currentParty?.build();
        _$failedField = 'words';
        words.build();
        _$failedField = 'wordsInHat';
        wordsInHat.build();
        _$failedField = 'wordsInThisTurn';
        _wordsInThisTurn?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'GameState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
