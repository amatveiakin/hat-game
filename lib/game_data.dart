import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/app_info.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/team_compositions.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/util/assertion.dart';

class NavigationState {
  GamePhase lastSeenGamePhase;
  bool exitingGame = false;
}

class LocalGameData {
  final bool onlineMode;
  final String gameID;
  final DBDocumentReference gameReference;
  final int myPlayerID;
  final navigationState = NavigationState();

  bool get isAdmin => !onlineMode || myPlayerID == 0;

  String get gameRoute => '/game-$gameID';
  String get gameUrl => webAppPath + gameRoute;

  // Returns Game ID
  static String parseRoute(String route) {
    final String routePrefix = '/game-';
    if (!route.startsWith(routePrefix)) {
      return null;
    }
    return route.substring(routePrefix.length);
  }

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
  static int turnIndex(Iterable<TurnRecord> turnLog) => turnLog.length;

  static Set<int> wordsInHat(InitialGameState initialState,
      Iterable<TurnRecord> turnLog, TurnState turnState) {
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
      Iterable<PersonalState> otherPersonalStates) {
    final wordsFlaggedByOthers = Set<int>();
    for (final st in otherPersonalStates) {
      wordsFlaggedByOthers.addAll(st.wordFlags);
    }
    return wordsFlaggedByOthers;
  }
}

class TeamCompositionsViewData {
  final GameConfig gameConfig;
  final List<List<String>> playerNames;

  TeamCompositionsViewData({
    @required this.gameConfig,
    @required this.playerNames,
  });
}

class WordWritingViewData {
  final PersonalState playerState;
  final int numPlayers;
  final int numPlayersReady;
  final List<String> playersNotReady;

  WordWritingViewData({
    @required this.playerState,
    @required this.numPlayers,
    @required this.numPlayersReady,
    @required this.playersNotReady,
  });
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

class _PlayerPerformance {
  int wordsExplained = 0;
  int wordsGuessed = 0;
}

class PlayerScoreViewData {
  final String name;
  final int wordsExplained;
  final int wordsGuessed;

  PlayerScoreViewData(
      {@required this.name,
      @required this.wordsExplained,
      @required this.wordsGuessed});
}

class TeamScoreViewData {
  final int totalScore;
  final List<PlayerScoreViewData> players;

  TeamScoreViewData({@required this.totalScore, @required this.players});
}

class WordInTurnLogViewData {
  final String text;
  final WordStatus status;

  WordInTurnLogViewData({@required this.text, @required this.status});
}

class TurnLogViewData {
  final String party;
  final List<WordInTurnLogViewData> wordsInThisTurn;

  TurnLogViewData({@required this.party, @required this.wordsInThisTurn});
}

// All information about the game, read-only.
// Use GameController to influence the game.
class GameData {
  final GameConfig config;
  final InitialGameState initialState;
  final BuiltList<TurnRecord> turnLog;
  final TurnState turnState;
  final PersonalState personalState;
  final BuiltList<PersonalState> otherPersonalStates; // online-only

  GameData(this.config, this.initialState, this.turnLog, this.turnState,
      this.personalState, this.otherPersonalStates);

  bool gameFinished() => turnState == null;

  int turnIndex() => DerivedGameState.turnIndex(turnLog);

  int numWordsInHat() =>
      DerivedGameState.wordsInHat(initialState, turnLog, turnState).length;

  String currentWordText() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    return _wordText(turnState.wordsInThisTurn.last.id);
  }

  List<WordViewData> wordsInThisTurnData() {
    final wordsFlaggedByOthers =
        DerivedGameState.wordsFlaggedByOthers(otherPersonalStates);
    return turnState.wordsInThisTurn
        .map((w) => WordViewData(
              id: w.id,
              text: _wordText(w.id),
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

  List<TeamScoreViewData> scoreData() {
    final Map<int, _PlayerPerformance> playerPerformance = config.players.names
        .map((id, name) => MapEntry(id, _PlayerPerformance()))
        .toMap();
    for (final t in turnLog) {
      final int numWordsScored = t.wordsInThisTurn
          .where((w) => w.status == WordStatus.explained)
          .length;
      playerPerformance[t.party.performer].wordsExplained += numWordsScored;
      for (final p in t.party.recipients) {
        playerPerformance[p].wordsGuessed += numWordsScored;
      }
    }

    final scoreItems = List<TeamScoreViewData>();
    if (initialState.teamCompositions.teams != null) {
      for (final team in initialState.teamCompositions.teams) {
        final players = List<PlayerScoreViewData>();
        int totalWordsExplained = 0;
        int totalWordsGuessed = 0;
        for (final playerID in team) {
          final performance = playerPerformance[playerID];
          totalWordsExplained += performance.wordsExplained;
          totalWordsGuessed += performance.wordsGuessed;
          players.add(PlayerScoreViewData(
            name: config.players.names[playerID],
            wordsExplained: performance.wordsExplained,
            wordsGuessed: performance.wordsGuessed,
          ));
        }
        if (config.teaming.guessingInLargeTeam !=
            IndividualPlayStyle.broadcast) {
          Assert.eq(totalWordsExplained, totalWordsGuessed);
        }
        scoreItems.add(TeamScoreViewData(
          totalScore: totalWordsExplained,
          players: players,
        ));
      }
    } else {
      config.players.names.forEach((playerID, name) {
        final performance = playerPerformance[playerID];
        scoreItems.add(
          TeamScoreViewData(
            totalScore: performance.wordsExplained + performance.wordsGuessed,
            players: [
              PlayerScoreViewData(
                name: name,
                wordsExplained: performance.wordsExplained,
                wordsGuessed: performance.wordsGuessed,
              ),
            ],
          ),
        );
      });
    }
    scoreItems.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return scoreItems;
  }

  List<TurnLogViewData> turnLogData() {
    return turnLog
        .map((t) => TurnLogViewData(
              party: _partyToString(t.party),
              wordsInThisTurn: t.wordsInThisTurn
                  .map((w) => WordInTurnLogViewData(
                        text: _wordText(w.id),
                        status: w.status,
                      ))
                  .toList(),
            ))
        .toList();
  }

  String _partyToString(Party p) {
    return config.players.names[p.performer] +
        ' → ' +
        p.recipients.map((r) => config.players.names[r]).join(', ');
  }

  String _wordText(int wordID) {
    final word = initialState.words[wordID];
    Assert.eq(word.id, wordID);
    return word.text;
  }
}
