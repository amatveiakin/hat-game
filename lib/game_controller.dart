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
import 'package:hatgame/util/future.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/strings.dart';
import 'package:russian_words/russian_words.dart' as russian_words;
import 'package:unicode/unicode.dart' as unicode;

class TurnStateTransformer {
  final GameConfig config;
  final InitialGameState initialState;
  final List<TurnRecord> turnLog;
  TurnState turnState;

  TurnStateTransformer(
      this.config, this.initialState, this.turnLog, this.turnState);

  static TurnRecord turnRecord(TurnState turnState) {
    return TurnRecord(
      (b) => b
        ..party.replace(turnState.party)
        ..wordsInThisTurn.replace(turnState.wordsInThisTurn),
    );
  }

  static TurnState newTurn(
    GameConfig config,
    InitialGameState initialState, {
    @required bool timeToEndGame,
    @required int turnIndex,
  }) {
    return timeToEndGame
        ? null
        : TurnState((b) => b
          ..party.replace(PartyingStrategy.fromGame(config, initialState)
              .getParty(turnIndex))
          ..turnPhase = TurnPhase.prepare);
  }

  void startExplaning() {
    Assert.eq(turnState.turnPhase, TurnPhase.prepare);
    turnState = turnState.rebuild(
      (b) => b
        ..turnPhase = TurnPhase.explain
        ..turnPaused = false
        ..turnTimeBeforePause = Duration.zero
        ..turnTimeStart = NtpTime.nowUtcOrNull(),
    );
    drawNextWord();
  }

