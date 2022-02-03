import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_phase_reader.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/kicked_screen.dart';
import 'package:hatgame/score_view.dart';
import 'package:hatgame/team_compositions_view.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/async_snapshot_error.dart';
import 'package:hatgame/widget/dialog.dart';
import 'package:hatgame/write_words_view.dart';

// We never pop the the previous game stage directly: this is done only
// through the navigator.
enum _PopResponse {
  disabled,
  custom,
  exitGame,
}

class RouteArguments {
  final GamePhase phase;

  RouteArguments({required this.phase});
}

// OPTIMIZATION POTENTIAL: This class might be simplified when Navigator 2.0
//   is out: https://github.com/flutter/flutter/issues/45938.
// TODO: Consider setting maintainState == false.
// TODO: Is it ok that GameNavigator smuggles state into StalelessWidget?
//   May be GameNavigator should be a mixin on top of StatefulWidget.
class GameNavigator {
  final GamePhase currentPhase;

  GameNavigator({
    required this.currentPhase,
  });

  // TODO: Disable bonus turn timer after reconnect.
  static Future<void> navigateToGame({
    required BuildContext context,
    required LocalGameData localGameData,
  }) async {
    final snapshot = await localGameData.gameReference.get();
    final gamePhase = GamePhaseReader.fromSnapshot(localGameData, snapshot);
    _navigateTo(
      context: context,
      localGameData: localGameData,
      snapshot: snapshot,
      oldPhase: null,
      newPhase: gamePhase,
    );
  }

