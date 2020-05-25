import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/assertion.dart';

enum GamePhase {
  // Normal phases
  configure,
  composeTeams,
  play,
  gameOver,

  // Special phases
  kicked,
}

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
    if (snapshot.containsNonNull(DBColInitialState())) {
      if (snapshot.containsNonNull(DBColCurrentTurn())) {
        return GamePhase.play;
      } else {
        return GamePhase.gameOver;
      }
    } else if (snapshot.containsNonNull(DBColTeamCompositions())) {
      return GamePhase.composeTeams;
    } else {
      return GamePhase.configure;
    }
  }

  static _checkDB(DBDocumentSnapshot snapshot, GamePhase phase) {
    switch (phase) {
      case GamePhase.configure:
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
        break;
    }
  }
}
