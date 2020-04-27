import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/serializers.dart';
import 'package:hatgame/db_constants.dart';
import 'package:hatgame/util/assertion.dart';

class GameConfigReadResult {
  final GameConfig config;
  final bool gameHasStarted;

  GameConfigReadResult(this.config, this.gameHasStarted);
}

class GameConfigController {
  final DocumentReference gameReference;

  GameConfigController(this.gameReference);

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

  static GameConfigReadResult configFromSnapshot(
      DocumentSnapshot documentSnapshot) {
    Assert.holds(documentSnapshot.data.containsKey(DBColumns.config),
        lazyMessage: () =>
            documentSnapshot.reference.path +
            ' -> ' +
            documentSnapshot.data.toString());
    GameConfig config = serializers
        .deserialize(json.decode(documentSnapshot.data[DBColumns.config]));
    bool gameHasStarted = true;
    // This happens in online mode before the game has started.
    if (config.players == null) {
      gameHasStarted = false;
      final playerNames = List<String>();
      for (int playerID = 0;; playerID++) {
        final String key = DBColumns.player(playerID);
        if (!documentSnapshot.data.containsKey(key)) {
          break;
        }
        playerNames.add(documentSnapshot.data[key]);
      }
      config = config.rebuild(
        (b) => b
          ..players.replace(PlayersConfig(
            (b) => b..names.replace(playerNames),
          )),
      );
    }
    return GameConfigReadResult(config, gameHasStarted);
  }

  void update(GameConfig Function(GameConfig) updater) {
    Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot snapshot = await tx.get(gameReference);
      final String oldValueSerialized = snapshot.data[DBColumns.config];
      final GameConfig oldValue =
          serializers.deserialize(json.decode(oldValueSerialized));
      final GameConfig newValue = updater(oldValue);
      final newValueSerialized = json.encode(serializers.serialize(newValue));
      await tx.update(gameReference,
          <String, dynamic>{DBColumns.config: newValueSerialized});
    });
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
