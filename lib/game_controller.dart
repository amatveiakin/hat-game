import 'dart:async';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hatgame/app_version.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db_columns.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/built_value_ext.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/strings.dart';
import 'package:russian_words/russian_words.dart' as russian_words;
import 'package:unicode/unicode.dart' as unicode;

class GameStateTransformer {
  final GameConfig config;
  GameState state;

  GameStateTransformer(this.config, this.state);

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
      (b) => b
        ..turnPhase = TurnPhase.explain
        ..turnPaused = false
        ..turnTimeBeforePause = Duration.zero
        ..turnTimeStart = NtpTime.nowUtc(),
    );
    drawNextWord();
  }

  void pauseExplaning() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    Assert.holds(!state.turnPaused);
    state = state.rebuild((b) => b
      ..turnPaused = true
      ..turnTimeBeforePause = state.turnTimeBeforePause +
          (NtpTime.nowUtc().difference(state.turnTimeStart)));
  }

  void resumeExplaning() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    Assert.holds(state.turnPaused);
    state = state.rebuild(
      (b) => b
        ..turnPaused = false
        ..turnTimeStart = NtpTime.nowUtc(),
    );
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
      (b) => b
        ..turnPhase = TurnPhase.review
        ..turnPaused = null
        ..turnTimeBeforePause = null
        ..turnTimeStart = null
        ..bonusTimeStart = NtpTime.nowUtc(),
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

class PersonalStateTransformer {
  PersonalState personalState;

  PersonalStateTransformer(this.personalState);

  void setWordFeedback(int wordId, WordFeedback newFeedback) {
    final wordFeedback = personalState.wordFeedback.toMap();
    if (newFeedback != null) {
      wordFeedback[wordId] = newFeedback;
    } else {
      wordFeedback.remove(wordId);
    }
    personalState =
        personalState.rebuild((b) => b..wordFeedback.replace(wordFeedback));
  }

  void setWordFlag(int wordId, bool hasFlag) {
    final wordFlags = personalState.wordFlags.toSet();
    if (hasFlag) {
      wordFlags.add(wordId);
    } else {
      wordFlags.remove(wordId);
    }
    personalState =
        personalState.rebuild((b) => b..wordFlags.replace(wordFlags));
  }
}

class GameController {
  final LocalGameData localGameData;
  GameConfig config;
  // TODO: Should UI be able to get state from here or only from the stream?
  GameState state;
  DerivedGameState derivedState;
  PersonalState personalState;
  final localState = LocalGameState();
  final _streamController = StreamController<GameData>(sync: true);

  Stream<GameData> get stateUpdatesStream => _streamController.stream;

  GameData get _gameData =>
      GameData(config, state, derivedState, personalState, localState);
  GameStateTransformer get _transformer => GameStateTransformer(config, state);
  PersonalStateTransformer get _personalTransformer =>
      PersonalStateTransformer(personalState);

  // Since isInitialized becomes true:
  //   - config, state, derivedState and personalState are always non-null,
  //   - config doesn't change,
  //   - isInitialized stays true,
  //   - stateUpdatesStream starts sending updates.
  bool get isInitialized => config != null;

  bool get isActivePlayer =>
      state == null ? false : activePlayer(state) == localGameData.myPlayerID;

  static String generateNewGameID(int length, String prefix) {
    return prefix +
        Random().nextInt(pow(10, length)).toString().padLeft(length, '0');
  }

  static DocumentReference gameReferenceFromGameID(String gameId) {
    return Firestore.instance.collection('games').document(gameId);
  }

  static int activePlayer(GameState state) => state.currentParty.performer;

  static void checkPlayerNameIsValid(String name) {
    if (name.isEmpty) {
      throw InvalidOperation('Player name is empty');
    }
    if (name.length > 50) {
      throw InvalidOperation('Player name too long');
    }
    for (final c in name.codeUnits) {
      if (unicode.isControl(c) || unicode.isFormat(c)) {
        throw InvalidOperation('Player name contans invalid character: '
            '${String.fromCharCode(c)} (code $c)');
      }
    }
  }

