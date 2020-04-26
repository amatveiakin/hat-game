import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/built_value_ext.dart';
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
  final GameConfig config;
  // TODO: Should UI be able to get state from here or only from the stream?
  GameState state;
  DocumentReference reference;

  GameData get gameData => GameData(config, state);
  GameTransformer get _transformer => GameTransformer(config, state);

  static void newGame(GameConfig config) {
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
    _writeConfig(config);
    _writeInitialState(
        (GameTransformer(config, initialState)..initTurn()).state);
  }

  GameController.fromSnapshot(final DocumentSnapshot documentSnapshot)
      : config = serializers
            .deserialize(json.decode(documentSnapshot.data['config'])),
        state = serializers
            .deserialize(json.decode(documentSnapshot.data['state'])),
        reference = documentSnapshot.reference;

  static void _writeConfig(GameConfig config) {
    // TODO: Use a transaction to make sure the config doesn't exist yet.
    final serialized = json.encode(serializers.serialize(config));
    Firestore.instance
        .collection('games')
        .document('test')
        .updateData({'config': serialized});
  }

  static void _writeInitialState(GameState initialState) {
    // TODO: Use a transaction to make sure the state doesn't exist yet.
    final serialized = json.encode(serializers.serialize(initialState));
    Firestore.instance
        .collection('games')
        .document('test')
        .updateData({'state': serialized});
  }

  void _updateState(GameState newState) {
    final oldStateSerialized = json.encode(serializers.serialize(state));
    final newStateSerialized = json.encode(serializers.serialize(newState));
    Assert.holds(reference != null);
    Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot postSnapshot = await tx.get(reference);
      final dbState = postSnapshot.data['state'];
      Assert.holds(dbState == oldStateSerialized,
          lazyMessage: () =>
              'Race condition detected!' +
              ('\nState in DB :\n' + dbState) +
              ('\nOld state in the App:\n' + oldStateSerialized) +
              ('\nNew state in the App:\n' + newStateSerialized),
          inRelease: AssertInRelease.log);
      await tx
          .update(reference, <String, dynamic>{'state': newStateSerialized});
    });
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
