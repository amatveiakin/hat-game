import 'dart:async';

import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/future.dart';
import 'package:meta/meta.dart';

class GameConfigPlus {
  final GameConfig config;
  final bool gameHasStarted;
  final bool kicked;

  GameConfigPlus(
    this.config, {
    @required this.gameHasStarted,
    @required this.kicked,
  });
}

class GameConfigReadResult {
  final GameConfig rawConfig;
  final List<PersonalState> playerStates; // online-only
  GameConfig get configWithOverrides =>
      rawConfig.players != null || playerStates == null
          ? rawConfig
          : rawConfig.rebuild((b) => b
            ..players.replace(PlayersConfig(
              (b) => b
                ..names.replace(Map.fromEntries(playerStates
                    .where((e) => !(e.kicked ?? false))
                    .map((p) => MapEntry(p.id, p.name)))),
            )));

  GameConfigReadResult(this.rawConfig, this.playerStates);
}

class GameConfigController {
  final LocalGameData localGameData;
  GameConfig _rawConfig;
  List<PersonalState> _playerStates;
  bool _gameHasStarted = false;
  final _streamController = StreamController<GameConfigPlus>(sync: true);

  Stream<GameConfigPlus> get stateUpdatesStream => _streamController.stream;
  bool get isReadOnly => !localGameData.isAdmin;

  bool isInitialized() =>
      _rawConfig != null &&
      (_playerStates == null ||
          _playerStates.length > localGameData.myPlayerID);
  bool _kicked() =>
      _playerStates != null &&
      (_playerStates[localGameData.myPlayerID].kicked ?? false);

  static GameConfig defaultConfig() {
    return GameConfig(
      (b) => b
        ..rules.turnSeconds = 15
        ..rules.bonusSeconds = 5
        ..rules.wordsPerPlayer = 5
        ..teaming.teamPlay = true
        ..teaming.randomizeTeams = true
        ..teaming.individualPlayStyle = IndividualPlayStyle.fluidPairs
        ..teaming.desiredTeamSize = DesiredTeamSize.teamsOf2
        ..teaming.unequalTeamSize = UnequalTeamSize.forbid
        ..teaming.guessingInLargeTeam = IndividualPlayStyle.fluidPairs,
    );
  }

  GameConfigController.fromDB(this.localGameData) {
    localGameData.gameReference.snapshots().listen(
      _onUpdateFromDB,
      onError: (error) {
        Assert.fail('GameConfigController: DB error: $error');
      },
      onDone: () {
        Assert.fail('GameConfigController: DB updates stream aborted');
      },
    );
  }

  Future<void> testAwaitInitialized() {
    return FutureUtil.doWhileDelayed(() => !isInitialized());
  }

  static GameConfigReadResult configFromSnapshot(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    Assert.holds(snapshot.exists);
    GameConfig rawConfig = snapshot.get(DBColConfig());
    List<PersonalState> playerStates;
    if (rawConfig.players == null && localGameData.onlineMode) {
      // This happens in online mode before the game has started.
      playerStates = snapshot.getAll(DBColPlayerManager()).values().toList();
    }
    return GameConfigReadResult(rawConfig, playerStates);
  }

  GameConfig configWithOverrides() {
    return GameConfigReadResult(_rawConfig, _playerStates).configWithOverrides;
  }

  GameConfigPlus configPlus() => GameConfigPlus(
        configWithOverrides(),
        gameHasStarted: _gameHasStarted,
        kicked: _kicked(),
      );

  void _onUpdateFromDB(final DBDocumentSnapshot snapshot) {
    GameConfigReadResult readResult =
        configFromSnapshot(localGameData, snapshot);
    _playerStates = readResult.playerStates;
    _gameHasStarted = snapshot.contains(DBColInitialState());
    if (!isReadOnly && _rawConfig != null && !_gameHasStarted) {
      // Skip updating the config. The host is the only user who is updating
      // the config, so DB contains no information that we don't have. On
      // the other hand, information from DB can lag behing and cause UI
      // flickering if the config was updated many times in a row.
    } else {
      _rawConfig = readResult.rawConfig;
    }
    if (!isInitialized()) {
      return;
    }
    if (localGameData.onlineMode) {
      Assert.eq(_gameHasStarted, _rawConfig.players != null);
      Assert.eq(_gameHasStarted, _playerStates == null);
    } else {
      Assert.holds(_playerStates == null);
    }
    _streamController.add(configPlus());
  }

  void _checkWritesAllowed() {
    Assert.holds(!isReadOnly,
        message: 'Trying to update config while in read-only mode',
        inRelease: AssertInRelease.log);
  }

  Future<void> update(GameConfig Function(GameConfig) updater) {
    _checkWritesAllowed();
    _rawConfig = updater(_rawConfig);
    _streamController.add(configPlus());
    return localGameData.gameReference.updateColumns([
      DBColConfig().withData(_rawConfig),
    ]);
  }

  void updateRules(RulesConfig Function(RulesConfig) updater) {
    update((config) => config.rebuild(
          (b) => b..rules.replace(updater(config.rules)),
        ));
  }

  void updateTeaming(TeamingConfig Function(TeamingConfig) updater) {
    update((config) => config.rebuild(
          (b) => b..teaming.replace(updater(config.teaming)),
        ));
  }

  void updatePlayers(PlayersConfig Function(PlayersConfig) updater) {
    update((config) => config.rebuild(
          (b) => b..players.replace(updater(config.players)),
        ));
  }
}
