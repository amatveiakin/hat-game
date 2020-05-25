import 'package:flutter/material.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/kicked_screen.dart';
import 'package:hatgame/score_view.dart';
import 'package:hatgame/start_screen.dart';
import 'package:hatgame/team_compositions_view.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/async_snapshot_error.dart';

enum _GameNavigationState {
  none,
  expected,
  requested,
}

// We never pop the the previous game stage directly: this is done only
// through the navigator.
enum _PopResponse {
  disabled,
  custom,
  exitGame,
}

class _Destination {
  final MaterialPageRoute route;
  final GamePhase parent; // pop action target (optional)

  _Destination(this.route, {this.parent});
}

// OPTIMIZATION POTENTIAL: This class might be simplified when Navigator 2.0
//   is out: https://github.com/flutter/flutter/issues/45938.
// TODO: Don't show loading indicator when loading is very fast. Idea:
//   prefetch the first state for half-second and start navigation afterwards;
//   show a screenshot meanwhile or show widgets based on the latest state
//   for the current phase and block interactions.
// TODO: Consider setting maintainState == false.
// TODO: Is it ok that GameNavigator smuggles state into StalelessWidget?
//   May be GameNavigator should be a mixin on top of StatefulWidget.
class GameNavigator {
  final GamePhase currentPhase;
  _GameNavigationState _navigationState = _GameNavigationState.none;

  GameNavigator({
    @required this.currentPhase,
  });

  // TODO: Allow re-join game in the middle, use this.
  /*
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
  */

