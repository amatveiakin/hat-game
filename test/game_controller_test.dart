import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/ntp_time.dart';

class AppConfig {
  bool hasNtp = true;
}

void setupApp(AppConfig config) {
  NtpTime.test_setInitialized(config.hasNtp);
}

class Client {
  LocalGameData localGameData;
  GameController controller;

  Future<void> createGameController() async {
    controller = GameController.fromDB(localGameData);
    await controller.testAwaitInitialized();
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
  LocalGameData localGameData = await GameController.newOffineGame();
  await GameController.startGame(
      localGameData.gameReference, twoVsTwoOfflineConfig());
  final controller = GameController.fromDB(localGameData);
  await controller.testAwaitInitialized();

  await controller.startExplaning();
  await controller.wordGuessed();
  await controller.wordGuessed();
  await controller.wordGuessed();
  await controller.wordGuessed();
  await controller.nextTurn();

  expect(controller.gameData.gameFinished(), isTrue);
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
      LocalGameData localGameData = await GameController.newOffineGame();
      await GameController.startGame(
          localGameData.gameReference, twoVsTwoOfflineConfig());
      final controller = GameController.fromDB(localGameData);
      await controller.testAwaitInitialized();

      await controller.startExplaning();
      final int w0 = controller.turnState.wordsInThisTurn.last.id;
      await controller.wordGuessed();
      final int w1 = controller.turnState.wordsInThisTurn.last.id;
      await controller.wordGuessed();
      await controller.wordGuessed();
      // Last word is already pulled from the hat, although not guessed.
      expect(controller.gameData.numWordsInHat(), equals(0));
      await controller.finishExplanation();
      await controller.setWordStatus(w0, WordStatus.discarded);
      await controller.setWordStatus(w1, WordStatus.notExplained);
      await controller.nextTurn();
      // One word wasn't guessed to begin with and one was returned to the hat.
      expect(controller.gameData.numWordsInHat(), equals(2));

      expect(controller.turnState.turnPhase, equals(TurnPhase.prepare));
      await controller.startExplaning();
      expect(controller.turnState.turnPhase, equals(TurnPhase.explain));
      await controller.wordGuessed();
      expect(controller.turnState.turnPhase, equals(TurnPhase.explain));
      await controller.wordGuessed();
      expect(controller.turnState.turnPhase, equals(TurnPhase.review));
      await controller.nextTurn();
      expect(controller.gameData.gameFinished(), isTrue);
      final scoreData = controller.gameData.scoreData();
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

      final configController = GameConfigController.fromDB(host.localGameData);
      await configController.testAwaitInitialized();
      await configController.update((config) => config.rebuild(
            (b) => b
              ..teaming.teamPlay = false
              ..rules.wordsPerPlayer = 2,
          ));

      await GameController.startGame(host.localGameData.gameReference,
          configController.configWithOverrides());
      await host.createGameController();
      await guest.createGameController();

      await host.controller.startExplaning();
      await host.controller.finishExplanation();
      await host.controller.nextTurn();

      await guest.controller.startExplaning();
      await guest.controller.wordGuessed();
      await guest.controller.wordGuessed();
      await guest.controller.wordGuessed();
      await guest.controller.finishExplanation();
      await guest.controller.nextTurn();

      await host.controller.startExplaning();
      await host.controller.wordGuessed();
      await host.controller.nextTurn();

      expect(host.controller.gameData.gameFinished(), isTrue);
      expect(guest.controller.gameData.gameFinished(), isTrue);
    });
  });
}
