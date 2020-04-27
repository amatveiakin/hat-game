import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/db_constants.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/built_value_ext.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:russian_words/russian_words.dart' as russian_words;

class GameTransformer {
  final GameConfig config;
  GameState state;

  GameTransformer(this.config, this.state);

  void nextTurn() {
    Assert.eq(state.turnPhase, TurnPhase.review);
    finishTurn();
    if (state.wordsInHat.length == 0) {
      Assert.holds(!state.gameFinished);
      state = state.rebuild(
        (b) => b..gameFinished = true,
      );
    } else {
      state = state.rebuild(
        (b) => b..turn = state.turn + 1,
      );
      initTurn();
    }
  }

  void startExplaning() {
    Assert.eq(state.turnPhase, TurnPhase.prepare);
    state = state.rebuild(
      (b) => b..turnPhase = TurnPhase.explain,
    );
    drawNextWord();
  }

  void wordGuessed() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    Assert.holds(state.wordsInThisTurn.isNotEmpty);
    Assert.eq(state.wordsInThisTurn.last, state.currentWord);
    setWordStatus(state.currentWord, WordStatus.explained);
    drawNextWord();
  }

  void finishExplanation() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    state = state.rebuild(
      (b) => b..turnPhase = TurnPhase.review,
    );
  }

  void setWordStatus(int wordId, WordStatus newStatus) {
    state = state.rebuild(
      (b) => b
        ..words.rebuildAt(
          wordId,
          (b) => b..status = newStatus,
        ),
    );
  }

  void setWordFeedback(int wordId, WordFeedback newFeedback) {
    state = state.rebuild(
      (b) => b
        ..words.rebuildAt(
          wordId,
          (b) => b..feedback = newFeedback,
        ),
    );
  }

  void initTurn() {
    state = state.rebuild(
      (b) => b
        ..turnPhase = TurnPhase.prepare
        ..currentParty.replace(
            PartyingStrategy.fromGame(config, state).getParty(state.turn)),
    );
  }

  void finishTurn() {
    final List<int> wordsScored = state.wordsInThisTurn
        .where((w) => state.words[w].status == WordStatus.explained)
        .toList();
    state = state.rebuild(
      (b) => b
        ..turnPhase = null
        ..players.map((p) {
          if (state.currentParty.performer == p.id) {
            return p.rebuild((b) => b..wordsExplained.addAll(wordsScored));
          } else if (state.currentParty.recipients.contains(p.id)) {
            return p.rebuild((b) => b..wordsGuessed.addAll(wordsScored));
          }
          return p;
        })
        ..wordsInHat.addAll(state.wordsInThisTurn
            .where((w) => b.words[w].status == WordStatus.notExplained))
        ..wordsInThisTurn.clear(),
    );
  }

  void drawNextWord() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    if (state.wordsInHat.isEmpty) {
      finishExplanation();
      return;
    }
    final int nextWord =
        state.wordsInHat[Random().nextInt(state.wordsInHat.length)];
    Assert.holds(state.wordsInHat.contains(nextWord),
        lazyMessage: () => state.wordsInHat.toString());
    state = state.rebuild(
      (b) => b
        ..currentWord = nextWord
        ..wordsInThisTurn.add(nextWord)
        ..wordsInHat.remove(nextWord),
    );
  }
}

class GameController {
  final LocalGameData localGameData;
  GameConfig config;
  // TODO: Should UI be able to get state from here or only from the stream?
  GameState state;
  final localState = LocalGameState();
  final _streamController = StreamController<GameData>(sync: true);

  Stream<GameData> get stateUpdatesStream => _streamController.stream;

  GameData get _gameData => GameData(config, state, localState);
  GameTransformer get _transformer => GameTransformer(config, state);

  // Since isInitialzied becomes true:
  //   - config and state are guaranteed to be non-null,
  //   - config doesn't change,
  //   - isInitialzied stays true,
  //   - stateUpdatesStream starts sending updates.
  bool get isInitialzied => config != null;