  static void checkVersionCompatibility(
      String hostVersion, String clientVersion) {
    if (isNullOrEmpty(hostVersion)) {
      throw InvalidOperation('Unknown host version', isInternalError: true);
    }
    if (isNullOrEmpty(clientVersion)) {
      throw InvalidOperation('Unknown client version', isInternalError: true);
    }
    if (!versionsCompatibile(hostVersion, clientVersion)) {
      throw InvalidOperation('Incompatible game version. '
          'Host version: $hostVersion, local version: $clientVersion');
    }
  }

  static Future<LocalGameData> newLobby(String myName) async {
    checkPlayerNameIsValid(myName);
    const int minIDLength = 4;
    const int maxIDLength = 8;
    const int attemptsPerTransaction = 100;
    final String idPrefix = kReleaseMode ? '' : '.';
    // TODO: Use config from local storage OR from account.
    final GameConfig config = GameConfigController.defaultConfig();
    String gameID;
    DocumentReference reference;
    final int playerID = 0;
    for (int idLength = minIDLength;
        idLength <= maxIDLength && gameID == null;
        idLength++) {
      await Firestore.instance.runTransaction((Transaction tx) async {
        for (int iter = 0; iter < attemptsPerTransaction; iter++) {
          gameID = generateNewGameID(idLength, idPrefix);
          reference = gameReferenceFromGameID(gameID);
          DocumentSnapshot snapshot = await tx.get(reference);
          if (!snapshot.exists) {
            await tx.set(
                reference,
                dbData([
                  DBColCreationTimeUtc().setData(NtpTime.nowUtc().toString()),
                  DBColHostAppVersion().setData(appVersion),
                  DBColConfig().setData(config),
                  DBColPlayer(playerID).setData(PersonalState((b) => b
                    ..id = playerID
                    ..name = myName)),
                ]));
            return;
          }
        }
        gameID = null;
      });
    }
    if (gameID == null) {
      throw InvalidOperation('Cannot generate game ID', isInternalError: true);
    }
    return LocalGameData(
      gameID: gameID,
      gameReference: reference,
      myPlayerID: playerID,
    );
  }

