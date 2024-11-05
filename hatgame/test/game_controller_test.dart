import 'package:built_collection/built_collection.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/team_compositions.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase_reader.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/util/ntp_time.dart';

class AppConfig {
  bool hasNtp = true;
}

Future<void> setupApp(AppConfig config) async {
  await Lexicon.init();
  LocalStorage.test_init();
  NtpTime.test_setInitialized(config.hasNtp);
}

const awaitPhaseTimeout = Duration(seconds: 3);

class Client {
  late LocalGameData localGameData;

  Future<GamePhase> gamePhase() async {
    final snapshot = await localGameData.gameReference.get();
    return GamePhaseReader.fromSnapshot(localGameData, snapshot);
  }

  Future<GameConfigController> configController() async {
    final snapshot = await localGameData.gameReference.get();
    return GameConfigController.fromSnapshot(localGameData, snapshot);
  }

  Future<GameController> controller() async {
    final snapshot = await localGameData.gameReference.get();
    return GameController.fromSnapshot(localGameData, snapshot);
  }

  Future<void> startGame(
      {GameConfig? config, TeamCompositions? teamCompositions}) async {
    if (config != null) {
      await localGameData.gameReference.updateColumns([
        DBColConfig().setValue(config),
      ]);
    }
    if (teamCompositions != null) {
      await localGameData.gameReference.updateColumns([
        DBColTeamCompositions().setValue(teamCompositions),
        DBColGamePhase().setValue(GamePhase.composeTeams),
      ]);
    }
    final snapshot = await localGameData.gameReference.get();
    await GameController.startGame(localGameData, snapshot);
  }
}

GameConfig twoVsTwoOfflineConfig() {
  return GameConfigController.defaultConfig().rebuild(
    (b) => b
      ..players
          .names
          .replace({0: 'PlayerA', 1: 'PlayerB', 2: 'PlayerC', 3: 'PlayerD'})
      ..teaming.teamingStyle = TeamingStyle.manualTeams
      ..rules.dictionaries.replace(Lexicon.defaultDictionaries())
      ..rules.wordsPerPlayer = 1,
  );
}

TeamCompositions twoVsTwoSimpleComposition() {
  return TeamCompositions(
    (b) => b
      ..teams.replace([
        BuiltList<int>([0, 1]),
        BuiltList<int>([2, 3])
      ]),
  );
}

TeamCompositions ascendingIndividualTurnOrder({required int numPlayers}) {
  return TeamCompositions(
    (b) => b..individualOrder.replace(List<int>.generate(numPlayers, (i) => i)),
  );
}

// TODO: Hook this into all DB writes automatically for invariant checks.
Future<GamePhase> getGamePhase(LocalGameData localGameData) async {
  final DBDocumentSnapshot snapshot = await localGameData.gameReference.get();
  return GamePhaseReader.fromSnapshot(localGameData, snapshot);
}

Future<void> minimalOfflineGameTest() async {
  final client = Client();
  client.localGameData = await GameController.newGameOffine();
  await client.startGame(
      config: twoVsTwoOfflineConfig(),
      teamCompositions: twoVsTwoSimpleComposition());

  await (await client.controller()).startExplaning();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).wordGuessed();
  await (await client.controller()).nextTurn();

  expect((await client.controller()).gameData.gameFinished(), isTrue);
}

