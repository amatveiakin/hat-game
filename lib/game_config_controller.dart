import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/db_columns.dart';
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
  bool get gameHasStarted => rawConfig.players != null;
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
  // bool _gameHasStarted = false;
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

  // TODO: Remove after prod release.
  static GameConfig devConfig() {
    return defaultConfig().rebuild(
      (b) => b
        ..rules.turnSeconds = 5
        ..rules.bonusSeconds = 3
        ..rules.wordsPerPlayer = 1
        ..players.names.replace(['Vasya', 'Petya', 'Masha', 'Dasha']),
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

  static GameConfigReadResult configFromSnapshot(DocumentSnapshot snapshot) {
    Assert.holds(snapshot.data != null);
    GameConfig rawConfig = dbGet(snapshot, DBColConfig());
    Map<int, String> playerNamesOverrides;
    if (rawConfig.players == null) {
      // This happens in online mode before the game has started.
      playerNamesOverrides = Map<int, String>();
      // TODO: Support gaps or check that there are none.
      for (int playerID = 0;; playerID++) {
        final playerColumn = DBColPlayer(playerID);
        if (!dbContains(snapshot, playerColumn)) {
          break;
        }
        playerNamesOverrides[playerID] = dbGet(snapshot, playerColumn).name;
      }
    }
    return GameConfigReadResult(rawConfig, playerNamesOverrides);
  }

  GameConfig _configWithOverrides() {
    return GameConfigReadResult(_rawConfig, _playerNamesOverrides)
        .configWithOverrides;
  }

  GameConfigPlus _configPlus() =>
      GameConfigPlus(_configWithOverrides(), _rawConfig.players != null);

  void _onUpdateFromDB(final DocumentSnapshot snapshot) {
    GameConfigReadResult readResult = configFromSnapshot(snapshot);
    // If config view starts lagging, a potential fix would be to skip
    // updating _rawConfig when `!isReadOnly`. Just be sure not to forget
    // about playerNamesOverrides and gameHasStarted!
    _rawConfig = readResult.rawConfig;
    _playerNamesOverrides = readResult.playerNamesOverrides;
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
        .updateData(dbData([DBColConfig().setData(_rawConfig)]));
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
