import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/util/assertion.dart';

class PartyViewData {
  final PlayerState performer;
  final List<PlayerState> recipients;

  PartyViewData(this.performer, this.recipients);
}

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

class DerivedGameState {
  final BuiltSet<int> flaggedWords;

  DerivedGameState({@required this.flaggedWords});
}

// All information about the game, read-only.
// Use GameController to influence the game.
class GameData {
  final GameConfig config;
  final GameState state;
  final DerivedGameState derivedState;
  final PersonalState personalState;
  final LocalGameState localState;

  GameData(this.config, this.state, this.derivedState, this.personalState,
      this.localState);

  int numWordsInHat() => state.wordsInHat.length;

  String currentWordText() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    return state.words[state.currentWord].text;
  }

  List<Word> wordsInThisTurnData() {
    return state.wordsInThisTurn.map((wordId) => state.words[wordId]).toList();
  }

  PartyViewData currentPartyViewData() {
    return PartyViewData(state.players[state.currentParty.performer],
        state.currentParty.recipients.map((id) => state.players[id]).toList());
  }
}
