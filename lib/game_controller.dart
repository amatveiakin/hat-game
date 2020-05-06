import 'dart:async';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:hatgame/app_version.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/db/db_firestore.dart';
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

  bool get isActivePlayer => state == null
      ? false
      : (localGameData.onlineMode
          ? activePlayer(state) == localGameData.myPlayerID
          : true);

  static List<DBColumnData> _newGameRecord() {
    return [
      DBColCreationTimeUtc().withData(NtpTime.nowUtc().toString()),
      DBColHostAppVersion().withData(appVersion),
    ];
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

  static Future<LocalGameData> newOffineGame() async {
    DBDocumentReference reference = newLocalGameReference();
    await reference.delete();
    final GameConfig config = GameConfigController.defaultConfig().rebuild(
      (b) => b.players.names.replace({}),
    );
    await reference.setColumns(
      _newGameRecord() +
          [
            DBColConfig().withData(config),
            DBColLocalPlayer().withData(PersonalState((b) => b
              ..id = 0
              ..name = 'fake')),
          ],
    );
    return LocalGameData(
      onlineMode: false,
      gameReference: reference,
    );
  }

  static Future<LocalGameData> newLobby(String myName) async {
    checkPlayerNameIsValid(myName);
    const int minIDLength = 4;
    const int maxIDLength = 8;
    const int attemptsPerTransaction = 100;
    final String idPrefix = kReleaseMode ? '' : '.';
    String gameID;
    firestore.DocumentReference reference;
    final int playerID = 0;
    // TODO: Use config from local storage OR from account.
    final GameConfig config = GameConfigController.defaultConfig();
    final gameRecordStub = _newGameRecord();
    for (int idLength = minIDLength;
        idLength <= maxIDLength && gameID == null;
        idLength++) {
      await firestore.Firestore.instance
          .runTransaction((firestore.Transaction tx) async {
        for (int iter = 0; iter < attemptsPerTransaction; iter++) {
          gameID = newFirestoreGameID(idLength, idPrefix);
          reference = firestoreGameReference(gameID: gameID);
          firestore.DocumentSnapshot snapshot = await tx.get(reference);
          if (!snapshot.exists) {
            await tx.set(
                reference,
                dbData(gameRecordStub +
                    [
                      DBColConfig().withData(config),
                      DBColPlayer(playerID).withData(PersonalState((b) => b
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
      onlineMode: true,
      gameID: gameID,
      gameReference: FirestoreDocumentReference(reference),
      myPlayerID: playerID,
    );
  }

  static Future<LocalGameData> joinLobby(String myName, String gameID) async {
    checkPlayerNameIsValid(myName);
    // TODO: Check if the game has already started.
    final firestore.DocumentReference reference =
        firestoreGameReference(gameID: gameID);

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

    await firestore.Firestore.instance
        .runTransaction((firestore.Transaction tx) async {
      firestore.DocumentSnapshot snapshot = await tx.get(reference);
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
            dbTryGet(snapshot.data, DBColHostAppVersion()), appVersion);
      } on InvalidOperation catch (e) {
        error = e;
        return;
      }
      while (dbContains(snapshot.data, DBColPlayer(playerID))) {
        if (myName == dbGet(snapshot.data, DBColPlayer(playerID)).name) {
          error = InvalidOperation("Name $myName is already taken");
          return;
        }
        playerID++;
      }
      await tx.update(
          reference,
          dbData([
            DBColPlayer(playerID).withData(PersonalState((b) => b
              ..id = playerID
              ..name = myName))
          ]));
    });

    if (error != null) {
      throw error;
    }

    return LocalGameData(
      onlineMode: true,
      gameID: gameID,
      gameReference: FirestoreDocumentReference(reference),
      myPlayerID: playerID,
    );
  }

  static Future<void> startGame(
      DBDocumentReference reference, GameConfig config) {
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
    return _writeInitialState(reference, config, initialState);
  }

  Map<int, PersonalState> _parsePersonalStates(
      final DBDocumentSnapshot snapshot) {
    final states = Map<int, PersonalState>();
    int playerID = 0;
    while (snapshot.contains(DBColPlayer(playerID))) {
      states[playerID] = snapshot.get(DBColPlayer(playerID));
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

  void _onUpdateFromDB(final DBDocumentSnapshot snapshot) {
    Assert.holds(snapshot.exists);
    final bool wasInitialized = isInitialized;
    if (!isInitialized) {
      final GameConfigReadResult configReadResult =
          GameConfigController.configFromSnapshot(localGameData, snapshot);
      if (!snapshot.contains(DBColState())) {
        return;
      }
      // This is the one and only place where the config changes.
      config = configReadResult.configWithOverrides;
    }

    GameState newState = snapshot.get(DBColState());
    if (isActivePlayer) {
      Assert.holds(wasInitialized);
      if (localGameData.onlineMode) {
        final int newActivePlayer = activePlayer(newState);
        Assert.eq(localGameData.myPlayerID, newActivePlayer,
            message: 'Active player unexpectedly changed from '
                '${localGameData.myPlayerID} to $newActivePlayer');
      }
      // Ignore the update, because the state of truth is on the client while
      // we are the active player.
    } else {
      state = newState;
    }

    if (localGameData.onlineMode) {
      final personalStates = _parsePersonalStates(snapshot);
      derivedState = _makeDerivedGameState(personalStates);
      Assert.holds(personalStates.containsKey(localGameData.myPlayerID));
      personalState = personalStates[localGameData.myPlayerID];
    } else {
      personalState = snapshot.get(DBColLocalPlayer());
      derivedState = _makeDerivedGameState({personalState.id: personalState});
    }

    _streamController.add(_gameData);
  }

  GameController.fromDB(this.localGameData) {
    localGameData.gameReference.snapshots().listen(
      _onUpdateFromDB,
      onError: (error) {
        Assert.fail('GameController: DB error: $error');
      },
      onDone: () {
        Assert.fail('GameController: DB updates stream aborted');
      },
    );
  }

  Future<void> testAwaitInitialized() {
    return Future.doWhile(() async => !isInitialized);
  }

  static Future<void> _writeInitialState(DBDocumentReference reference,
      GameConfig config, GameState initialState) async {
    reference.updateColumns([
      DBColConfig().withData(config),
      DBColState().withData(initialState),
    ]);
  }

  Future<void> _updateState(GameState newState) {
    Assert.holds(isActivePlayer,
        message: 'Only active player should change game state');
    state = newState;
    _streamController.add(_gameData);
    return localGameData.gameReference
        .updateColumns([DBColState().withData(newState)]);
  }

  Future<void> _updatePersonalState(PersonalState newState) {
    personalState = newState;
    _streamController.add(_gameData);
    return localGameData.gameReference.updateColumns(
        [DBColPlayer(localGameData.myPlayerID).withData(newState)]);
  }

  Future<void> nextTurn() {
    return _updateState((_transformer..nextTurn()).state);
  }

  Future<void> startExplaning() {
    return _updateState((_transformer..startExplaning()).state);
  }

  Future<void> pauseExplaning() {
    return _updateState((_transformer..pauseExplaning()).state);
  }

  Future<void> resumeExplaning() {
    return _updateState((_transformer..resumeExplaning()).state);
  }

  Future<void> wordGuessed() {
    return _updateState((_transformer..wordGuessed()).state);
  }

  Future<void> finishExplanation() {
    return _updateState((_transformer..finishExplanation()).state);
  }

  Future<void> setWordStatus(int wordId, WordStatus newStatus) {
    return _updateState((_transformer..setWordStatus(wordId, newStatus)).state);
  }

  Future<void> setWordFeedback(int wordId, WordFeedback newFeedback) {
    return _updatePersonalState((_personalTransformer
          ..setWordFeedback(wordId, newFeedback))
        .personalState);
  }

  Future<void> setWordFlag(int wordId, bool hasFlag) {
    return _updatePersonalState(
        (_personalTransformer..setWordFlag(wordId, hasFlag)).personalState);
  }
}
