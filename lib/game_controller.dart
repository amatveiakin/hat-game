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
import 'package:hatgame/util/firestore.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:russian_words/russian_words.dart' as russian_words;

class GameTransformer {
  final GameConfig config;
  GameState state;

  GameData get gameData => GameData(config, state);

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
        ..currentParty
            .replace(PartyingStrategy.fromGame(gameData).getParty(state.turn)),
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
  final DocumentReference gameReference;
  final GameConfig config;
  // TODO: Should UI be able to get state from here or only from the stream?
  GameState state;

  GameData get gameData => GameData(config, state);
  GameTransformer get _transformer => GameTransformer(config, state);

  static String generateNewGameID() {
    return Random().nextInt(10000).toString().padLeft(4, '0');
  }

  static DocumentReference gameReferenceFromGameID(String gameId) {
    return Firestore.instance.collection('games').document(gameId);
  }

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
      throw Exception('Cannot generate game ID');
    });
    return LocalGameData(
      gameID: gameID,
      gameReference: reference,
      myPlayerID: playerID,
    );
  }

  static Future<LocalGameData> joinLobby(String myName, String gameID) async {
    final DocumentReference reference = gameReferenceFromGameID(gameID);
    int playerID = 0;
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        // TODO: Catch this and show a proper error message.
        throw Exception('Game doesn\'t exist');
      }
      // TODO: Check that player name is unique.
      while (snapshot.data.containsKey('player-' + playerID.toString())) {
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
  static void startGame(
      DocumentReference reference, GameConfig config) {
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
      // TODO: Forbid games with a single players.
      Assert.holds(config.players.names != null);
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

  GameController._(this.gameReference, this.config, this.state);

  factory GameController.fromSnapshot(final DocumentSnapshot documentSnapshot) {
    final GameConfigReadResult configReadResult =
        GameConfigController.configFromSnapshot(documentSnapshot);
    if (!configReadResult.gameHasStarted ||
        !documentSnapshot.data.containsKey(DBColumns.state)) {
      return null;
    }
    final GameState state = serializers
        .deserialize(json.decode(documentSnapshot.data[DBColumns.state]));
    return GameController._(
        documentSnapshot.reference, configReadResult.config, state);
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
    FirestoreUtil.atomicUpdateColumn(
        gameReference, DBColumns.state, state, newState);
    state = newState;
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
