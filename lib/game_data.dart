import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/util/assertion.dart';

// TODO: Rename in order to make it explicit that these are immutable settings.
class LocalGameData {
  final bool onlineMode;
  final String gameID;
  final DBDocumentReference gameReference;
  final int myPlayerID;

  bool get isAdmin => !onlineMode || myPlayerID == 0;

  LocalGameData(
      {@required this.onlineMode,
      this.gameID,
      @required this.gameReference,
      this.myPlayerID}) {
    Assert.holds(onlineMode != null);
    Assert.holds(gameReference != null);
  }
}

class LocalGameState {
  bool startButtonEnabled = false;
}

// Namespace class for computing information about the game that is not
// persisted to the DB.
//
// Things that are required by GameController or other parts of the engine
// go here (for clearer dependencies). Things needed only for GUI can go to
// GameData directly.
//
class DerivedGameState {
  static int turnIndex(List<TurnRecord> turnLog) => turnLog.length;

  static Set<int> wordsInHat(InitialGameState initialState,
      List<TurnRecord> turnLog, TurnState turnState) {
    final Set<int> wordsInHat = initialState.words.map((w) => w.id).toSet();
    for (final t in turnLog) {
      wordsInHat.removeAll(t.wordsInThisTurn
          .where((w) => w.status != WordStatus.notExplained)
          .map((w) => w.id));
    }
    if (turnState != null) {
      wordsInHat.removeAll(turnState.wordsInThisTurn.map((w) => w.id));
    }
    return wordsInHat;
  }

  static Set<int> wordsFlaggedByOthers(
      List<PersonalState> otherPersonalStates) {
    final wordsFlaggedByOthers = Set<int>();
    for (final st in otherPersonalStates) {
      wordsFlaggedByOthers.addAll(st.wordFlags);
    }
    return wordsFlaggedByOthers;
  }
}

class PlayerViewData {
  final int id;
  final String name;

  PlayerViewData({@required this.id, @required this.name});
}

class PartyViewData {
  final PlayerViewData performer;
  final List<PlayerViewData> recipients;

  PartyViewData({@required this.performer, @required this.recipients});
}

class WordViewData {
  final int id;
  final String text;
  final WordStatus status;
  final WordFeedback feedback;
  final bool flaggedByActivePlayer;
  final bool flaggedByOthers;

  WordViewData({
    @required this.id,
    @required this.text,
    @required this.status,
    @required this.feedback,
    @required this.flaggedByActivePlayer,
    @required this.flaggedByOthers,
  });
}

// All information about the game, read-only.
// Use GameController to influence the game.
class GameData {
  final GameConfig config;
  final InitialGameState initialState;
  final List<TurnRecord> turnLog;
  final TurnState turnState;
  final PersonalState personalState;
  final List<PersonalState> otherPersonalStates; // online-only
  final LocalGameState localState;

  GameData(this.config, this.initialState, this.turnLog, this.turnState,
      this.personalState, this.otherPersonalStates, this.localState);

  bool gameFinished() => turnState == null;

  int turnIndex() => DerivedGameState.turnIndex(turnLog);

  int numWordsInHat() =>
      DerivedGameState.wordsInHat(initialState, turnLog, turnState).length;

  String currentWordText() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    return initialState.words[turnState.wordsInThisTurn.last.id].text;
  }

  List<WordViewData> wordsInThisTurnData() {
    final wordsFlaggedByOthers =
        DerivedGameState.wordsFlaggedByOthers(otherPersonalStates);
    return turnState.wordsInThisTurn
        .map((w) => WordViewData(
              id: w.id,
              text: initialState.words[w.id].text,
              status: w.status,
              feedback: personalState.wordFeedback[w.id],
              flaggedByActivePlayer: personalState.wordFlags.contains(w.id),
              flaggedByOthers: wordsFlaggedByOthers.contains(w.id),
            ))
        .toList();
  }

  PlayerViewData _playerViewData(int playerID) {
    return PlayerViewData(
      id: playerID,
      name: config.players.names[playerID],
    );
  }

  PartyViewData currentPartyViewData() {
    return PartyViewData(
      performer: _playerViewData(turnState.party.performer),
      recipients:
          turnState.party.recipients.map((id) => _playerViewData(id)).toList(),
    );
  }
}