  static Future<LocalGameData> joinLobby(String myName, String gameID) async {
    checkPlayerNameIsValid(myName);
    // TODO: Check if the game has already started.
    final DocumentReference reference = gameReferenceFromGameID(gameID);

    if (!(await reference.get()).exists) {
      // [1/2] Workaround flutter/firestore error:
      //     E/flutter ( 6075): [ERROR:flutter/lib/ui/ui_dart_state.cc(157)]
      //         Unhandled Exception: PlatformException(Error performing
      //         transaction, Every document read in a transaction must also
      //         be written., null)
      // Check if the document exists beforehand. This is not 100% safe if
      // the documents can be deleted (which may be the case), but I don't
      // see what else we can do.
      // TODO: Remove the workaround whe the bug is fixed.
      throw InvalidOperation("Game $gameID doesn't exist");
    }

    // TODO: Adhere to best practices: get `playerID` as a return value from
    // runTransaction. I tried doing this, but unfortunately ran into
    // https://github.com/flutter/flutter/issues/17663. Note: the issue was
    // already marked as closed, but for me it still crashed with:
    //     Unhandled Exception: PlatformException(Error performing transaction,
    //         java.lang.Exception: DoTransaction failed: Invalid argument:
    //         Instance of '_CompactLinkedHashSet<Object>', null)
    int playerID = 0;
    // For some reason, throwing from `runTransaction` doesn't work. Got:
    //     Unhandled Exception: PlatformException(Error performing transaction,
    //         java.lang.Exception: DoTransaction failed: Instance of
    //         'InvalidOperation', null)
    InvalidOperation error;

    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        error = InvalidOperation("Game $gameID doesn't exist");
        return;
      }
      {
        // [2/2] Workaround flutter/firestore error. Do a dumb write.
        await tx.set(reference, snapshot.data);
      }
      try {
        checkVersionCompatibility(
            dbTryGet(snapshot, DBColHostAppVersion()), appVersion);
      } on InvalidOperation catch (e) {
        error = e;
        return;
      }
      while (dbContains(snapshot, DBColPlayer(playerID))) {
        if (myName == dbGet(snapshot, DBColPlayer(playerID)).name) {
          error = InvalidOperation("Name $myName is already taken");
          return;
        }
        playerID++;
      }
      await tx.update(
          reference,
          dbData([
            DBColPlayer(playerID).setData(PersonalState((b) => b
              ..id = playerID
              ..name = myName))
          ]));
    });

    if (error != null) {
      throw error;
    }

    return LocalGameData(
      gameID: gameID,
      gameReference: reference,
      myPlayerID: playerID,
    );
  }

  // Writes state asynchronously.
  static void startGame(DocumentReference reference, GameConfig config) {
    final numPlayers = config.players.names.length;
    BuiltList<BuiltList<int>> teams;
    BuiltList<int> individualOrder;
    if (config.teaming.teamPlay) {
      if (config.players.teams != null) {
        teams = BuiltList<BuiltList<int>>.from(config.players.teams
            .map((team) => team.toList().shuffled())
            .toList()
            .shuffled());
      } else {
        final List<int> teamSizes = generateTeamSizes(numPlayers,
            config.teaming.desiredTeamSize, config.teaming.unequalTeamSize);
        final teamsMutable = generateTeamPlayers(
            playerIDs: config.players.names.keys.toList().shuffled(),
            teamSizes: teamSizes.shuffled());
        teams = BuiltList<BuiltList<int>>.from(
            teamsMutable.map((t) => BuiltList<int>(t)));
      }
    } else {
      Assert.holds(config.players.teams == null);
      checkNumPlayersForIndividualPlay(
          numPlayers, config.teaming.individualPlayStyle);
      individualOrder = BuiltList<int>.from(
          List<int>.generate(numPlayers, (i) => i).shuffled());
    }

    final players = BuiltList<PlayerState>.from(
      config.players.names.entries.map((entry) => PlayerState(
            (b) => b
              ..id = entry.key
              ..name = entry.value,
          )),
    );

    final int totalWords = config.rules.wordsPerPlayer * numPlayers;
    final words = List<Word>();
    while (words.length < totalWords) {
      final String text =
          russian_words.nouns[Random().nextInt(russian_words.nouns.length)];
      // This dictionary contains a lot of words with diminutive sufficies -
      // try to filter them out. This will also throw away some legit words,
      // but that's ok. Eventually we'll find a better dictionary.
      if (text.toLowerCase() != text ||
          text.endsWith('ик') ||
          text.endsWith('ек') ||
          text.endsWith('ок')) {
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
        ..individualOrder =
            (individualOrder != null ? ListBuilder(individualOrder) : null)
        ..teams = (teams != null ? ListBuilder(teams) : null)
        ..words.replace(words)
        ..wordsInHat.replace(words.map((w) => w.id))
        ..turn = 0
        ..gameFinished = false,
    );
    initialState =
        (GameStateTransformer(config, initialState)..initTurn()).state;
    // In addition to initial state, write the config:
    //   - just to be sure;
    //   - to fill in players field.  // TODO: Better solution for this?
    _writeInitialState(reference, config, initialState);
  }

  Map<int, PersonalState> _parsePersonalStates(
      final DocumentSnapshot snapshot) {
    final states = Map<int, PersonalState>();
    int playerID = 0;
    while (dbContains(snapshot, DBColPlayer(playerID))) {
      states[playerID] = dbGet(snapshot, DBColPlayer(playerID));
      playerID++;
    }
    return states;
  }

  DerivedGameState _makeDerivedGameState(
      Map<int, PersonalState> personalStates) {
    final flaggedWords = Set<int>();
    for (final st in personalStates.values) {
      flaggedWords.addAll(st.wordFlags);
    }
    return DerivedGameState(flaggedWords: BuiltSet.from(flaggedWords));
  }

  void _onUpdateFromDB(final DocumentSnapshot snapshot) {
    Assert.holds(snapshot.data != null);
    final bool wasInitialized = isInitialized;
    if (!isInitialized) {
      final GameConfigReadResult configReadResult =
          GameConfigController.configFromSnapshot(snapshot);
      if (!configReadResult.gameHasStarted ||
          !dbContains(snapshot, DBColState())) {
        return;
      }
      // This is the one and only place where the config changes.
      config = configReadResult.configWithOverrides;
    }

    if (!dbContains(snapshot, DBColState())) {
      Assert.fail('Game state not found');
    }

    GameState newState = dbGet(snapshot, DBColState());
    if (isActivePlayer) {
      Assert.holds(wasInitialized);
      final int newActivePlayer = activePlayer(newState);
      Assert.eq(localGameData.myPlayerID, newActivePlayer,
          message: 'Active player unexpectedly changed from '
              '${localGameData.myPlayerID} to $newActivePlayer');
      // Ignore the update, because the state of truth is on the client while
      // we are the active player.
    } else {
      state = newState;
    }

    final personalStates = _parsePersonalStates(snapshot);
    derivedState = _makeDerivedGameState(personalStates);
    Assert.holds(personalStates.containsKey(localGameData.myPlayerID));
    personalState = personalStates[localGameData.myPlayerID];

    _streamController.add(_gameData);
  }

  GameController.fromFirestore(this.localGameData) {
    localGameData.gameReference.snapshots().listen(
      _onUpdateFromDB,
      onError: (error) {
        Assert.fail('GameController: Firestore error: $error');
      },
      onDone: () {
        Assert.fail('GameController: Firestore updates stream aborted');
      },
    );
  }

  static Future<void> _writeInitialState(DocumentReference reference,
      GameConfig config, GameState initialState) async {
    await Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot snapshot = await tx.get(reference);
      Assert.holds(snapshot.exists,
          lazyMessage: () => 'Game doesn\'t exist: ' + reference.path);
      Assert.holds(!dbContains(snapshot, DBColState()),
          lazyMessage: () => 'Game state already exists: ' + reference.path);
      await tx.update(
          reference,
          dbData([
            DBColConfig().setData(config),
            DBColState().setData(initialState),
          ]));
    });
  }

  void _updateState(GameState newState) {
    Assert.holds(isActivePlayer,
        message: 'Only active player should change game state');
    localGameData.gameReference
        .updateData(dbData([DBColState().setData(newState)]));
    state = newState;
    _streamController.add(_gameData);
  }

  void _updatePersonalState(PersonalState newState) {
    localGameData.gameReference.updateData(
        dbData([DBColPlayer(localGameData.myPlayerID).setData(newState)]));
    personalState = newState;
    _streamController.add(_gameData);
  }

  void nextTurn() {
    _updateState((_transformer..nextTurn()).state);
  }

  void startExplaning() {
    _updateState((_transformer..startExplaning()).state);
  }

  void pauseExplaning() {
    _updateState((_transformer..pauseExplaning()).state);
  }

  void resumeExplaning() {
    _updateState((_transformer..resumeExplaning()).state);
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
    _updatePersonalState((_personalTransformer
          ..setWordFeedback(wordId, newFeedback))
        .personalState);
  }

  void setWordFlag(int wordId, bool hasFlag) {
    _updatePersonalState(
        (_personalTransformer..setWordFlag(wordId, hasFlag)).personalState);
  }
}
