import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/assertion.dart';

enum GamePhase {
  // Normal phases
  configure,
  play,
  gameOver,

  // Special phases
  kicked,
}

class GamePhaseReader {
  static GamePhase getPhase(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    final gamePhase = _getPhaseImpl(localGameData, snapshot);
    _checkDB(snapshot, gamePhase);
    return gamePhase;
  }

  static GamePhase _getPhaseImpl(
      LocalGameData localGameData, DBDocumentSnapshot snapshot) {
    final personalState =
        snapshot.tryGet(DBColPlayer(localGameData.myPlayerID));
    if (personalState?.kicked ?? false) {
      return GamePhase.kicked;
    }
    if (snapshot.containsNonNull(DBColInitialState())) {
      if (snapshot.containsNonNull(DBColCurrentTurn())) {
        return GamePhase.play;
      } else {
        return GamePhase.gameOver;
      }
    } else {
      return GamePhase.configure;
    }
  }

  static _checkDB(DBDocumentSnapshot snapshot, GamePhase phase) {
    switch (phase) {
      case GamePhase.configure:
        Assert.holds(snapshot.containsNonNull(DBColConfig()));
        Assert.holds(!snapshot.containsNonNull(DBColInitialState()));
        Assert.holds(!snapshot.containsNonNull(DBColCurrentTurn()));
        break;
      case GamePhase.play:
        Assert.holds(snapshot.containsNonNull(DBColConfig()));
        Assert.holds(snapshot.containsNonNull(DBColInitialState()));
        Assert.holds(snapshot.containsNonNull(DBColCurrentTurn()));
        break;
      case GamePhase.gameOver:
        Assert.holds(snapshot.containsNonNull(DBColConfig()));
        Assert.holds(snapshot.containsNonNull(DBColInitialState()));
        Assert.holds(!snapshot.containsNonNull(DBColCurrentTurn()));
        break;
      case GamePhase.kicked:
        break;
    }
  }
}