  Widget buildWrapper({
    @required BuildContext context,
    @required LocalGameData localGameData,
    @required Widget Function(BuildContext, DBDocumentSnapshot) buildBody,
    void Function() onBackPressed,
  }) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context,
          localGameData: localGameData, onBackPressed: onBackPressed),
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
              _navigationState != _GameNavigationState.requested) {
            _navigationState = _GameNavigationState.requested;
            Future(() => _navigate(
                  context: context,
                  localGameData: localGameData,
                  oldPhase: currentPhase,
                  newPhase: newPhase,
                ));
          }
          if (_navigationState != _GameNavigationState.none) {
            return Center(child: CircularProgressIndicator());
          }
          Assert.eq(newPhase, currentPhase);
          return buildBody(context, snapshot.data);
        },
      ),
    );
  }

  // Call when a user action means navigation is inevitable.
  // TODO: Use this widely or delete.
  // TODO: Shouldn't this be called only inside setState()?
  /*
  void setNavigationExpected() {
    Assert.eq(_navigationState, _GameNavigationState.none);
    _navigationState = _GameNavigationState.expected;
  }
  */

  Future<void> _navigate({
    @required BuildContext context,
    @required LocalGameData localGameData,
    @required GamePhase oldPhase,
    @required GamePhase newPhase,
  }) async {
    await localGameData.gameReference.assertLocalCacheIsEmpty();
    // Hide virtual keyboard
    FocusScope.of(context).unfocus();
    _Destination oldDest =
        _destination(localGameData: localGameData, phase: oldPhase);
    _Destination newDest =
        _destination(localGameData: localGameData, phase: newPhase);
    if (newPhase == oldDest.parent) {
      Navigator.of(context).pop(); // does not trigger `onWillPop`
      return;
    }
    if (newDest.parent != null) {
      Assert.eq(newDest.parent, oldPhase);
      Navigator.of(context).push(
        newDest.route,
      );
      // Reset _navigationState to allow navigating from this screen again if
      // the user goes back to it. Don't reset _navigationState immediately,
      // as in this case navigation to the next page happens multiple times.
      newDest.route.popped.then((_) {
        _navigationState = _GameNavigationState.none;
      });
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        newDest.route,
        ModalRoute.withName('/'),
      );
    }
  }

  static _Destination _destination({
    @required LocalGameData localGameData,
    @required GamePhase phase,
  }) {
    switch (phase) {
      case GamePhase.configure:
        return _Destination(
          MaterialPageRoute(
            builder: (context) => GameConfigView(localGameData: localGameData),
            settings: RouteSettings(name: GameConfigView.routeName),
          ),
        );
      case GamePhase.composeTeams:
        return _Destination(
          MaterialPageRoute(
            builder: (context) =>
                TeamCompositionsView(localGameData: localGameData),
            settings: RouteSettings(name: TeamCompositionsView.routeName),
          ),
          parent: GamePhase.configure,
        );
      case GamePhase.play:
        return _Destination(
          MaterialPageRoute(
            builder: (context) => GameView(localGameData: localGameData),
            settings: RouteSettings(name: GameView.routeName),
          ),
        );
      case GamePhase.gameOver:
        return _Destination(
          MaterialPageRoute(
            builder: (context) => ScoreView(localGameData: localGameData),
            settings: RouteSettings(name: ScoreView.routeName),
          ),
        );
      case GamePhase.kicked:
        return _Destination(
          MaterialPageRoute(
            builder: (context) => KickedScreen(),
            settings: RouteSettings(name: KickedScreen.routeName),
          ),
        );
    }
    Assert.fail('Unexpected GamePhase: $phase');
  }

  Future<_PopResponse> _confimLeaveGame(
    BuildContext context, {
    @required LocalGameData localGameData,
  }) {
    // TODO: Change text for offline game.
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: Text('Leave game?'),
            // TODO: Replace with a description of how to re-join / continue
            // when it's possible to re-join / continue.
            content: Text(localGameData.onlineMode
                ? "You wouldn't be able to join back "
                    "(this is not implemented yet)"
                : "You wouldn't be able to continue "
                    "(this is not implemented yet)"),
            actions: [
              FlatButton(
                child: Text('Stay'),
                onPressed: () =>
                    Navigator.of(context).pop(_PopResponse.disabled),
              ),
              FlatButton(
                child: Text('Leave'),
                onPressed: () =>
                    Navigator.of(context).pop(_PopResponse.exitGame),
              ),
            ],
          ),
        ) ??
        _PopResponse.disabled;
  }

  Future<bool> _onWillPop(
    BuildContext context, {
    @required LocalGameData localGameData,
    void Function() onBackPressed,
  }) async {
    final popResponse =
        await _popResponse(context, localGameData: localGameData);
    switch (popResponse) {
      case _PopResponse.disabled:
        break;
      case _PopResponse.custom:
        onBackPressed();
        break;
      case _PopResponse.exitGame:
        _navigationState = _GameNavigationState.expected;
        // This would look better with a pop animation, something like:
        //     Navigator.of(context).popUntil((route) => route.isFirst);
        // However it doesn't work, because it triggers `route.popped`, which
        // reset navigation state. When Navigator 2.0 is out, this logic could
        // be replaced with remove_underlying_routes + pop.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => StartScreen(),
            settings: RouteSettings(name: StartScreen.routeName),
          ),
          (route) => true,
        );
        break;
    }
    return false;
  }

  Future<_PopResponse> _popResponse(
    BuildContext context, {
    @required LocalGameData localGameData,
  }) async {
    switch (currentPhase) {
      case GamePhase.configure:
        return localGameData.isAdmin
            ? _PopResponse.exitGame
            : _confimLeaveGame(context, localGameData: localGameData);
      case GamePhase.composeTeams:
        return localGameData.isAdmin
            ? _PopResponse.custom
            : _confimLeaveGame(context, localGameData: localGameData);
      case GamePhase.play:
        return _confimLeaveGame(context, localGameData: localGameData);
      case GamePhase.gameOver:
        return _PopResponse.exitGame;
      case GamePhase.kicked:
        return _PopResponse.exitGame;
    }
    Assert.fail('Unexpected game phase: $currentPhase');
  }
}
