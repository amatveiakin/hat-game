import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/util/assertion.dart';

class GameConfigController {
  final LocalGameData localGameData;
  final GameConfig rawConfig;
  final BuiltList<PersonalState> playerStates; // online-only

  bool get isReadOnly => !localGameData.isAdmin;

  bool get isInitialized =>
      rawConfig != null &&
      (playerStates == null || playerStates.length > localGameData.myPlayerID);

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

  static GameConfig initialConfig() {
    return LocalStorage.instance.get(LocalColLastConfig()) ?? defaultConfig();
  }

  GameConfig configWithOverrides() {
    return rawConfig.players != null || playerStates == null
        ? rawConfig
        : rawConfig.rebuild((b) => b
          ..players.replace(PlayersConfig(
            (b) => b
              ..names.replace(Map.fromEntries(playerStates
                  .where((e) => !(e.kicked ?? false))
                  .map((p) => MapEntry(p.id, p.name)))),
          )));
  }

  GameConfigController._(
      this.localGameData, this.rawConfig, this.playerStates) {
    if (isInitialized) {
      if (localGameData.onlineMode) {
        Assert.holds(rawConfig.players == null);
        Assert.holds(playerStates != null);
      } else {
        Assert.holds(rawConfig.players != null);
        Assert.holds(playerStates == null);
      }
    }
  }

  factory GameConfigController.fromSnapshot(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    Assert.holds(snapshot.exists);
    Assert.eq(
        GamePhaseReader.getPhase(localGameData, snapshot), GamePhase.configure);

    GameConfig rawConfig = snapshot.get(DBColConfig());
    BuiltList<PersonalState> playerStates;
    if (rawConfig.players == null && localGameData.onlineMode) {
      // This happens in online mode before the game has started.
      playerStates = BuiltList<PersonalState>.from(
          snapshot.getAll(DBColPlayerManager()).values());
    }

    return GameConfigController._(localGameData, rawConfig, playerStates);
  }

  void _checkWritesAllowed() {
    Assert.holds(!isReadOnly,
        message: 'Trying to update config while in read-only mode',
        inRelease: AssertInRelease.log);
  }

  void _updateLastConfig(GameConfig config) {
    // Best-effort, don't wait.
    LocalStorage.instance
        .set(LocalColLastConfig(), config.rebuild((b) => b..players = null));
  }

  Future<void> update(GameConfig Function(GameConfig) updater) {
    _checkWritesAllowed();
    final newRawConfig = updater(rawConfig);
    _updateLastConfig(newRawConfig);
    return localGameData.gameReference.updateColumns([
      DBColConfig().withData(newRawConfig),
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
