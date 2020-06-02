import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/assertion.dart';

class GamePhaseReader {
  static GamePhase fromSnapshot(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    final gamePhase = _getPhase(snapshot, localGameData: localGameData);
    _checkDB(snapshot, gamePhase);
    return gamePhase;
  }

  static GamePhase fromSnapshotNoPersonal(DBDocumentSnapshot snapshot) {
    final gamePhase = _getPhase(snapshot);
    _checkDB(snapshot, gamePhase);
    return gamePhase;
  }

  static GamePhase _getPhase(DBDocumentSnapshot snapshot,
      {LocalGameData localGameData}) {
    if (localGameData != null) {
      final personalState =
          snapshot.tryGet(DBColPlayer(localGameData.myPlayerID));
      if (personalState?.kicked ?? false) {
        return GamePhase.kicked;
      }
    }
    if (snapshot.containsNonNull(DBColRematchNextGameID())) {
      return GamePhase.rematch;
    }
    return snapshot.get(DBColGamePhase());
  }

  static _checkDB(DBDocumentSnapshot snapshot, GamePhase phase) {
    Assert.withContext(
      context: () => snapshot.toString(),
      body: () {
        switch (phase) {
          case GamePhase.configure:
          case GamePhase.writeWords:
            Assert.holds(snapshot.containsNonNull(DBColConfig()));
            Assert.holds(!snapshot.containsNonNull(DBColTeamCompositions()));
            Assert.holds(!snapshot.containsNonNull(DBColInitialState()));
            Assert.holds(!snapshot.containsNonNull(DBColCurrentTurn()));
            break;
          case GamePhase.composeTeams:
            Assert.holds(snapshot.containsNonNull(DBColConfig()));
            Assert.holds(snapshot.containsNonNull(DBColTeamCompositions()));
            Assert.holds(!snapshot.containsNonNull(DBColInitialState()));
            Assert.holds(!snapshot.containsNonNull(DBColCurrentTurn()));
            break;
          case GamePhase.play:
            Assert.holds(snapshot.containsNonNull(DBColConfig()));
            Assert.holds(!snapshot.containsNonNull(DBColTeamCompositions()));
            Assert.holds(snapshot.containsNonNull(DBColInitialState()));
            Assert.holds(snapshot.containsNonNull(DBColCurrentTurn()));
            break;
          case GamePhase.gameOver:
            Assert.holds(snapshot.containsNonNull(DBColConfig()));
            Assert.holds(!snapshot.containsNonNull(DBColTeamCompositions()));
            Assert.holds(snapshot.containsNonNull(DBColInitialState()));
            Assert.holds(!snapshot.containsNonNull(DBColCurrentTurn()));
            break;
          case GamePhase.kicked:
          case GamePhase.rematch:
            break;
        }
      },
    );
  }
}
