import 'dart:async';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:hatgame/app_version.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/team_compositions.dart';
import 'package:hatgame/db/db.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/db/db_firestore.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase_reader.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/start_game_online_screen.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/built_value_ext.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/strings.dart';

enum Reconnection {
  connectForTheFirstTime,
  reconnectBeforeGame,
  reconnectDuringName,
}

class JoinGameResult {
  final LocalGameData localGameData;
  final Reconnection reconnection;

  JoinGameResult({@required this.localGameData, @required this.reconnection});
}

enum JoinGameErrorSource {
  gameID,
  playerName,
}

enum StartGameErrorSource {
  players,
  dictionaries,
}

class TurnStateTransformer {
  final GameConfig config;
  final InitialGameState initialState;
  final BuiltList<TurnRecord> turnLog;
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
          ..party.replace(
              PartyingStrategy.fromGame(config, initialState.teamCompositions)
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
  final GameConfig config;
  final InitialGameState initialState;
  final BuiltList<TurnRecord> turnLog;
  final TurnState turnState;
  final PersonalState personalState;
  final BuiltList<PersonalState> otherPersonalStates; // online-only

  GameData get gameData => GameData(config, initialState, turnLog, turnState,
      personalState, otherPersonalStates);
  TurnStateTransformer get _transformer =>
      TurnStateTransformer(config, initialState, turnLog, turnState);
  PersonalStateTransformer get _personalTransformer =>
      PersonalStateTransformer(personalState);

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
      DBColGamePhase().withData(GamePhase.configure),
    ];
  }

  static int activePlayer(TurnState currentTurn) => currentTurn.party.performer;

  static void checkVersionCompatibility(
      String hostVersion, String clientVersion) {
    if (isNullOrEmpty(hostVersion)) {
      throw InvalidOperation('Unknown host version', isInternalError: true);
    }
    if (isNullOrEmpty(clientVersion)) {
      throw InvalidOperation('Unknown client version', isInternalError: true);
    }
    if (!versionsCompatibile(hostVersion, clientVersion)) {
      throw InvalidOperation(tr('incompatible_game_version', namedArgs: {
        'hostVersion': hostVersion,
        'clientVersion': clientVersion
      }));
    }
  }

  // Returns game ID.
  static Future<String> _createGameOffline(
      List<DBColumnData> initialColumns) async {
    final String gameID = newLocalGameID();
    DBDocumentReference reference = localGameReference(gameID: gameID);
    await reference.setColumns(initialColumns);
    return gameID;
  }

  // Returns game ID.
  static Future<String> _createGameOnline(
      firestore.FirebaseFirestore firestoreInstance,
      List<DBColumnData> initialColumns) async {
    const int minIDLength = 4;
    const int maxIDLength = 8;
    const int attemptsPerTransaction = 100;
    final String idPrefix = kReleaseMode ? '' : '.';
    String gameID;
    for (int idLength = minIDLength;
        idLength <= maxIDLength && gameID == null;
        idLength++) {
      await firestoreInstance.runTransaction((firestore.Transaction tx) async {
        for (int iter = 0; iter < attemptsPerTransaction; iter++) {
          gameID = newFirestoreGameID(idLength, idPrefix);
          final reference = firestoreGameReference(
              firestoreInstance: firestoreInstance, gameID: gameID);
          firestore.DocumentSnapshot snapshot = await tx.get(reference);
          if (!snapshot.exists) {
            await tx.set(reference, dbData(initialColumns));
            return;
          }
        }
        gameID = null;
      });
    }
    if (gameID == null) {
      throw InvalidOperation('Cannot generate game ID', isInternalError: true);
    }
    return gameID;
  }

  static Future<LocalGameData> newGameOffine() async {
    final GameConfig config =
        GameConfigController.initialConfig(onlineMode: false).rebuild(
      (b) => b.players.names.replace({}),
    );
    final String gameID = await _createGameOffline([
      ..._newGameRecord(),
      DBColConfig().withData(config),
      DBColLocalPlayer().withData(PersonalState((b) => b
        ..id = 0
        ..name = 'fake')),
    ]);
    return LocalGameData(
      onlineMode: false,
      gameID: gameID,
      gameReference: localGameReference(gameID: gameID),
    );
  }

  static Future<LocalGameData> newLobby(
      firestore.FirebaseFirestore firestoreInstance, String myName) async {
    final int playerID = 0;
    final GameConfig config =
        GameConfigController.initialConfig(onlineMode: true);
    final String gameID = await _createGameOnline(firestoreInstance, [
      ..._newGameRecord(),
      DBColConfig().withData(config),
      DBColPlayer(playerID).withData(PersonalState((b) => b
        ..id = playerID
        ..name = myName)),
    ]);
    return LocalGameData(
      onlineMode: true,
      gameID: gameID,
      gameReference: FirestoreDocumentReference(firestoreGameReference(
          firestoreInstance: firestoreInstance, gameID: gameID)),
      myPlayerID: playerID,
    );
  }

  static Future<JoinGameResult> joinLobby(
      firestore.FirebaseFirestore firestoreInstance,
      String myName,
      String gameID) async {
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
      throw InvalidOperation(tr('game_doesnt_exist', args: [gameID]))
        ..addTag(JoinGameErrorSource.gameID);
    }

    // TODO: Adhere to best practices: get `playerID` as a return value from
    // runTransaction. I tried doing this, but unfortunately ran into
    // https://github.com/flutter/flutter/issues/17663. Note: the issue was
    // already marked as closed, but for me it still crashed with:
    //     Unhandled Exception: PlatformException(Error performing transaction,
    //         java.lang.Exception: DoTransaction failed: Invalid argument:
    //         Instance of '_CompactLinkedHashSet<Object>', null)
    int playerID;
    Reconnection reconnection;
    // For some reason, throwing or returning Future.error from `runTransaction`
    // doesn't work. Got:
    //     Unhandled Exception: PlatformException(Error performing transaction,
    //         java.lang.Exception: DoTransaction failed: Instance of
    //         'InvalidOperation', null)
    InvalidOperation error;

    await firestoreInstance.runTransaction((firestore.Transaction tx) async {
      firestore.DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        error = InvalidOperation(tr('game_doesnt_exist', args: [gameID]))
          ..addTag(JoinGameErrorSource.gameID);
        return;
      }
      {
        // [2/2] Workaround flutter/firestore error. Do a dumb write.
        await tx.set(reference, snapshot.data());
      }
      try {
        checkVersionCompatibility(
            dbTryGet(snapshot.data(), DBColHostAppVersion()), appVersion);
      } on InvalidOperation catch (e) {
        error = e;
        return;
      }
      final GamePhase gamePhase = GamePhaseReader.fromSnapshotNoPersonal(
          FirestoreDocumentSnapshot.fromFirestore(snapshot));
      final bool userCreationPhase = (gamePhase == GamePhase.configure);

      // Note: include kicked players.
      final playerData = dbGetAll(snapshot.data(), DBColPlayerManager(),
          documentPath: reference.path);
      int existingPlayerID;
      for (final p in playerData.values().where((v) => !(v.kicked ?? false))) {
        if (myName == p.name) {
          existingPlayerID = p.id;
          break;
        }
      }

      if (existingPlayerID != null) {
        playerID = existingPlayerID;
        if (userCreationPhase) {
          reconnection = Reconnection.reconnectBeforeGame;
        } else {
          reconnection = Reconnection.reconnectDuringName;
        }
      } else {
        if (userCreationPhase) {
          playerID = dbNextIndex(playerData);
          reconnection = Reconnection.connectForTheFirstTime;
          await tx.update(
              reference,
              dbData([
                DBColPlayer(playerID).withData(PersonalState((b) => b
                  ..id = playerID
                  ..name = myName))
              ]));
        } else {
          // TODO: Fix message:
          //     'Game $xxx has already started. In order to reconnect...'
          error = InvalidOperation('Name $myName is already taken')
            ..addTag(JoinGameErrorSource.playerName);
        }
      }
    });

    if (error != null) {
      throw error;
    }

    return JoinGameResult(
      localGameData: LocalGameData(
        onlineMode: true,
        gameID: gameID,
        gameReference: FirestoreDocumentReference(reference),
        myPlayerID: playerID,
      ),
      reconnection: reconnection,
    );
  }

  static Future<void> kickPlayer(
      DBDocumentReference firestoreReference, int playerID) async {
    final firestore.DocumentReference reference =
        (firestoreReference as FirestoreDocumentReference).firestoreReference;
    firestore.FirebaseFirestore firestoreInstance = reference.firestore;
    // Same caveats as in joinLobby.
    await firestoreInstance.runTransaction((firestore.Transaction tx) async {
      firestore.DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        return Future.error(
            InvalidOperation("Game ${firestoreReference.path} doesn't exist"));
      }
      {
        // Workaround flutter/firestore error. Do a dumb write.
        await tx.set(reference, snapshot.data());
      }
      final playerRecord = dbGet(snapshot.data(), DBColPlayer(playerID),
          documentPath: reference.path);
      await tx.update(
          reference,
          dbData([
            DBColPlayer(playerID)
                .withData(playerRecord.rebuild((b) => b..kicked = true))
          ]));
    });
  }

  static Future<void> toWriteWordsPhase(DBDocumentReference reference) async {
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColGamePhase().withData(GamePhase.writeWords),
    ]);
  }

  static Future<void> backFromWordWritingPhase(
      DBDocumentReference reference) async {
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColGamePhase().withData(GamePhase.configure),
    ]);
  }

  static void preGameCheck(GameConfig config) {
    if (config.rules.writeWords == false &&
        (config.rules.dictionaries == null ||
            config.rules.dictionaries.isEmpty)) {
      throw InvalidOperation(tr('no_dictionaries_selected'))
        ..addTag(StartGameErrorSource.dictionaries);
    }

    try {
      // Check that teams can be generate, don't write them down yet.
      GameController.generateTeamCompositions(config);
    } on InvalidOperation catch (e) {
      throw e..addTag(StartGameErrorSource.players);
    }
  }

  static TeamCompositions generateTeamCompositions(GameConfig config) {
    final numPlayers = config.players.names.length;
    final playerIDs = config.players.names.keys.toList();
    if (config.teaming.teamPlay) {
      BuiltList<BuiltList<int>> teams;
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
      return TeamCompositions((b) => b..teams.replace(teams));
    } else {
      Assert.holds(config.players.teams == null);
      checkNumPlayersForIndividualPlay(
          numPlayers, config.teaming.individualPlayStyle);
      return TeamCompositions((b) => b
        ..individualOrder.replace(
          playerIDs.shuffled(),
        ));
    }
  }

  static Future<void> updateTeamCompositions(
      DBDocumentReference reference, GameConfig config) async {
    final TeamCompositions teamCompositions = generateTeamCompositions(config);
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColTeamCompositions().withData(teamCompositions),
      DBColGamePhase().withData(GamePhase.composeTeams),
    ]);
  }

  static Future<void> discardTeamCompositions(DBDocumentReference reference) {
    return reference.updateColumns([
      DBColTeamCompositions().withData(null),
      DBColGamePhase().withData(GamePhase.configure),
    ]);
  }

  static TeamCompositionsViewData getTeamCompositions(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    List<String> _playerNames(GameConfig config, Iterable<int> playerIDs) {
      return playerIDs.map((id) => config.players.names[id]).toList();
    }

    if (GamePhaseReader.fromSnapshot(localGameData, snapshot) !=
        GamePhase.composeTeams) {
      return null;
    }
    final GameConfig gameConfig =
        GameConfigController.fromSnapshot(localGameData, snapshot)
            .configWithOverrides();
    final TeamCompositions teamCompositions =
        snapshot.get(DBColTeamCompositions());
    final List<List<String>> playerNames = teamCompositions.teams != null
        ? teamCompositions.teams
            .map((t) => _playerNames(gameConfig, t))
            .toList()
        : teamCompositions.individualOrder
            .map((p) => _playerNames(gameConfig, [p]))
            .toList();
    Assert.eq(teamCompositions.teams != null, gameConfig.teaming.teamPlay);
    return TeamCompositionsViewData(
        gameConfig: gameConfig, playerNames: playerNames);
  }

  static List<String> _generateRandomWords(GameConfig config) {
    final int numPlayers = config.players.names.length;
    final int totalWords = config.rules.wordsPerPlayer * numPlayers;
    Assert.holds(
        config.rules.dictionaries != null &&
            config.rules.dictionaries.isNotEmpty,
        lazyMessage: () => config.rules.toString());
    final wordCollection =
        Lexicon.wordCollection(config.rules.dictionaries.toList());
    return List.generate(totalWords, (_) => wordCollection.randomWord());
  }

  static List<String> _collectWordsFromPlayers(DBDocumentSnapshot snapshot) {
    final personalStates = _parsePersonalStates(snapshot);
    return personalStates.values
        .fold([], (total, state) => total + state.words.asList());
  }

  static List<Word> _wordsFromWordTexts(List<String> wordTexts) {
    return wordTexts
        .mapWithIndex(
          (index, text) => Word((b) => b
            ..id = index
            ..text = text),
        )
        .toList();
  }

  static Future<void> startGame(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    final GameConfig config =
        GameConfigController.fromSnapshot(localGameData, snapshot)
            .configWithOverrides();
    final TeamCompositions teamCompositions =
        snapshot.get(DBColTeamCompositions());

    final List<Word> words = _wordsFromWordTexts(
      config.rules.writeWords
          ? _collectWordsFromPlayers(snapshot)
          : _generateRandomWords(config),
    );

    final InitialGameState initialState = InitialGameState((b) => b
      ..teamCompositions.replace(teamCompositions)
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
    return _writeInitialState(
        snapshot.reference, config, initialState, turnState);
  }

  static Future<void> rematch(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) async {
    List<DBColumnData> initialColumns = _newGameRecord();
    String gameID;
    if (localGameData.onlineMode) {
      final firestore.FirebaseFirestore firestoreInstance =
          (localGameData.gameReference as FirestoreDocumentReference)
              .firestoreReference
              .firestore;
      initialColumns.add(DBColConfig().withData(
          snapshot.get(DBColConfig()).rebuild((b) => b..players = null)));
      initialColumns.addAll(snapshot
          .getAll(DBColPlayerManager())
          .map((c) => DBColPlayer(c.id).withData(PersonalState(
                (b) => b
                  ..id = c.value.id
                  ..name = c.value.name
                  ..kicked = c.value.kicked,
              ))));
      gameID = await _createGameOnline(firestoreInstance, initialColumns);
    } else {
      initialColumns.add(DBColConfig().withData(snapshot.get(DBColConfig())));
      initialColumns
          .add(DBColLocalPlayer().withData(snapshot.get(DBColLocalPlayer())));
      gameID = await _createGameOffline(initialColumns);
    }
    return localGameData.gameReference.updateColumns([
      DBColRematchNextGameID().withData(gameID),
    ]);
  }

  static DBDocumentReference _rematchGameReference(
      LocalGameData oldLocalGameData,
      {@required String newGameID}) {
    if (oldLocalGameData.onlineMode) {
      final firestore.FirebaseFirestore firestoreInstance =
          (oldLocalGameData.gameReference as FirestoreDocumentReference)
              .firestoreReference
              .firestore;
      return FirestoreDocumentReference(firestoreGameReference(
          firestoreInstance: firestoreInstance, gameID: newGameID));
    } else {
      return localGameReference(gameID: newGameID);
    }
  }

  static LocalGameData joinRematch(
      LocalGameData oldLocalGameData, DBDocumentSnapshot snapshot) {
    final String newGameID = snapshot.get(DBColRematchNextGameID());
    return LocalGameData(
      onlineMode: oldLocalGameData.onlineMode,
      gameID: newGameID,
      gameReference:
          _rematchGameReference(oldLocalGameData, newGameID: newGameID),
      myPlayerID: oldLocalGameData.myPlayerID,
    );
  }

  static WordWritingViewData getWordWritingViewData(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    final Iterable<PersonalState> playerStates =
        _parsePersonalStates(snapshot).values;
    return WordWritingViewData(
      playerState: snapshot.get(DBColPlayer(localGameData.myPlayerID)),
      numPlayers: playerStates.length,
      numPlayersReady:
          playerStates.where((p) => (p.wordsReady ?? false)).length,
      playersNotReady: playerStates
          .where((p) => !(p.wordsReady ?? false))
          .map((p) => p.name)
          .toList(),
    );
  }

  static Future<void> updatePersonalState(
      LocalGameData localGameData, PersonalState newState) {
    final DBColumn column = localGameData.onlineMode
        ? DBColPlayer(localGameData.myPlayerID)
        : DBColLocalPlayer();
    return localGameData.gameReference.updateColumns([
      column.withData(newState),
    ], localCache: LocalCacheBehavior.cache);
  }

  static Map<int, PersonalState> _parsePersonalStates(
      DBDocumentSnapshot snapshot) {
    return Map.fromEntries(snapshot
        .getAll(DBColPlayerManager())
        .where((e) => !(e.value.kicked ?? false))
        .map((e) => MapEntry(e.id, e.value)));
  }

  GameController._(
    this.localGameData,
    this.config,
    this.initialState,
    this.turnLog,
    this.turnState,
    this.personalState,
    this.otherPersonalStates,
  ) {
    Assert.holds(!(personalState.kicked ?? false));
  }

  factory GameController.fromSnapshot(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    Assert.holds(snapshot.exists);
    Assert.isIn(GamePhaseReader.fromSnapshot(localGameData, snapshot),
        {GamePhase.play, GamePhase.gameOver});

    final GameConfig config = snapshot.get(DBColConfig());
    final InitialGameState initialState = snapshot.get(DBColInitialState());
    final BuiltList<TurnRecord> turnLog =
        BuiltList.from(snapshot.getAll(DBColTurnRecordManager()).values());
    final TurnState turnState = snapshot.tryGet(DBColCurrentTurn());

    PersonalState personalState;
    BuiltList<PersonalState> otherPersonalStates;
    if (localGameData.onlineMode) {
      final allPersonalStates = _parsePersonalStates(snapshot);
      Assert.holds(allPersonalStates.containsKey(localGameData.myPlayerID));
      personalState = allPersonalStates[localGameData.myPlayerID];
      allPersonalStates
          .removeWhere((playerID, _) => playerID == localGameData.myPlayerID);
      otherPersonalStates =
          BuiltList<PersonalState>.from(allPersonalStates.values.toList());
    } else {
      personalState = snapshot.get(DBColLocalPlayer());
      otherPersonalStates = BuiltList<PersonalState>.from([]);
    }

    return GameController._(localGameData, config, initialState, turnLog,
        turnState, personalState, otherPersonalStates);
  }

  static Future<void> _writeInitialState(
      DBDocumentReference reference,
      GameConfig config,
      InitialGameState initialState,
      TurnState turnState) async {
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColGamePhase().withData(GamePhase.play),
      DBColConfig().withData(config),
      DBColTeamCompositions().withData(null),
      DBColInitialState().withData(initialState),
      DBColCurrentTurn().withData(turnState),
    ]);
  }

  Future<void> _updateTurnState(TurnState newState) {
    Assert.holds(isActivePlayer(),
        message: 'Only the active player can change game state');
    return localGameData.gameReference.updateColumns([
      DBColCurrentTurn().withData(newState),
    ], localCache: LocalCacheBehavior.cache);
  }

  Future<void> _updatePersonalState(PersonalState newState) {
    return updatePersonalState(localGameData, newState);
  }

  Future<void> nextTurn() async {
    Assert.holds(isActivePlayer(),
        message: 'Only the active player can change game state');
    final int turnIndex = DerivedGameState.turnIndex(turnLog);
    final TurnRecord newTurnRecord = TurnStateTransformer.turnRecord(turnState);
    final BuiltList<TurnRecord> newTurnLog =
        turnLog.rebuild((b) => b..add(newTurnRecord));
    final bool timeToEndGame =
        DerivedGameState.wordsInHat(initialState, newTurnLog, null).isEmpty;
    final TurnState newTurnState = TurnStateTransformer.newTurn(
      config,
      initialState,
      // pass (turnState == null) to `wordsInHat`, because words from the
      // current turn have already been moved to turn log.
      timeToEndGame: timeToEndGame,
      turnIndex: turnIndex + 1,
    );
    localGameData.gameReference.clearLocalCache();
    return localGameData.gameReference.updateColumns([
      if (timeToEndGame) DBColGamePhase().withData(GamePhase.gameOver),
      DBColCurrentTurn().withData(newTurnState),
      DBColTurnRecord(turnIndex).withData(newTurnRecord),
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
