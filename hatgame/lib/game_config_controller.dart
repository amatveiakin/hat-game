import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase_reader.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/util/assertion.dart';

class GameConfigController {
  final LocalGameData localGameData;
  final GameConfig rawConfig;
  final BuiltList<PersonalState>? playerStates; // online-only

  bool get isReadOnly => !localGameData.isAdmin;

  bool get isInitialized => (playerStates == null ||
      playerStates!.length > localGameData.myPlayerID!);

  static GameConfig defaultConfig() {
    return GameConfig(
      (b) => b
        ..rules.turnSeconds = 15
        ..rules.bonusSeconds = 5
        ..rules.variant = GameVariant.standard
        ..rules.extent = GameExtent.fixedWordSet
        ..rules.wordsPerPlayer = 5
        ..rules.numRounds = 3
        ..teaming.teamingStyle = TeamingStyle.individual
        ..teaming.numTeams = 2,
    );
  }

  static GameConfig _adaptForOfflineMode(GameConfig config) {
    return config.rebuild((b) {
      if (config.rules.variant == GameVariant.writeWords) {
        b.rules.variant = GameVariant.standard;
      }
      b.players.names.replace({});
    });
  }

  static GameConfig _adaptForOnlineMode(GameConfig config) {
    return config.rebuild((b) {
      if (config.teaming.teamingStyle == TeamingStyle.manualTeams) {
        b.teaming.teamingStyle = TeamingStyle.randomTeams;
      }
    });
  }

  static GameConfig fixGameExtentForGameVariant(GameConfig config) {
    return config.rebuild((b) {
      if (config.rules.variant == GameVariant.writeWords) {
        b.rules.extent = GameExtent.fixedWordSet;
      }
    });
  }

  static GameConfig fixPlayersForTeamingStyle(GameConfig config) {
    return config.rebuild((b) {
      final players = config.players;
      if (players != null) {
        if (config.teaming.teamingStyle == TeamingStyle.manualTeams) {
          if (players.teams == null) {
            b.players.teams.replace([BuiltList<int>(players.names.keys)]);
          }
        } else {
          b.players.teams = null;
        }
      }
    });
  }

  static GameConfig _fixDictionaries(GameConfig config) {
    return config.rebuild((b) {
      b.rules.dictionaries
          .replace(Lexicon.fixDictionaries(config.rules.dictionaries.toList()));
    });
  }

  static GameConfig _fix(GameConfig config) {
    return fixPlayersForTeamingStyle(
        fixGameExtentForGameVariant(_fixDictionaries(config)));
  }

  static GameConfig initialConfig({required bool onlineMode}) {
    final GameConfig config =
        LocalStorage.instance.get<GameConfig?>(LocalColLastConfig()) ??
            defaultConfig();
    // TODO: Do something to avoid breaking online-only and offline-only
    // fields in LocalColLastConfig.
    return _fix(onlineMode
        ? _adaptForOnlineMode(config)
        : _adaptForOfflineMode(config));
  }

  GameConfig configWithOverrides() {
    return rawConfig.players != null || playerStates == null
        ? rawConfig
        : rawConfig.rebuild((b) => b
          ..players.replace(PlayersConfig(
            (b) => b
              ..names.replace(Map.fromEntries(playerStates!
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
    Assert.isIn(GamePhaseReader.fromSnapshot(localGameData, snapshot),
        {GamePhase.configure, GamePhase.composeTeams, GamePhase.writeWords});

    GameConfig rawConfig = snapshot.get(DBColConfig());
    BuiltList<PersonalState>? playerStates;
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
      DBColConfig().setValue(newRawConfig),
    ], localCache: LocalCacheBehavior.cache);
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

  void updatePlayers(PlayersConfig Function(PlayersConfig?) updater) {
    update((config) => config.rebuild(
          (b) => b..players.replace(updater(config.players)),
        ));
  }
}
