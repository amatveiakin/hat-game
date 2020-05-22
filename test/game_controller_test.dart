import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:hatgame/util/ntp_time.dart';

class AppConfig {
  bool hasNtp = true;
}

void setupApp(AppConfig config) {
  LocalStorage.test_init();
  NtpTime.test_setInitialized(config.hasNtp);
}

const awaitPhaseTimeout = Duration(seconds: 3);

class Client {
  LocalGameData localGameData;

  Future<GamePhase> gamePhase() async {
    final snapshot = await localGameData.gameReference.get();
    return GamePhaseReader.getPhase(localGameData, snapshot);
  }

  Future<GameConfigController> configController() async {
    final snapshot = await localGameData.gameReference.get();
    return GameConfigController.fromSnapshot(localGameData, snapshot);
  }

  Future<GameController> controller() async {
    final snapshot = await localGameData.gameReference.get();
    return GameController.fromSnapshot(localGameData, snapshot);
  }
}

GameConfig twoVsTwoOfflineConfig() {
  return GameConfigController.defaultConfig().rebuild(
    (b) => b
      ..players
          .names
          .replace({0: 'PlayerA', 1: 'PlayerB', 2: 'PlayerC', 3: 'PlayerD'})
      ..rules.wordsPerPlayer = 1,
  );
}

Future<void> minimalOfflineGameTest() async {
  final client = Client();
  client.localGameData = await GameController.newOffineGame();
  await GameController.startGame(
      client.localGameData.gameReference, twoVsTwoOfflineConfig());

  await (await client.controller()).startExplaning();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).nextTurn();

  expect((await client.controller()).gameData.gameFinished(), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final firestoreInstance = MockFirestoreInstance();

  group('e2e offline', () {
    test('minimal game', () async {
      setupApp(AppConfig());
      await minimalOfflineGameTest();
    });

    test('sample 2 vs 2 game', () async {
      setupApp(AppConfig());
      final client = Client();
      client.localGameData = await GameController.newOffineGame();
      await GameController.startGame(
          client.localGameData.gameReference, twoVsTwoOfflineConfig());

      await (await client.controller()).startExplaning();
      final int w0 =
          (await client.controller()).turnState.wordsInThisTurn.last.id;
      await (await client.controller()).wordGuessed();
      final int w1 =
          (await client.controller()).turnState.wordsInThisTurn.last.id;
      await (await client.controller()).wordGuessed();
      await (await client.controller()).wordGuessed();
      // Last word is already pulled from the hat, although not guessed.
      expect((await client.controller()).gameData.numWordsInHat(), equals(0));
      await (await client.controller()).finishExplanation();
      await (await client.controller()).setWordStatus(w0, WordStatus.discarded);
      await (await client.controller())
          .setWordStatus(w1, WordStatus.notExplained);
      await (await client.controller()).nextTurn();
      // One word wasn't guessed to begin with and one was returned to the hat.
      expect((await client.controller()).gameData.numWordsInHat(), equals(2));

      expect((await client.controller()).turnState.turnPhase,
          equals(TurnPhase.prepare));
      await (await client.controller()).startExplaning();
      expect((await client.controller()).turnState.turnPhase,
          equals(TurnPhase.explain));
      await (await client.controller()).wordGuessed();
      expect((await client.controller()).turnState.turnPhase,
          equals(TurnPhase.explain));
      await (await client.controller()).wordGuessed();
      expect((await client.controller()).turnState.turnPhase,
          equals(TurnPhase.review));
      await (await client.controller()).nextTurn();
      expect((await client.controller()).gameData.gameFinished(), isTrue);
      final scoreData = (await client.controller()).gameData.scoreData();
      expect(scoreData.length, equals(2));
      expect(scoreData[0].totalScore, equals(2));
      expect(scoreData[1].totalScore, equals(1));
    });

    test('no NTP', () async {
      setupApp(AppConfig()..hasNtp = false);
      await minimalOfflineGameTest();
    });
  });

  group('e2e online', () {
    test('simple game', () async {
      setupApp(AppConfig());
      final host = Client();
      final guest = Client();

      host.localGameData =
          await GameController.newLobby(firestoreInstance, 'user_host');
      guest.localGameData = await GameController.joinLobby(
          firestoreInstance, 'user_guest', host.localGameData.gameID);

      await (await host.configController()).update((config) => config.rebuild(
            (b) => b
              ..teaming.teamPlay = false
              ..rules.wordsPerPlayer = 2,
          ));

      // Don't shuffle players, so that host explains first.
      final MockShuffler<int> shuffler = (l) => l;

      await GameController.startGame(host.localGameData.gameReference,
          (await host.configController()).configWithOverrides(),
          individualOrderMockShuffler: shuffler);

      await (await host.controller()).startExplaning();
      await (await host.controller()).finishExplanation();
      await (await host.controller()).nextTurn();

      await (await guest.controller()).startExplaning();
      await (await guest.controller()).wordGuessed();
      await (await guest.controller()).wordGuessed();
      await (await guest.controller()).wordGuessed();
      await (await guest.controller()).finishExplanation();
      await (await guest.controller()).nextTurn();

      await (await host.controller()).startExplaning();
      await (await host.controller()).wordGuessed();
      await (await host.controller()).nextTurn();

      expect((await host.controller()).gameData.gameFinished(), isTrue);
      expect((await guest.controller()).gameData.gameFinished(), isTrue);
    });

    test('kick player', () async {
      setupApp(AppConfig());
      final host = Client();
      final user1 = Client();
      final user2 = Client();

      host.localGameData =
          await GameController.newLobby(firestoreInstance, 'user_0');

      user1.localGameData = await GameController.joinLobby(
          firestoreInstance, 'user_1', host.localGameData.gameID);
      expect(user1.localGameData.myPlayerID, equals(1));

      await GameController.kickPlayer(host.localGameData.gameReference, 1);

      user2.localGameData = await GameController.joinLobby(
          firestoreInstance, 'user_2', host.localGameData.gameID);
      expect(user2.localGameData.myPlayerID, equals(2));

      expect(await user1.gamePhase(), equals(GamePhase.kicked));
      expect(await user2.gamePhase(), isNot(equals(GamePhase.kicked)));

      await (await host.configController()).update((config) => config.rebuild(
            (b) => b..teaming.teamPlay = false,
          ));

      await GameController.startGame(host.localGameData.gameReference,
          (await host.configController()).configWithOverrides());

      expect((await host.controller()).initialState.individualOrder.asList(),
          unorderedEquals([0, 2]));
      final party = (await host.controller()).turnState.party;
      expect([party.performer] + party.recipients.toList(),
          unorderedEquals([0, 2]));
    });
  });
}
