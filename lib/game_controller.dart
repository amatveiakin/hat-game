import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/built_value_ext.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/list_ext.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:russian_words/russian_words.dart' as russian_words;

// All functions that don't end with `NoUpdate`, both public and private,
// update the state.
// TODO: Find a cleaner to avoid sequential calls. Note that avoiding
// sequential calls is important: it's not only a performance, but also a
// correctness problems, because users could see intermediate state.

class GameController {
  final GameConfig config;
  // TODO: Should UI be able to get state from here or only from the stream?
  GameState state;
  DocumentReference reference;

  GameData get gameData => GameData(config, state);

  // TODO: Don't create a throwaway class instance.
  GameController.newGame(this.config) {
    final words = List<Word>();
    while (words.length < 5) {
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

    state = GameState(
      (b) => b
        ..players.replace(players)
        ..words.replace(words)
        ..wordsInHat.replace(words.map((w) => w.id))
        ..turn = 0
        ..gameFinished = false,
    );
    if (teams != null) {
      // TODO: Is there a way to do this concisely in one builder?
      state = state
          .rebuild((b) => b.teams.replace(teams.map((t) => BuiltList<int>(t))));
    }
    _updateConfig();
    _initTurn();
  }

  GameController.fromSnapshot(final DocumentSnapshot documentSnapshot)
      : config = serializers
            .deserialize(json.decode(documentSnapshot.data['config'])),
        state = serializers
            .deserialize(json.decode(documentSnapshot.data['state'])),
        reference = documentSnapshot.reference;

  // TODO: Find a cleaner to avoid sequential calls. Note that avoiding
  // sequential calls is important: it's not only a performance, but also a
  // correctness problems, because users could see intermediate state.
  void _updateConfig() {
    final serialized = json.encode(serializers.serialize(config));
    Firestore.instance
        .collection('games')
        .document('test')
        .updateData({'config': serialized});
  }

  void _setState(GameState newState) {
    state = newState;
    _updateState();
  }

  void _updateState() {
    final serialized = json.encode(serializers.serialize(state));

    if (reference != null) {
      // TODO: Make this a transaction!
      reference.updateData({'state': serialized});
    } else {
      Firestore.instance
          .collection('games')
          .document('test')
          .updateData({'state': serialized});
    }
  }

  void nextTurn() {
    Assert.eq(state.turnPhase, TurnPhase.review);
    _finishTurnNoUpdate();
    if (state.wordsInHat.length == 0) {
      Assert.holds(!state.gameFinished);
      _setState(state.rebuild(
        (b) => b..gameFinished = true,
      ));
    } else {
      state = state.rebuild(
        (b) => b..turn = state.turn + 1,
      );
      _initTurn();
    }
  }

  void startExplaning() {
    Assert.eq(state.turnPhase, TurnPhase.prepare);
    state = state.rebuild(
      (b) => b..turnPhase = TurnPhase.explain,
    );
    _drawNextWord();
  }

  void wordGuessed() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    Assert.holds(state.wordsInThisTurn.isNotEmpty);
    Assert.eq(state.wordsInThisTurn.last, state.currentWord);
    _setWordStatusNoUpdate(state.currentWord, WordStatus.explained);
    _drawNextWord();
  }

  void finishExplanation() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    _setState(state.rebuild(
      (b) => b..turnPhase = TurnPhase.review,
    ));
  }

  void setWordStatus(int wordId, WordStatus newStatus) {
    _setWordStatusNoUpdate(wordId, newStatus);
    _updateState();
  }

  void setWordFeedback(int wordId, WordFeedback newFeedback) {
    _setState(state.rebuild(
      (b) => b
        ..words.rebuildAt(
          wordId,
          (b) => b..feedback = newFeedback,
        ),
    ));
  }

  void _initTurn() {
    _setState(state.rebuild(
      (b) => b
        ..turnPhase = TurnPhase.prepare
        ..currentParty
            .replace(PartyingStrategy.fromGame(gameData).getParty(state.turn)),
    ));
  }

  void _finishTurnNoUpdate() {
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

  void _setWordStatusNoUpdate(int wordId, WordStatus newStatus) {
    state = state.rebuild(
      (b) => b
        ..words.rebuildAt(
          wordId,
          (b) => b..status = newStatus,
        ),
    );
  }

  void _drawNextWord() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    if (state.wordsInHat.isEmpty) {
      finishExplanation();
      return;
    }
    final int nextWord =
        state.wordsInHat[Random().nextInt(state.wordsInHat.length)];
    Assert.holds(state.wordsInHat.contains(nextWord),
        lazyMessage: () => state.wordsInHat.toString());
    _setState(state.rebuild(
      (b) => b
        ..currentWord = nextWord
        ..wordsInThisTurn.add(nextWord)
        ..wordsInHat.remove(nextWord),
    ));
  }
}
