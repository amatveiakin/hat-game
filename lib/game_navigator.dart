import 'package:flutter/material.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/kicked_screen.dart';
import 'package:hatgame/score_view.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/async_snapshot_error.dart';

enum GameNavigationState {
  none,
  expected,
  requested,
}

class GameNavigator {
  final GamePhase currentPhase;
  GameNavigationState _navigationState = GameNavigationState.none;

  GameNavigator({@required this.currentPhase});

  static Future<void> navigateToGame({
    @required BuildContext context,
    @required LocalGameData localGameData,
  }) async {
    final snapshot = await localGameData.gameReference.get();
    await _navigate(
      context: context,
      localGameData: localGameData,
      newPhase: GamePhaseReader.getPhase(localGameData, snapshot),
    );
  }

  Widget buildWrapper({
    @required BuildContext context,
    @required LocalGameData localGameData,
    @required Widget Function(BuildContext, DBDocumentSnapshot) buildBody,
  }) {
    return WillPopScope(
      onWillPop: () => _canPop(context),
      child: StreamBuilder<DBDocumentSnapshot>(
        stream: localGameData.gameReference.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DBDocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return AsyncSnapshotError(snapshot, gamePhase: currentPhase);
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final newPhase =
              GamePhaseReader.getPhase(localGameData, snapshot.data);
          if (newPhase != currentPhase &&
              _navigationState != GameNavigationState.requested) {
            _navigationState = GameNavigationState.requested;
            Future(() => _navigate(
                  context: context,
                  localGameData: localGameData,
                  oldPhase: currentPhase,
                  newPhase: newPhase,
                ));
          }
          if (_navigationState != GameNavigationState.none) {
            return Center(child: CircularProgressIndicator());
          }
          Assert.eq(newPhase, currentPhase);
          return buildBody(context, snapshot.data);
        },
      ),
    );
  }

  // Call when a user action means navigation is inevitable.
  void setNavigationRequested() {
    Assert.eq(_navigationState, GameNavigationState.none);
    _navigationState = GameNavigationState.expected;
  }

  static Future<void> _navigate({
    @required BuildContext context,
    @required LocalGameData localGameData,
    GamePhase oldPhase,
    @required GamePhase newPhase,
  }) async {
    await localGameData.gameReference.assertLocalCacheIsEmpty();
    // Hide virtual keyboard
    FocusScope.of(context).unfocus();
    switch (newPhase) {
      case GamePhase.configure:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => GameConfigView(localGameData: localGameData),
            settings: RouteSettings(name: GameConfigView.routeName),
          ),
          ModalRoute.withName('/'),
        );
        break;
      case GamePhase.play:
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => GameView(localGameData: localGameData),
              settings: RouteSettings(name: GameView.routeName),
            ),
            ModalRoute.withName('/'));
        break;
      case GamePhase.gameOver:
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ScoreView(localGameData: localGameData),
              settings: RouteSettings(name: ScoreView.routeName),
            ),
            ModalRoute.withName('/'));
        break;
      case GamePhase.kicked:
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => KickedScreen(),
              settings: RouteSettings(name: KickedScreen.routeName),
            ),
            ModalRoute.withName('/'));
        break;
    }
  }

  Future<bool> _confimLeaveGame(BuildContext context) {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: Text('Leave game?'),
            // TODO: Replace with a description of how to re-join when it's
            // possible to re-join.
            content: Text("You wouldn't be able to join back "
                "(this is not implemented yet)"),
            actions: [
              FlatButton(
                child: Text('Stay'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              FlatButton(
                child: Text('Leave'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _canPop(BuildContext context) {
    switch (currentPhase) {
      case GamePhase.configure:
        return Future.value(true);
      case GamePhase.play:
        return _confimLeaveGame(context);
      case GamePhase.gameOver:
        return Future.value(true);
      case GamePhase.kicked:
        return Future.value(true);
    }
    Assert.fail('Unexpected game phase: $currentPhase');
  }
}