// TODO: Add tests for rematch.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final firestoreInstance = FakeFirebaseFirestore();

  group('e2e offline', () {
    test('minimal game', () async {
      await setupApp(AppConfig());
      await minimalOfflineGameTest();
    });

    test('sample 2 vs 2 game', () async {
      await setupApp(AppConfig());
      final client = Client();
      client.localGameData = await GameController.newGameOffine();
      await client.startGame(
          config: twoVsTwoOfflineConfig(),
          teamCompositions: twoVsTwoSimpleComposition());

      await (await client.controller()).startExplaning();
      final w0 = (await client.controller()).turnState!.wordsInThisTurn.last.id;
      await (await client.controller()).wordGuessed();
      final w1 = (await client.controller()).turnState!.wordsInThisTurn.last.id;
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

      expect((await client.controller()).turnState!.turnPhase,
          equals(TurnPhase.prepare));
      await (await client.controller()).startExplaning();
      expect((await client.controller()).turnState!.turnPhase,
          equals(TurnPhase.explain));
      await (await client.controller()).wordGuessed();
      expect((await client.controller()).turnState!.turnPhase,
          equals(TurnPhase.explain));
      await (await client.controller()).wordGuessed();
      expect((await client.controller()).turnState!.turnPhase,
          equals(TurnPhase.review));
      await (await client.controller()).nextTurn();
      expect((await client.controller()).gameData.gameFinished(), isTrue);
      final scoreData = (await client.controller()).gameData.scoreData();
      expect(scoreData.length, equals(2));
      expect(scoreData[0].totalScore, equals(2));
      expect(scoreData[1].totalScore, equals(1));
    });

    test('fixed number of rounds game', () async {
      await setupApp(AppConfig());
      final client = Client();
      client.localGameData = await GameController.newGameOffine();
      await client.startGame(
        config: GameConfigController.defaultConfig().rebuild((b) => b
          ..players.names.replace({0: 'PlayerA', 1: 'PlayerB'})
          ..teaming.teamingStyle = TeamingStyle.individual
          ..rules.dictionaries.replace(Lexicon.defaultDictionaries())
          ..rules.extent = GameExtent.fixedNumRounds
          ..rules.numRounds = 3),
        teamCompositions:
            TeamCompositions((b) => b..individualOrder.replace([0, 1])),
      );

      final playOneTurn = (int wordsGuessed) async {
        await (await client.controller()).startExplaning();
        for (var i = 0; i < wordsGuessed; i++) {
          await (await client.controller()).wordGuessed();
        }
        await (await client.controller()).finishExplanation();
        await (await client.controller()).nextTurn();
      };

      expect((await client.controller()).gameData.gameFinished(), isFalse);
      expect((await client.controller()).gameData.numWordsInHat(), isNull);
      expect((await client.controller()).gameData.gameProgress(),
          equals(FixedNumRoundsProgress(0, 3, 0, 2)));

      await playOneTurn(1);
      expect((await client.controller()).gameData.gameFinished(), isFalse);
      expect((await client.controller()).gameData.gameProgress(),
          equals(FixedNumRoundsProgress(0, 3, 1, 2)));

      await playOneTurn(10);
      expect((await client.controller()).gameData.gameFinished(), isFalse);
      expect((await client.controller()).gameData.gameProgress(),
          equals(FixedNumRoundsProgress(1, 3, 0, 2)));

      await playOneTurn(1);
      await playOneTurn(20);
      await playOneTurn(1);
      await playOneTurn(0);
      expect((await client.controller()).gameData.gameFinished(), isTrue);

      final scoreData = (await client.controller()).gameData.scoreData();
      expect(scoreData.length, equals(2));
      expect(scoreData[0].totalScore, equals(33));
      expect(scoreData[0].players[0].wordsExplained, equals(3));
      expect(scoreData[1].totalScore, equals(33));
      expect(scoreData[1].players[0].wordsExplained, equals(30));
    });

    test('no NTP', () async {
      await setupApp(AppConfig()..hasNtp = false);
      await minimalOfflineGameTest();
    });
  });

  group('e2e online', () {
    test('simple game', () async {
      await setupApp(AppConfig());
      final host = Client();
      final guest = Client();

      host.localGameData =
          await GameController.newLobby(firestoreInstance, 'user_host');
      guest.localGameData = (await GameController.joinLobby(
              firestoreInstance, 'user_guest', host.localGameData.gameID))
          .localGameData;

      await (await host.configController()).update((config) => config.rebuild(
            (b) => b
              ..teaming.teamingStyle = TeamingStyle.individual
              ..rules.wordsPerPlayer = 2,
          ));

      await host.startGame(
          teamCompositions: ascendingIndividualTurnOrder(numPlayers: 2));

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
      await setupApp(AppConfig());
      final host = Client();
      final user1 = Client();
      final user2 = Client();

      host.localGameData =
          await GameController.newLobby(firestoreInstance, 'user_0');

      user1.localGameData = (await GameController.joinLobby(
              firestoreInstance, 'user_1', host.localGameData.gameID))
          .localGameData;
      expect(user1.localGameData.myPlayerID, equals(1));

      await GameController.kickPlayer(host.localGameData.gameReference, 1);

      user2.localGameData = (await GameController.joinLobby(
              firestoreInstance, 'user_2', host.localGameData.gameID))
          .localGameData;
      expect(user2.localGameData.myPlayerID, equals(2));

      expect(await user1.gamePhase(), equals(GamePhase.kicked));
      expect(await user2.gamePhase(), isNot(equals(GamePhase.kicked)));

      await (await host.configController()).update((config) => config.rebuild(
            (b) => b..teaming.teamingStyle = TeamingStyle.individual,
          ));
      final config = (await host.configController()).configWithOverrides();

      await GameController.updateTeamCompositions(
          host.localGameData.gameReference, config);
      final teamCompositions = (await host.localGameData.gameReference.get())
          .get(DBColTeamCompositions());
      expect(teamCompositions!.individualOrder, unorderedEquals([0, 2]));

      await host.startGame();

      final party = (await host.controller()).turnState!.party;
      expect([party.performer] + party.recipients.toList(),
          unorderedEquals([0, 2]));
    });

    test('go to and from team compositions', () async {
      await setupApp(AppConfig());
      final host = Client();
      final guest = Client();

      host.localGameData =
          await GameController.newLobby(firestoreInstance, 'user_host');
      expect(
          await getGamePhase(host.localGameData), equals(GamePhase.configure));

      guest.localGameData = (await GameController.joinLobby(
              firestoreInstance, 'user_guest', host.localGameData.gameID))
          .localGameData;
      expect(
          await getGamePhase(host.localGameData), equals(GamePhase.configure));

      await (await host.configController()).update((config) => config
          .rebuild((b) => b..teaming.teamingStyle = TeamingStyle.individual));
      expect(
          await getGamePhase(host.localGameData), equals(GamePhase.configure));

      await GameController.updateTeamCompositions(
          host.localGameData.gameReference,
          (await host.configController()).configWithOverrides());
      expect(await getGamePhase(host.localGameData),
          equals(GamePhase.composeTeams));

      await GameController.discardTeamCompositions(
          host.localGameData.gameReference);
      expect(
          await getGamePhase(host.localGameData), equals(GamePhase.configure));

      await GameController.updateTeamCompositions(
          host.localGameData.gameReference,
          (await host.configController()).configWithOverrides());
      expect(await getGamePhase(host.localGameData),
          equals(GamePhase.composeTeams));

      await host.startGame(
          teamCompositions: ascendingIndividualTurnOrder(numPlayers: 2));
      expect(await getGamePhase(host.localGameData), equals(GamePhase.play));
    });

    test('write words', () async {
      await setupApp(AppConfig());
      final host = Client();
      final guest = Client();

      host.localGameData =
          await GameController.newLobby(firestoreInstance, 'user_host');
      guest.localGameData = (await GameController.joinLobby(
              firestoreInstance, 'user_guest', host.localGameData.gameID))
          .localGameData;

      await (await host.configController()).update((config) => config.rebuild(
            (b) => b
              ..teaming.teamingStyle = TeamingStyle.individual
              ..rules.wordsPerPlayer = 1
              ..rules.variant = GameVariant.writeWords,
          ));

      {
        final wordWritingViewData = GameController.getWordWritingViewData(
            host.localGameData, await host.localGameData.gameReference.get());
        await GameController.updatePersonalState(
            host.localGameData,
            wordWritingViewData.playerState.rebuild(
              (b) => b
                ..words.replace(['foo'])
                ..wordsReady = true,
            ));
      }
      {
        final wordWritingViewData = GameController.getWordWritingViewData(
            host.localGameData, await host.localGameData.gameReference.get());
        expect(wordWritingViewData.numPlayersReady, equals(1));
      }
      {
        final wordWritingViewData = GameController.getWordWritingViewData(
            guest.localGameData, await guest.localGameData.gameReference.get());
        await GameController.updatePersonalState(
            guest.localGameData,
            wordWritingViewData.playerState.rebuild(
              (b) => b
                ..words.replace(['bar'])
                ..wordsReady = true,
            ));
      }
      {
        final wordWritingViewData = GameController.getWordWritingViewData(
            host.localGameData, await host.localGameData.gameReference.get());
        expect(wordWritingViewData.numPlayersReady, equals(2));
      }

      await host.startGame(
          teamCompositions: ascendingIndividualTurnOrder(numPlayers: 2));

      await (await host.controller()).startExplaning();
      final word = (await host.controller()).gameData.currentWordContent();
      expect(word.text, isIn(['foo', 'bar']));
    });
  });
}