  void pauseExplaning() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    Assert.holds(!turnState.turnPaused);
    turnState = turnState.rebuild((b) => b
      ..turnPaused = true
      ..turnTimeBeforePause = turnState.turnTimeBeforePause +
          (NtpTime.nowUtcOrNull()?.difference(turnState.turnTimeStart)));
  }

  void resumeExplaning() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    Assert.holds(turnState.turnPaused);
    turnState = turnState.rebuild(
      (b) => b
        ..turnPaused = false
        ..turnTimeStart = NtpTime.nowUtcOrNull(),
    );
  }

  void wordGuessed() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    Assert.holds(turnState.wordsInThisTurn.isNotEmpty);
    setWordStatus(turnState.wordsInThisTurn.last.id, WordStatus.explained);
    drawNextWord();
  }

  void finishExplanation() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    turnState = turnState.rebuild(
      (b) => b
        ..turnPhase = TurnPhase.review
        ..turnPaused = null
        ..turnTimeBeforePause = null
        ..turnTimeStart = null
        ..bonusTimeStart = NtpTime.nowUtcOrNull(),
    );
  }

  void setWordStatus(int wordId, WordStatus newStatus) {
    final int wordIndex =
        turnState.wordsInThisTurn.indexWhere((w) => w.id == wordId);
    Assert.holds(wordIndex >= 0);
    turnState = turnState.rebuild(
      (b) => b
        ..wordsInThisTurn.rebuildAt(
          wordIndex,
          (b) => b..status = newStatus,
        ),
    );
  }

  void drawNextWord() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    final wordsInHat =
        DerivedGameState.wordsInHat(initialState, turnLog, turnState);
    if (wordsInHat.isEmpty) {
      finishExplanation();
      return;
    }
    final int nextWord =
        wordsInHat.elementAt(Random().nextInt(wordsInHat.length));
    turnState = turnState.rebuild(
      (b) => b
        ..wordsInThisTurn.add(WordInTurn(
          (b) => b
            ..id = nextWord
            ..status = WordStatus.notExplained,
        )),
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
  InitialGameState initialState;
  List<TurnRecord> turnLog;
  TurnState turnState;
  PersonalState personalState;
  List<PersonalState> otherPersonalStates; // online-only
  final localState = LocalGameState();
  final _streamController = StreamController<GameData>(sync: true);

  Stream<GameData> get stateUpdatesStream => _streamController.stream;

  GameData get gameData => GameData(config, initialState, turnLog, turnState,
      personalState, otherPersonalStates, localState);
  TurnStateTransformer get _transformer =>
      TurnStateTransformer(config, initialState, turnLog, turnState);
  PersonalStateTransformer get _personalTransformer =>
      PersonalStateTransformer(personalState);

  // INVARIANTS. Since isInitialized becomes true:
  //   - config, initialState, turnLog, personalState and otherPersonalStates
  //     are always non-null,
  //   - turnState is not null until the game is over,
  //   - config and initialState don't change,
  //   - isInitialized stays true,
  //   - stateUpdatesStream starts sending updates.
  bool isInitialized() => config != null;

  bool isActivePlayer() => turnState == null
      ? false
      : (localGameData.onlineMode
          ? activePlayer(turnState) == localGameData.myPlayerID
          : true);

  static List<DBColumnData> _newGameRecord() {
    return [
      DBColCreationTimeUtc()
          .withData(NtpTime.nowUtcNoPrecisionGuarantee().toString()),
      DBColHostAppVersion().withData(appVersion),
    ];
  }

  static int activePlayer(TurnState currentTurn) => currentTurn.party.performer;

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

  static Future<LocalGameData> newLobby(
      firestore.Firestore firestoreInstance, String myName) async {
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
      await firestoreInstance.runTransaction((firestore.Transaction tx) async {
        for (int iter = 0; iter < attemptsPerTransaction; iter++) {
          gameID = newFirestoreGameID(idLength, idPrefix);
          reference = firestoreGameReference(
              firestoreInstance: firestoreInstance, gameID: gameID);
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

  static Future<LocalGameData> joinLobby(firestore.Firestore firestoreInstance,
      String myName, String gameID) async {
    checkPlayerNameIsValid(myName);
    // TODO: Check if the game has already started.
    final firestore.DocumentReference reference = firestoreGameReference(
        firestoreInstance: firestoreInstance, gameID: gameID);

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

    await firestoreInstance.runTransaction((firestore.Transaction tx) async {
      firestore.DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        return Future.error(InvalidOperation("Game $gameID doesn't exist"));
      }
      {
        // [2/2] Workaround flutter/firestore error. Do a dumb write.
        await tx.set(reference, snapshot.data);
      }
      try {
        checkVersionCompatibility(
            dbTryGet(snapshot.data, DBColHostAppVersion()), appVersion);
      } on InvalidOperation catch (e) {
        return Future.error(e);
      }

      // Note: include kicked players.
      final playerData = dbGetAll(snapshot.data, DBColPlayerManager(),
          documentPath: reference.path);
      for (final p in playerData.values()) {
        if (myName == p.name) {
          return Future.error(
              InvalidOperation("Name $myName is already taken"));
        }
      }
      playerID = dbNextIndex(playerData);

      await tx.update(
          reference,
          dbData([
            DBColPlayer(playerID).withData(PersonalState((b) => b
              ..id = playerID
              ..name = myName))
          ]));
    });

    return LocalGameData(
      onlineMode: true,
      gameID: gameID,
      gameReference: FirestoreDocumentReference(reference),
      myPlayerID: playerID,
    );
  }

  static Future<void> kickPlayer(
      DBDocumentReference firestoreReference, int playerID) async {
    final firestore.DocumentReference reference =
        (firestoreReference as FirestoreDocumentReference).firestoreReference;
    firestore.Firestore firestoreInstance = reference.firestore;
    // Same caveats as in joinLobby.
    await firestoreInstance.runTransaction((firestore.Transaction tx) async {
      firestore.DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        return Future.error(
            InvalidOperation("Game ${firestoreReference.path} doesn't exist"));
      }
      {
        // Workaround flutter/firestore error. Do a dumb write.
        await tx.set(reference, snapshot.data);
      }
      final playerRecord = dbGet(snapshot.data, DBColPlayer(playerID),
          documentPath: reference.path);
      await tx.update(
          reference,
          dbData([
            DBColPlayer(playerID)
                .withData(playerRecord.rebuild((b) => b..kicked = true))
          ]));
    });
  }

  static Future<void> startGame(
      DBDocumentReference reference, GameConfig config,
      {MockShuffler<int> individualOrderMockShuffler}) {
    final numPlayers = config.players.names.length;
    final playerIDs = config.players.names.keys.toList();
    BuiltList<BuiltList<int>> teams;
    BuiltList<int> individualOrder;
    if (config.teaming.teamPlay) {
      if (config.players.teams != null) {
        teams = BuiltList<BuiltList<int>>.from(config.players.teams
            .map((team) => BuiltList<int>(team.toList().shuffled()))
            .toList()
            .shuffled());
      } else {
        final List<int> teamSizes = generateTeamSizes(numPlayers,
            config.teaming.desiredTeamSize, config.teaming.unequalTeamSize);
        final teamsMutable = generateTeamPlayers(
            playerIDs: playerIDs.shuffled(), teamSizes: teamSizes.shuffled());
        teams = BuiltList<BuiltList<int>>.from(
            teamsMutable.map((t) => BuiltList<int>(t)));
      }
      checkTeamSizes(teams);
    } else {
      Assert.holds(config.players.teams == null);
      checkNumPlayersForIndividualPlay(
          numPlayers, config.teaming.individualPlayStyle);
      individualOrder = BuiltList<int>.from(
          playerIDs.shuffled(mockShuffler: individualOrderMockShuffler));
    }

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
        ..text = text));
    }

    final InitialGameState initialState = InitialGameState((b) => b
      ..individualOrder =
          (individualOrder != null ? ListBuilder(individualOrder) : null)
      ..teams = (teams != null ? ListBuilder(teams) : null)
      ..words.replace(words));
    final TurnState turnState = TurnStateTransformer.newTurn(
      config,
      initialState,
      timeToEndGame: false,
      turnIndex: 0,
    );
    // In addition to initial state, write the config:
    //   - just to be sure;
    //   - to fill in players field.  // TODO: Better solution for this?
    return _writeInitialState(reference, config, initialState, turnState);
  }

  Map<int, PersonalState> _parsePersonalStates(
      final DBDocumentSnapshot snapshot) {
    return Map.fromEntries(snapshot
        .getAll(DBColPlayerManager())
        .where((e) => !(e.value.kicked ?? false))
        .map((e) => MapEntry(e.id, e.value)));
  }

  List<TurnRecord> _parseTurnLog(final DBDocumentSnapshot snapshot) {
    return snapshot.getAll(DBColTurnRecordManager()).values().toList();
  }

  void _onUpdateFromDB(final DBDocumentSnapshot snapshot) {
    Assert.holds(snapshot.exists);
    if (!isInitialized()) {
      final GameConfigReadResult configReadResult =
          GameConfigController.configFromSnapshot(localGameData, snapshot);
      if (!snapshot.contains(DBColInitialState())) {
        return;
      }
      // This is the one and only place where the config changes.
      config = configReadResult.configWithOverrides;
      initialState = snapshot.get(DBColInitialState());
    }

    TurnState newTurnState = snapshot.tryGet(DBColCurrentTurn());
    List<TurnRecord> newTurnLog = _parseTurnLog(snapshot);
    if (isActivePlayer()) {
      if (localGameData.onlineMode) {
        final int newActivePlayer = activePlayer(newTurnState);
        Assert.eq(localGameData.myPlayerID, newActivePlayer,
            message: 'Active player unexpectedly changed from '
                '${localGameData.myPlayerID} to $newActivePlayer');
      }
      // Ignore the update, because the state of truth is on the client while
      // we are the active player.
    } else if (turnLog != null &&
        DerivedGameState.turnIndex(newTurnLog) <
            DerivedGameState.turnIndex(turnLog)) {
      // Similar to above. There is only one case when update in the DB can
      // be older than the local version: we used to be the active player,
      // wrote an update indicating that a new turn started and then received
      // a stale update from the previous turn.
    } else {
      turnState = newTurnState;
      turnLog = newTurnLog;
    }

    if (localGameData.onlineMode) {
      final allPersonalStates = _parsePersonalStates(snapshot);
      Assert.holds(allPersonalStates.containsKey(localGameData.myPlayerID));
      personalState = allPersonalStates[localGameData.myPlayerID];
      allPersonalStates
          .removeWhere((playerID, _) => playerID == localGameData.myPlayerID);
      otherPersonalStates = allPersonalStates.values.toList();
    } else {
      personalState = snapshot.get(DBColLocalPlayer());
      otherPersonalStates = [];
    }
    Assert.holds(!(personalState.kicked ?? false));

    _streamController.add(gameData);
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
    return FutureUtil.doWhileDelayed(() => !isInitialized());
  }

  static Future<void> _writeInitialState(
      DBDocumentReference reference,
      GameConfig config,
      InitialGameState initialState,
      TurnState turnState) async {
    return reference.updateColumns([
      DBColConfig().withData(config),
      DBColInitialState().withData(initialState),
      DBColCurrentTurn().withData(turnState),
    ]);
  }

  Future<void> _updateTurnState(TurnState newState) {
    Assert.holds(isActivePlayer(),
        message: 'Only the active player can change game state');
    turnState = newState;
    _streamController.add(gameData);
    return localGameData.gameReference.updateColumns([
      DBColCurrentTurn().withData(newState),
    ]);
  }

  Future<void> _updatePersonalState(PersonalState newState) {
    personalState = newState;
    _streamController.add(gameData);
    return localGameData.gameReference.updateColumns([
      DBColPlayer(localGameData.myPlayerID).withData(newState),
    ]);
  }

  Future<void> nextTurn() {
    Assert.holds(isActivePlayer(),
        message: 'Only the active player can change game state');
    final int turnIndex = DerivedGameState.turnIndex(turnLog);
    turnLog.add(TurnStateTransformer.turnRecord(turnState));
    turnState = TurnStateTransformer.newTurn(
      config,
      initialState,
      // pass (turnState == null) to `wordsInHat`, because words from the
      // currect turn have already been moved to turnLog
      timeToEndGame:
          DerivedGameState.wordsInHat(initialState, turnLog, null).isEmpty,
      turnIndex: turnIndex + 1,
    );
    _streamController.add(gameData);
    return localGameData.gameReference.updateColumns([
      DBColCurrentTurn().withData(turnState),
      DBColTurnRecord(turnIndex).withData(turnLog.last),
    ]);
  }

  Future<void> startExplaning() {
    return _updateTurnState((_transformer..startExplaning()).turnState);
  }

  Future<void> pauseExplaning() {
    return _updateTurnState((_transformer..pauseExplaning()).turnState);
  }

  Future<void> resumeExplaning() {
    return _updateTurnState((_transformer..resumeExplaning()).turnState);
  }

  Future<void> wordGuessed() {
    return _updateTurnState((_transformer..wordGuessed()).turnState);
  }

  Future<void> finishExplanation() {
    return _updateTurnState((_transformer..finishExplanation()).turnState);
  }

  Future<void> setWordStatus(int wordId, WordStatus newStatus) {
    return _updateTurnState(
        (_transformer..setWordStatus(wordId, newStatus)).turnState);
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
