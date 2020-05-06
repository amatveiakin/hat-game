import 'dart:async';
import 'dart:convert';

import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/assertion.dart';

class GameConfigPlus {
  final GameConfig config;
  final bool gameHasStarted;

  GameConfigPlus(this.config, this.gameHasStarted);
}

class GameConfigReadResult {
  final GameConfig rawConfig;
  final Map<int, String> playerNamesOverrides;
  GameConfig get configWithOverrides =>
      rawConfig.players != null || playerNamesOverrides == null
          ? rawConfig
          : rawConfig.rebuild((b) => b
            ..players.replace(PlayersConfig(
              (b) => b..names.replace(playerNamesOverrides),
            )));

  GameConfigReadResult(this.rawConfig, this.playerNamesOverrides);
}

class GameConfigController {
  final LocalGameData localGameData;
  GameConfig _rawConfig;
  Map<int, String> _playerNamesOverrides;
  bool _gameHasStarted = false;
  final _streamController = StreamController<GameConfigPlus>(sync: true);

  Stream<GameConfigPlus> get stateUpdatesStream => _streamController.stream;
  bool get isReadOnly => !localGameData.isAdmin;

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

  GameConfigController.fromFirestore(this.localGameData) {
    localGameData.gameReference.snapshots().listen(
      _onUpdateFromDB,
      onError: (error) {
        Assert.fail('GameConfigController: Firestore error: $error');
      },
      onDone: () {
        Assert.fail('GameConfigController: Firestore updates stream aborted');
      },
    );
  }

  static GameConfigReadResult configFromSnapshot(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    Assert.holds(snapshot.exists);
    GameConfig rawConfig = snapshot.get(DBColConfig());
    Map<int, String> playerNamesOverrides;
    if (rawConfig.players == null && localGameData.onlineMode) {
      // This happens in online mode before the game has started.
      playerNamesOverrides = Map<int, String>();
      // TODO: Support gaps or check that there are none.
      for (int playerID = 0;; playerID++) {
        final playerColumn = DBColPlayer(playerID);
        if (!snapshot.contains(playerColumn)) {
          break;
        }
        playerNamesOverrides[playerID] = snapshot.get(playerColumn).name;
      }
    }
    return GameConfigReadResult(rawConfig, playerNamesOverrides);
  }

  GameConfig _configWithOverrides() {
    return GameConfigReadResult(_rawConfig, _playerNamesOverrides)
        .configWithOverrides;
  }

  GameConfigPlus _configPlus() =>
      GameConfigPlus(_configWithOverrides(), _gameHasStarted);

  void _onUpdateFromDB(final DBDocumentSnapshot snapshot) {
    GameConfigReadResult readResult =
        configFromSnapshot(localGameData, snapshot);
    // If config view starts lagging, a potential fix would be to skip
    // updating _rawConfig when `!isReadOnly`. Just be sure not to forget
    // about playerNamesOverrides and gameHasStarted!
    _rawConfig = readResult.rawConfig;
    _playerNamesOverrides = readResult.playerNamesOverrides;
    _gameHasStarted = snapshot.contains(DBColState());
    if (localGameData.onlineMode) {
      Assert.eq(_gameHasStarted, _rawConfig.players != null);
      Assert.eq(_gameHasStarted, _playerNamesOverrides == null);
    } else {
      Assert.holds(_playerNamesOverrides == null);
    }
    _streamController.add(_configPlus());
  }

  void _checkWritesAllowed() {
    Assert.holds(!isReadOnly,
        message: 'Trying to update config while in read-only mode',
        inRelease: AssertInRelease.log);
  }

  void update(GameConfig Function(GameConfig) updater) {
    _checkWritesAllowed();
    _rawConfig = updater(_rawConfig);
    localGameData.gameReference
        .updateColumns([DBColConfig().setData(_rawConfig)]);
    _streamController.add(_configPlus());
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