  bool get isActivePlayer =>
      state == null ? false : activePlayer(state) == localGameData.myPlayerID;

  static String generateNewGameID() {
    return Random().nextInt(10000).toString().padLeft(4, '0');
  }

  static DocumentReference gameReferenceFromGameID(String gameId) {
    return Firestore.instance.collection('games').document(gameId);
  }

  static int activePlayer(GameState state) => state.currentParty.performer;

  static Future<LocalGameData> newLobby(String myName) async {
    const int maxAttempts = 1000;
    // TODO: Use config from local storage OR from account.
    final GameConfig config = GameConfigController.defaultConfig();
    final String serialized = json.encode(serializers.serialize(config));
    String gameID;
    DocumentReference reference;
    final int playerID = 0;
    await Firestore.instance.runTransaction((Transaction tx) async {
      for (int iter = 0; iter < maxAttempts; iter++) {
        gameID = generateNewGameID();
        reference = gameReferenceFromGameID(gameID);
        DocumentSnapshot snapshot = await tx.get(reference);
        if (!snapshot.exists) {
          await tx.set(reference, <String, dynamic>{
            DBColumns.config: serialized,
            DBColumns.player(playerID): myName
          });
          return;
        }
      }
      throw InvalidOperation('Cannot generate game ID', isInternalError: true);
    });
    return LocalGameData(
      gameID: gameID,
      gameReference: reference,
      myPlayerID: playerID,
    );
  }