  Widget buildWrapper({
    required BuildContext context,
    required LocalGameData localGameData,
    required Widget Function(BuildContext, DBDocumentSnapshot) buildBody,
    void Function()? onBackPressed,
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
          final snapshotData = snapshot.data!;
          final newPhase =
              GamePhaseReader.fromSnapshot(localGameData, snapshotData);
          if (newPhase != currentPhase) {
            if (newPhase != localGameData.navigationState.lastSeenGamePhase &&
                !localGameData.navigationState.exitingGame) {
              _navigateTo(
                context: context,
                localGameData: localGameData,
                snapshot: snapshotData,
                oldPhase: currentPhase,
                newPhase: newPhase,
              );
            }
            return Center(child: CircularProgressIndicator());
          }
          Assert.eq(newPhase, currentPhase);
          return buildBody(context, snapshotData);
        },
      ),
    );
  }

  // TODO: Remove or fix how it looks. Don't show loading indicator when
  //   loading is very fast. Idea: prefetch the first state for half-second
  //   and start navigation afterwards; show a screenshot meanwhile or show
  //   widgets based on the latest state for the current phase and block
  //   interactions.
  /*
  void setNavigationExpected() {
    Assert.eq(_navigationState, _GameNavigationState.none);
    _navigationState = _GameNavigationState.expected;
  }
  */

  static void _navigateTo({
    required BuildContext context,
    required LocalGameData localGameData,
    required DBDocumentSnapshot snapshot,
    required GamePhase? oldPhase,
    required GamePhase newPhase,
  }) {
    localGameData.navigationState.lastSeenGamePhase = newPhase;
    localGameData.gameReference.clearLocalCache();
    if (newPhase == GamePhase.rematch) {
      localGameData.navigationState.exitingGame = true;
      final LocalGameData newLocalGameData =
          GameController.joinRematch(localGameData, snapshot);
      // Use `Future` because it's not allowed to navigate from `build`.
      Future(() =>
          navigateToGame(context: context, localGameData: newLocalGameData));
      return;
    }
    // Use `Future` because it's not allowed to navigate from `build`.
    Future(() => _navigateToImpl(
          context: context,
          localGameData: localGameData,
          snapshot: snapshot,
          oldPhase: oldPhase,
          newPhase: newPhase,
        ));
  }

  // TODO: Seems like `snapshot` is not needed from here down.
  static void _navigateToImpl({
    required BuildContext context,
    required LocalGameData localGameData,
    required DBDocumentSnapshot snapshot,
    required GamePhase? oldPhase,
    required GamePhase newPhase,
  }) {
    // Hide virtual keyboard
    FocusScope.of(context).unfocus();
    if (_isGrandparentPhase(newPhase, oldPhase)) {
      // Note: does not trigger `onWillPop`.
      Navigator.of(context).popUntil((route) =>
          (route.settings.arguments as RouteArguments).phase == newPhase);
    } else {
      GamePhase? pushFrom;
      if (_isGrandparentPhase(oldPhase, newPhase)) {
        // TODO: Also `pushAndRemoveUntil` in case there was a subscreen
        pushFrom = oldPhase;
      } else {
        pushFrom = _firstGrandparentPhase(newPhase);
        final route = _route(
          localGameData: localGameData,
          snapshot: snapshot,
          phase: pushFrom,
        );
        Navigator.of(context).pushAndRemoveUntil(
          route,
          ModalRoute.withName('/'),
        );
      }
      _pushPhases(
        context: context,
        localGameData: localGameData,
        snapshot: snapshot,
        fromPhase: pushFrom!,
        toPhase: newPhase,
      );
    }
  }

  static void _pushPhases({
    required BuildContext context,
    required LocalGameData localGameData,
    required DBDocumentSnapshot snapshot,
    required GamePhase fromPhase, // non-inclusive
    required GamePhase toPhase, // inclusive
  }) {
    if (fromPhase != toPhase) {
      _pushPhases(
        context: context,
        localGameData: localGameData,
        snapshot: snapshot,
        fromPhase: fromPhase,
        toPhase: _parentPhase(toPhase)!,
      );
    }
    _pushPhase(
      context: context,
      localGameData: localGameData,
      snapshot: snapshot,
      phase: toPhase,
    );
  }

  static void _pushPhase({
    required BuildContext context,
    required LocalGameData localGameData,
    required DBDocumentSnapshot snapshot,
    required GamePhase phase,
  }) {
    final route = _route(
      localGameData: localGameData,
      snapshot: snapshot,
      phase: phase,
    );
    Navigator.of(context).push(route);
  }

  static MaterialPageRoute _route({
    required LocalGameData localGameData,
    required DBDocumentSnapshot snapshot,
    required GamePhase phase,
  }) {
    final routeSettings = RouteSettings(
      name: localGameData.gameRoute,
      arguments: RouteArguments(phase: phase),
    );
    switch (phase) {
      case GamePhase.configure:
        return MaterialPageRoute(
          builder: (context) => GameConfigView(localGameData: localGameData),
          settings: routeSettings,
        );
      case GamePhase.writeWords:
        return MaterialPageRoute(
          builder: (context) => WriteWordsView(localGameData: localGameData),
          settings: routeSettings,
        );
      case GamePhase.composeTeams:
        return MaterialPageRoute(
          builder: (context) =>
              TeamCompositionsView(localGameData: localGameData),
          settings: routeSettings,
        );
      case GamePhase.play:
        return MaterialPageRoute(
          builder: (context) => GameView(localGameData: localGameData),
          settings: routeSettings,
        );
      case GamePhase.gameOver:
        return MaterialPageRoute(
          builder: (context) => ScoreView(localGameData: localGameData),
          settings: routeSettings,
        );
      case GamePhase.kicked:
        return MaterialPageRoute(
          builder: (context) => KickedScreen(),
          settings: routeSettings,
        );
      case GamePhase.rematch:
        Assert.fail('There is no route for GamePhase.rematch');
    }
    Assert.fail('Unexpected GamePhase: $phase');
  }

  static GamePhase _firstGrandparentPhase(GamePhase phase) {
    final parent = _parentPhase(phase);
    return parent != null ? _firstGrandparentPhase(parent) : phase;
  }

  static bool _isGrandparentPhase(GamePhase? phaseA, GamePhase? phaseB) {
    if (phaseA == null || phaseB == null) {
      return false;
    }
    final phaseBParent = _parentPhase(phaseB);
    return phaseBParent == phaseA
        ? true
        : _isGrandparentPhase(phaseA, phaseBParent);
  }

  static GamePhase? _parentPhase(GamePhase phase) {
    switch (phase) {
      case GamePhase.configure:
        return null;
      case GamePhase.writeWords:
        return GamePhase.configure;
      case GamePhase.composeTeams:
        // TODO: Should we go back to writeWords?
        return GamePhase.configure;
      case GamePhase.play:
      case GamePhase.gameOver:
      case GamePhase.kicked:
      case GamePhase.rematch:
        return null;
    }
    Assert.fail('Unexpected GamePhase: $phase');
  }

  static Future<_PopResponse> _confimLeaveGame(
    BuildContext context, {
    required LocalGameData localGameData,
  }) {
    // TODO: Replace with a description of how to continue when it's
    // possible to continue.
    return multipleChoiceDialog(
      context: context,
      titleText: tr('leave_game'),
      contentText: localGameData.onlineMode
          ? tr('reconnect_link_hint') + '\n' + localGameData.gameUrl
          : "You wouldn't be able to continue (this is not implemented yet)",
      choices: [
        DialogChoice(_PopResponse.disabled, tr('stay')),
        DialogChoice(_PopResponse.exitGame, tr('leave')),
      ],
      defaultChoice: _PopResponse.disabled,
    );
  }

  Future<bool> _onWillPop(
    BuildContext context, {
    required LocalGameData localGameData,
    void Function()? onBackPressed,
  }) async {
    final popResponse =
        await _popResponse(context, localGameData: localGameData);
    switch (popResponse) {
      case _PopResponse.disabled:
        break;
      case _PopResponse.custom:
        onBackPressed!();
        break;
      case _PopResponse.exitGame:
        localGameData.navigationState.exitingGame = true;
        Navigator.of(context).popUntil(ModalRoute.withName('/'));
        break;
    }
    return false;
  }

  Future<_PopResponse> _popResponse(
    BuildContext context, {
    required LocalGameData localGameData,
  }) async {
    switch (currentPhase) {
      case GamePhase.configure:
        return localGameData.isAdmin
            ? Future.value(_PopResponse.exitGame)
            : _confimLeaveGame(context, localGameData: localGameData);
      case GamePhase.composeTeams:
      case GamePhase.writeWords:
        return localGameData.isAdmin
            ? Future.value(_PopResponse.custom)
            : _confimLeaveGame(context, localGameData: localGameData);
      case GamePhase.play:
        return _confimLeaveGame(context, localGameData: localGameData);
      case GamePhase.gameOver:
      case GamePhase.kicked:
      case GamePhase.rematch:
        return Future.value(_PopResponse.exitGame);
    }
    Assert.fail('Unexpected game phase: $currentPhase');
  }
}
