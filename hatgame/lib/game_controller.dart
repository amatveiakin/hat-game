import 'dart:async';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:hatgame/app_version.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/team_compositions.dart';
import 'package:hatgame/built_value/word.dart';
import 'package:hatgame/db/db.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/db/db_firestore.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase_reader.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/built_value_ext.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:hatgame/util/local_str.dart';
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

  JoinGameResult({required this.localGameData, required this.reconnection});
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

  static TurnState backToRereview(TurnRecord turnRecord) {
    return TurnState(
      (b) => b
        ..party.replace(turnRecord.party)
        ..wordsInThisTurn.replace(turnRecord.wordsInThisTurn)
        ..turnPhase = TurnPhase.rereview,
    );
  }

  static TurnState newTurn(
    GameConfig config,
    InitialGameState initialState, {
    required int turnIndex,
  }) {
    return TurnState((b) => b
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
    Assert.holds(!turnState.turnPaused!);
    turnState = turnState.rebuild((b) => b
      ..turnPaused = true
      ..turnTimeBeforePause = turnState.turnTimeBeforePause! +
          (NtpTime.nowUtcOrNull()?.difference(turnState.turnTimeStart!) ??
              Duration.zero));
  }

  void resumeExplaning() {
    Assert.eq(turnState.turnPhase, TurnPhase.explain);
    Assert.holds(turnState.turnPaused!);
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

  void setWordStatus(WordId wordId, WordStatus newStatus) {
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
    final WordInTurn wordInTurn;
    if (wordsInHat == null) {
      final wordCollection = Lexicon.wordCollection(
          config.rules.dictionaries.toList(),
          config.rules.variant == GameVariant.pluralias);
      final content = wordCollection.randomWord();
      wordInTurn = WordInTurn((b) => b
        ..id.turnIndex = DerivedGameState.turnIndex(turnLog)
        ..id.index = turnState.wordsInThisTurn.length
        ..content.replace(content)
        ..status = WordStatus.notExplained);
    } else {
      if (wordsInHat.isEmpty) {
        finishExplanation();
        return;
      }
      final nextWordId =
          wordsInHat.elementAt(Random().nextInt(wordsInHat.length));
      wordInTurn = WordInTurn((b) => b
        ..id.replace(nextWordId)
        ..status = WordStatus.notExplained);
    }
    turnState = turnState.rebuild(
      (b) => b..wordsInThisTurn.add(wordInTurn),
    );
  }
}

class PersonalStateTransformer {
  PersonalState personalState;

  PersonalStateTransformer(this.personalState);

  void setWordFeedback(WordId wordId, WordFeedback? newFeedback) {
    final wordFeedback = personalState.wordFeedback.toMap();
    if (newFeedback != null) {
      wordFeedback[wordId] = newFeedback;
    } else {
      wordFeedback.remove(wordId);
    }
    personalState =
        personalState.rebuild((b) => b..wordFeedback.replace(wordFeedback));
  }

  void setWordFlag(WordId wordId, bool hasFlag) {
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

class _JoinGameResultInternal {
  // Throwing or returning Future.error from `runTransaction` doesn't work.
  // It results in:
  //     Unhandled Exception: PlatformException(Error performing transaction,
  //         java.lang.Exception: DoTransaction failed: Instance of
  //         'InvalidOperation', null)
  // Other fields are ignored if `error` is non-null.
  InvalidOperation? error;

  int? playerID; // non-null if no error
  Reconnection? reconnection; // non-null if no error

  _JoinGameResultInternal.error(InvalidOperation this.error);
  _JoinGameResultInternal.success(
      {required int this.playerID, required Reconnection this.reconnection});
}

class GameController {
  final LocalGameData localGameData;
  final GameConfig config;
  final InitialGameState initialState;
  final BuiltList<TurnRecord> turnLog;
  final TurnState? turnState;
  final PersonalState personalState;
  final BuiltList<PersonalState> otherPersonalStates; // online-only

  GameData get gameData => GameData(config, initialState, turnLog, turnState,
      personalState, otherPersonalStates);
  TurnStateTransformer get _transformer =>
      TurnStateTransformer(config, initialState, turnLog, turnState!);
  PersonalStateTransformer get _personalTransformer =>
      PersonalStateTransformer(personalState);

  int get turnIndex => DerivedGameState.turnIndex(turnLog);

  bool isActivePlayer() => turnState == null
      ? false
      : (localGameData.onlineMode
          ? activePlayer(turnState!) == localGameData.myPlayerID
          : true);

  static List<DBColumnUpdate> _newGameRecord() {
    return [
      DBColCreationTimeUtc()
          .setValue(NtpTime.nowUtcNoPrecisionGuarantee().toString()),
      DBColHostAppVersion().setValue(appVersion),
      DBColGamePhase().setValue(GamePhase.configure),
    ];
  }

  static int activePlayer(TurnState currentTurn) => currentTurn.party.performer;

  static void checkVersionCompatibility(
      String hostVersion, String clientVersion) {
    if (isNullOrEmpty(hostVersion)) {
      throw InvalidOperation(LocalStr.raw('Unknown host version'),
          isInternalError: true);
    }
    if (isNullOrEmpty(clientVersion)) {
      throw InvalidOperation(LocalStr.raw('Unknown client version'),
          isInternalError: true);
    }
    if (!versionsCompatible(hostVersion, clientVersion)) {
      throw InvalidOperation(LocalStr.tr('incompatible_game_version',
          namedArgs: {
            'hostVersion': hostVersion,
            'clientVersion': clientVersion
          }));
    }
  }

  // Returns game ID.
  static Future<String> _createGameOffline(
      List<DBColumnUpdate> initialColumns) async {
    final String gameID = newLocalGameID();
    DBDocumentReference reference = localGameReference(gameID: gameID);
    await reference.setColumns(initialColumns);
    return gameID;
  }

  // Returns game ID.
  static Future<String> _createGameOnline(
      firestore.FirebaseFirestore firestoreInstance,
      List<DBColumnUpdate> initialColumns) async {
    const int minIDLength = 4;
    const int maxIDLength = 8;
    const int attemptsPerTransaction = 100;
    const String idPrefix = kReleaseMode ? '' : '.';
    for (int idLength = minIDLength; idLength <= maxIDLength; idLength++) {
      final String? gameID = await firestoreInstance
          .runTransaction((firestore.Transaction tx) async {
        for (int iter = 0; iter < attemptsPerTransaction; iter++) {
          final gameID = newFirestoreGameID(idLength, idPrefix);
          final reference = firestoreGameReference(
              firestoreInstance: firestoreInstance, gameID: gameID);
          firestore.DocumentSnapshot snapshot = await tx.get(reference);
          if (!snapshot.exists) {
            tx.set(reference, firestoreUpdates(initialColumns));
            return gameID;
          }
        }
        return null;
      });
      if (gameID != null) {
        return gameID;
      }
    }
    throw InvalidOperation(LocalStr.raw('Cannot generate game ID'),
        isInternalError: true);
  }

  static Future<LocalGameData> newGameOffine() async {
    final GameConfig config =
        GameConfigController.initialConfig(onlineMode: false);
    final String gameID = await _createGameOffline([
      ..._newGameRecord(),
      DBColConfig().setValue(config),
      DBColLocalPlayer().setValue(PersonalState((b) => b
        ..id = 0
        ..name = 'fake')),
    ]);
    return LocalGameData(
      onlineMode: false,
      gameID: gameID,
      gameReference: localGameReference(gameID: gameID),
      myPlayerID: null,
    );
  }

  static Future<LocalGameData> newLobby(
      firestore.FirebaseFirestore firestoreInstance, String myName) async {
    const int playerID = 0;
    final GameConfig config =
        GameConfigController.initialConfig(onlineMode: true);
    final String gameID = await _createGameOnline(firestoreInstance, [
      ..._newGameRecord(),
      DBColConfig().setValue(config),
      DBColPlayer(playerID).setValue(PersonalState((b) => b
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

    final _JoinGameResultInternal transactionResult = await firestoreInstance
        .runTransaction((firestore.Transaction tx) async {
      firestore.DocumentSnapshot snapshot = await tx.get(reference);
      if (!snapshot.exists) {
        return _JoinGameResultInternal.error(
            InvalidOperation(LocalStr.tr('game_doesnt_exist', args: [gameID]))
              ..addTag(JoinGameErrorSource.gameID));
      }
      try {
        checkVersionCompatibility(
            dbTryGet(snapshot.data() as Map<String, dynamic>,
                DBColHostAppVersion())!,
            appVersion);
      } on InvalidOperation catch (e) {
        return _JoinGameResultInternal.error(e);
      }
      final GamePhase gamePhase = GamePhaseReader.fromSnapshotNoPersonal(
          FirestoreDocumentSnapshot.fromFirestore(snapshot));
      final bool userCreationPhase = (gamePhase == GamePhase.configure);

      // Note: include kicked players.
      final playerData = dbGetAll(
          snapshot.data() as Map<String, dynamic>, DBColPlayerManager(),
          documentPath: reference.path);
      int? existingPlayerID;
      for (final p in playerData.values().where((v) => !(v.kicked ?? false))) {
        if (myName == p.name) {
          existingPlayerID = p.id;
          break;
        }
      }

      if (existingPlayerID != null) {
        return _JoinGameResultInternal.success(
            playerID: existingPlayerID,
            reconnection: userCreationPhase
                ? Reconnection.reconnectBeforeGame
                : Reconnection.reconnectDuringName);
      } else {
        if (userCreationPhase) {
          final playerID = dbNextIndex(playerData);
          tx.update(
              reference,
              firestoreUpdates([
                DBColPlayer(playerID).setValue(PersonalState((b) => b
                  ..id = playerID
                  ..name = myName))
              ]));
          return _JoinGameResultInternal.success(
              playerID: playerID,
              reconnection: Reconnection.connectForTheFirstTime);
        } else {
          // TODO: Fix message:
          //     'Game $xxx has already started. In order to reconnect...'
          return _JoinGameResultInternal.error(
              InvalidOperation(LocalStr.raw('Name $myName is already taken'))
                ..addTag(JoinGameErrorSource.playerName));
        }
      }
    });

    if (transactionResult.error != null) {
      throw transactionResult.error!;
    }

    return JoinGameResult(
      localGameData: LocalGameData(
        onlineMode: true,
        gameID: gameID,
        gameReference: FirestoreDocumentReference(reference),
        myPlayerID: transactionResult.playerID!,
      ),
      reconnection: transactionResult.reconnection!,
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
        return Future<void>.error(InvalidOperation(
            LocalStr.raw("Game ${firestoreReference.path} doesn't exist")));
      }
      final playerRecord = dbGet(
          snapshot.data() as Map<String, dynamic>, DBColPlayer(playerID),
          documentPath: reference.path);
      tx.update(
          reference,
          firestoreUpdates([
            DBColPlayer(playerID)
                .setValue(playerRecord.rebuild((b) => b..kicked = true))
          ]));
    });
  }

  static Future<void> toWriteWordsPhase(DBDocumentReference reference) async {
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColGamePhase().setValue(GamePhase.writeWords),
    ]);
  }

  static Future<void> backFromWordWritingPhase(
      DBDocumentReference reference) async {
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColGamePhase().setValue(GamePhase.configure),
    ]);
  }

  static void preGameCheck(GameConfig config) {
    if (config.rules.variant != GameVariant.writeWords &&
        config.rules.dictionaries.isEmpty) {
      throw InvalidOperation(LocalStr.tr('no_dictionaries_selected'))
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
    final numPlayers = config.players!.names.length;
    final playerIDs = config.players!.names.keys.toList();
    switch (config.teaming.teamingStyle) {
      case TeamingStyle.individual:
      case TeamingStyle.oneToAll:
        Assert.holds(config.players!.teams == null);
        checkNumPlayersForIndividualPlay(numPlayers, config.teaming);
        return TeamCompositions((b) => b
          ..individualOrder.replace(
            playerIDs.shuffled(),
          ));
      case TeamingStyle.randomPairs:
      case TeamingStyle.randomTeams:
        Assert.holds(config.players!.teams == null);
        final List<int> teamSizes =
            generateTeamSizes(numPlayers, config.teaming);
        final teamsMutable = generateTeamPlayers(
            playerIDs: playerIDs.shuffled(), teamSizes: teamSizes.shuffled());
        final teams = BuiltList<BuiltList<int>>.from(
            teamsMutable.map((t) => BuiltList<int>(t)));
        checkTeamSizes(teams);
        return TeamCompositions((b) => b..teams.replace(teams));
      case TeamingStyle.manualTeams:
        final teams = BuiltList<BuiltList<int>>.from(config.players!.teams!
            .map((team) => BuiltList<int>(team.toList().shuffled()))
            .toList()
            .shuffled());
        checkTeamSizes(teams);
        return TeamCompositions((b) => b..teams.replace(teams));
    }
    Assert.unexpectedValue(config.teaming.teamingStyle);
  }

  static Future<void> updateTeamCompositions(
      DBDocumentReference reference, GameConfig config) async {
    final TeamCompositions teamCompositions = generateTeamCompositions(config);
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColTeamCompositions().setValue(teamCompositions),
      DBColGamePhase().setValue(GamePhase.composeTeams),
    ]);
  }

  static Future<void> discardTeamCompositions(DBDocumentReference reference) {
    return reference.updateColumns([
      DBColTeamCompositions().setValue(null),
      DBColGamePhase().setValue(GamePhase.configure),
    ]);
  }

  static TeamCompositionsViewData? getTeamCompositions(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    List<String> getPlayerNames(GameConfig config, Iterable<int> playerIDs) {
      return playerIDs.map((id) => config.players!.names[id]!).toList();
    }

    if (GamePhaseReader.fromSnapshot(localGameData, snapshot) !=
        GamePhase.composeTeams) {
      return null;
    }
    final GameConfig gameConfig =
        GameConfigController.fromSnapshot(localGameData, snapshot)
            .configWithOverrides();
    final TeamCompositions teamCompositions =
        snapshot.get<TeamCompositions?>(DBColTeamCompositions())!;
    final List<List<String>> playerNames = teamCompositions.teams != null
        ? teamCompositions.teams!
            .map((t) => getPlayerNames(gameConfig, t))
            .toList()
        : teamCompositions.individualOrder!
            .map((p) => getPlayerNames(gameConfig, [p]))
            .toList();
    return TeamCompositionsViewData(
        gameConfig: gameConfig, playerNames: playerNames);
  }

  static List<WordContent> _generateRandomWords(GameConfig config) {
    final int numPlayers = config.players!.names.length;
    final int totalWords = config.rules.wordsPerPlayer * numPlayers;
    Assert.holds(config.rules.dictionaries.isNotEmpty,
        lazyMessage: () => config.rules.toString());
    final wordCollection = Lexicon.wordCollection(
        config.rules.dictionaries.toList(),
        config.rules.variant == GameVariant.pluralias);
    return List.generate(totalWords, (_) => wordCollection.randomWord());
  }

  static List<WordContent> _collectWordsFromPlayers(
      DBDocumentSnapshot snapshot) {
    final personalStates = _parsePersonalStates(snapshot);
    final total = <WordContent>[];
    personalStates.values.forEach((state) =>
        total.addAll(state.words!.map((text) => WordContent.plainWord(text))));
    return total;
  }

  static List<PersistentWord> _wordsFromWordContents(List<WordContent> words) {
    return words
        .mapWithIndex(
          (index, content) => PersistentWord((b) => b
            ..id.index = index
            ..content.replace(content)),
        )
        .toList();
  }

  static Future<void> startGame(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    final GameConfig config =
        GameConfigController.fromSnapshot(localGameData, snapshot)
            .configWithOverrides();
    final TeamCompositions? teamCompositions =
        snapshot.get(DBColTeamCompositions());

    final List<PersistentWord>? words = switch (config.rules.extent) {
      GameExtent.fixedWordSet => _wordsFromWordContents(
          config.rules.variant == GameVariant.writeWords
              ? _collectWordsFromPlayers(snapshot)
              : _generateRandomWords(config),
        ),
      GameExtent.fixedNumRounds => null,
      _ => Assert.unexpectedValue(config.rules.extent)
    };

    final InitialGameState initialState = InitialGameState((b) => b
      ..teamCompositions.replace(teamCompositions!)
      ..words = words?.toBuiltList().toBuilder());
    final TurnState turnState = TurnStateTransformer.newTurn(
      config,
      initialState,
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
    List<DBColumnUpdate> initialColumns = _newGameRecord();
    String gameID;
    if (localGameData.onlineMode) {
      final firestore.FirebaseFirestore firestoreInstance =
          (localGameData.gameReference as FirestoreDocumentReference)
              .firestoreReference
              .firestore;
      initialColumns.add(DBColConfig().setValue(
          snapshot.get(DBColConfig()).rebuild((b) => b..players = null)));
      initialColumns.addAll(snapshot
          .getAll(DBColPlayerManager())
          .map((c) => DBColPlayer(c.id).setValue(PersonalState(
                (b) => b
                  ..id = c.value.id
                  ..name = c.value.name
                  ..kicked = c.value.kicked,
              ))));
      gameID = await _createGameOnline(firestoreInstance, initialColumns);
    } else {
      initialColumns.add(DBColConfig().setValue(snapshot.get(DBColConfig())));
      initialColumns
          .add(DBColLocalPlayer().setValue(snapshot.get(DBColLocalPlayer())));
      gameID = await _createGameOffline(initialColumns);
    }
    return localGameData.gameReference.updateColumns([
      DBColRematchNextGameID().setValue(gameID),
    ]);
  }

  static DBDocumentReference _rematchGameReference(
      LocalGameData oldLocalGameData,
      {required String newGameID}) {
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
      playerState: snapshot.get(DBColPlayer(localGameData.myPlayerID!)),
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
        ? DBColPlayer(localGameData.myPlayerID!)
        : DBColLocalPlayer();
    return localGameData.gameReference.updateColumns([
      column.setValue(newState),
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
    final TurnState? turnState =
        snapshot.tryGet<TurnState?>(DBColCurrentTurn());

    PersonalState? personalState;
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
        turnState, personalState!, otherPersonalStates);
  }

  static Future<void> _writeInitialState(
      DBDocumentReference reference,
      GameConfig config,
      InitialGameState initialState,
      TurnState turnState) async {
    reference.clearLocalCache();
    return reference.updateColumns([
      DBColGamePhase().setValue(GamePhase.play),
      DBColConfig().setValue(config),
      DBColTeamCompositions().setValue(null),
      DBColInitialState().setValue(initialState),
      DBColCurrentTurn().setValue(turnState),
    ]);
  }

  Future<void> _updateTurnState(TurnState newState) {
    Assert.holds(isActivePlayer(),
        message: 'Only the active player can change game state');
    return localGameData.gameReference.updateColumns([
      DBColCurrentTurn().setValue(newState),
    ], localCache: LocalCacheBehavior.cache);
  }

  Future<void> _updatePersonalState(PersonalState newState) {
    return updatePersonalState(localGameData, newState);
  }

  Future<void> nextTurn() async {
    Assert.holds(isActivePlayer(),
        message: 'Only the active player can change game state');
    final int prevTurnIndex = turnIndex;
    final int nextTurnIndex = prevTurnIndex + 1;
    final TurnRecord newTurnRecord =
        TurnStateTransformer.turnRecord(turnState!);
    final BuiltList<TurnRecord> newTurnLog =
        turnLog.rebuild((b) => b..add(newTurnRecord));
    final bool timeToEndGame = switch (config.rules.extent) {
      GameExtent.fixedWordSet =>
        // pass (turnState == null) to `wordsInHat`, because words from the
        // current turn have already been moved to turn log.
        DerivedGameState.wordsInHat(initialState, newTurnLog, null)!.isEmpty,
      GameExtent.fixedNumRounds => config.rules.numRounds ==
          gameData
              .partyingStrategy()
              .getRoundsProgress(nextTurnIndex)
              .roundIndex,
      _ => Assert.unexpectedValue(config.rules.extent),
    };
    if (timeToEndGame) {
      return finishGame(
          lastTurnIndex: prevTurnIndex, lastTurnRecord: newTurnRecord);
    } else {
      final TurnState newTurnState = TurnStateTransformer.newTurn(
        config,
        initialState,
        turnIndex: nextTurnIndex,
      );
      localGameData.gameReference.clearLocalCache();
      return localGameData.gameReference.updateColumns([
        DBColCurrentTurn().setValue(newTurnState),
        DBColTurnRecord(prevTurnIndex).setValue(newTurnRecord),
      ]);
    }
  }

  // Go back to reviewing the words from the previous turn. Typically used when
  // somebody points out after the fact that there was a mistake in one of the
  // explanations.
  Future<void> backToRereview() async {
    Assert.holds(turnState!.turnPhase == TurnPhase.prepare && turnIndex > 0);
    final int prevTurnIndex = turnIndex - 1;
    final prevTurnState =
        TurnStateTransformer.backToRereview(turnLog[prevTurnIndex]);
    localGameData.gameReference.clearLocalCache();
    return localGameData.gameReference.updateColumns([
      DBColCurrentTurn().setValue(prevTurnState),
      DBColTurnRecord(prevTurnIndex).delete(),
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

  // TODO: Always include the last turn, even if finishing the game early during
  // explanation or review.
  Future<void> finishGame({int? lastTurnIndex, TurnRecord? lastTurnRecord}) {
    Assert.holds(isActivePlayer(),
        message: 'Only the active player can change game state');
    localGameData.gameReference.clearLocalCache();
    return localGameData.gameReference.updateColumns([
      DBColGamePhase().setValue(GamePhase.gameOver),
      DBColCurrentTurn().setValue(null),
      if (lastTurnIndex != null)
        DBColTurnRecord(lastTurnIndex).setValue(lastTurnRecord!),
    ]);
  }

  Future<void> setWordStatus(WordId wordId, WordStatus newStatus) {
    return _updateTurnState(
        (_transformer..setWordStatus(wordId, newStatus)).turnState);
  }

  Future<void> setWordFeedback(WordId wordId, WordFeedback? newFeedback) {
    return _updatePersonalState((_personalTransformer
          ..setWordFeedback(wordId, newFeedback))
        .personalState);
  }

  Future<void> setWordFlag(WordId wordId, bool hasFlag) {
    return _updatePersonalState(
        (_personalTransformer..setWordFlag(wordId, hasFlag)).personalState);
  }
}