  static Future<LocalGameData> joinLobby(String myName, String gameID) async {
    // TODO: Check if the game has already started.
    final DocumentReference reference = gameReferenceFromGameID(gameID);
    int playerID = 0;
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        throw InvalidOperation("Game $gameID doesn't exist");
      }
      while (snapshot.data.containsKey(DBColumns.player(playerID))) {
        if (myName == snapshot.data[DBColumns.player(playerID)]) {
          throw InvalidOperation("Name $myName is already taken");
        }
        playerID++;
      }
      await tx.update(reference,
          <String, dynamic>{'player-' + playerID.toString(): myName});
    });
    return LocalGameData(
      gameID: gameID,
      gameReference: reference,
      myPlayerID: playerID,
    );
  }

  // Writes state asynchronously.
  static void startGame(DocumentReference reference, GameConfig config) {
    Assert.ne(config.players.names == null, config.players.namesByTeam == null);
    List<String> playerNames;
    List<List<int>> teams;
    if (config.teaming.teamPlay) {
      List<int> teamSizes;
      if (config.players.namesByTeam != null) {
        // Shuffle names within teams. Teams themselves are shuffled later.
        final List<List<String>> namesByTeamShuffled = config
            .players.namesByTeam
            .map((t) => t.toList().shuffled())
            .toList();
        playerNames = namesByTeamShuffled.expand((t) => t).toList();
        teamSizes = namesByTeamShuffled.map((t) => t.length).toList();
      } else {
        playerNames = config.players.names.toList().shuffled();
        teamSizes = generateTeamSizes(playerNames.length,
            config.teaming.desiredTeamSize, config.teaming.unequalTeamSize);
      }
      teams = generateTeamPlayers(teamSizes).shuffled();
    } else {
      Assert.holds(config.players.names != null);
      if (config.players.names.length < 2) {
        throw InvalidOperation('At least two players are required');
      }
      playerNames = config.players.names.toList().shuffled();
    }

    final players = List<PlayerState>();
    for (final name in playerNames) {
      players.add(PlayerState(
        (b) => b
          ..id = players.length
          ..name = name,
      ));
    }

    final int totalWords = config.rules.wordsPerPlayer * players.length;
    final words = List<Word>();
    while (words.length < totalWords) {
      final String text =
          russian_words.nouns[Random().nextInt(russian_words.nouns.length)];
      if (text.toLowerCase() != text) {
        continue;
      }
      words.add(Word((b) => b
        ..id = words.length
        ..text = text
        ..status = WordStatus.notExplained));
    }

    GameState initialState = GameState(
      (b) => b
        ..players.replace(players)
        ..words.replace(words)
        ..wordsInHat.replace(words.map((w) => w.id))
        ..turn = 0
        ..gameFinished = false,
    );
    if (teams != null) {
      // TODO: Is there a way to do this concisely in one builder?
      initialState = initialState
          .rebuild((b) => b.teams.replace(teams.map((t) => BuiltList<int>(t))));
    }
    initialState = (GameTransformer(config, initialState)..initTurn()).state;
    // In addition to initial state, write the config:
    //   - just to be sure;
    //   - to fill in players field.  // TODO: Better solution for this?
    _writeInitialState(reference, config, initialState);
  }

  void _onUpdateFromDB(final DocumentSnapshot snapshot) {
    Assert.holds(snapshot.data != null);
    final bool wasInitialzied = isInitialzied;
    if (!isInitialzied) {
      final GameConfigReadResult configReadResult =
          GameConfigController.configFromSnapshot(snapshot);
      if (!configReadResult.gameHasStarted ||
          !snapshot.data.containsKey(DBColumns.state)) {
        return;
      }
      // This is the one and only place where the config changes.
      config = configReadResult.config;
    }

    if (!snapshot.data.containsKey(DBColumns.state)) {
      Assert.fail('Game state not found');
    }
    GameState newState =
        serializers.deserialize(json.decode(snapshot.data[DBColumns.state]));
    if (isActivePlayer) {
      Assert.holds(wasInitialzied);
      final int newActivePlayer = activePlayer(newState);
      Assert.eq(localGameData.myPlayerID, newActivePlayer,
          message: 'Active player unexpectedly changed from '
              '${localGameData.myPlayerID} to $newActivePlayer');
      // Ignore the update, because the state of truth is on the client while
      // we are the active player.
    } else {
      state = newState;
      _streamController.add(_gameData);
    }
  }

  GameController.fromFirestore(this.localGameData) {
    localGameData.gameReference.snapshots().listen(
      _onUpdateFromDB,
      onError: (error) {
        Assert.fail('Got error from Firestore: ' + error.toString());
      },
      onDone: () {
        Assert.fail('Firestore updates stream aborted');
      },
    );
  }

  static Future<void> _writeInitialState(DocumentReference reference,
      GameConfig config, GameState initialState) async {
    final serializedConfig = json.encode(serializers.serialize(config));
    final serializedState = json.encode(serializers.serialize(initialState));
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot snapshot = await tx.get(reference);
      Assert.holds(snapshot.exists,
          lazyMessage: () => 'Game doesn\'t exist: ' + reference.path);
      Assert.holds(!snapshot.data.containsKey(DBColumns.state),
          lazyMessage: () => 'Game state already exists: ' + reference.path);
      await tx.update(reference, {
        DBColumns.config: serializedConfig,
        DBColumns.state: serializedState,
      });
    });
  }

  void _updateState(GameState newState) {
    Assert.holds(isActivePlayer,
        message: 'Only active player should change game state');
    final serialized = json.encode(serializers.serialize(newState));
    localGameData.gameReference.updateData({DBColumns.state: serialized});
    state = newState;
    _streamController.add(_gameData);
  }

  void nextTurn() {
    _updateState((_transformer..nextTurn()).state);
  }

  void startExplaning() {
    _updateState((_transformer..startExplaning()).state);
  }

  void wordGuessed() {
    _updateState((_transformer..wordGuessed()).state);
  }

  void finishExplanation() {
    _updateState((_transformer..finishExplanation()).state);
  }

  void setWordStatus(int wordId, WordStatus newStatus) {
    _updateState((_transformer..setWordStatus(wordId, newStatus)).state);
  }

  void setWordFeedback(int wordId, WordFeedback newFeedback) {
    _updateState((_transformer..setWordFeedback(wordId, newFeedback)).state);
  }
}
