import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/team_compositions.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/game_phase.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/async_snapshot_error.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/spacing.dart';
import 'package:hatgame/widget/wide_button.dart';

enum NavigationState {
  none,
  expected,
  requested,
}

// TODO: Re-randomize button.

// This is similar to _TeamScoreView from score_view.dart, but not similar
// enough to unify the implementations.
class _TeamView extends StatelessWidget {
  final List<String> playerNames;

  _TeamView({@required this.playerNames});

  Widget _playerView(String name) {
    return Text(
      name,
      style: TextStyle(
        fontSize: 18.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 40), // for non-team view
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: addSpacing(
                vertical: 4,
                tiles: playerNames.map(_playerView).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TeamCompositionsView extends StatelessWidget {
  static const String routeName = '/team-compositions';

  final LocalGameData localGameData;
  final GameNavigator navigator =
      GameNavigator(currentPhase: GamePhase.composeTeams);

  TeamCompositionsView({@required this.localGameData});

  void _onBackPressed() {
    GameController.discardTeamCompositions(localGameData.gameReference);
  }

  void _startGame(BuildContext context, GameConfig gameConfig,
      TeamCompositions teamCompositions) async {
    try {
      await GameController.startGame(
          localGameData.gameReference, gameConfig, teamCompositions);
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return navigator.buildWrapper(
      context: context,
      localGameData: localGameData,
      buildBody: buildBody,
      onBackPressed: _onBackPressed,
    );
  }

  Widget buildBody(BuildContext context, DBDocumentSnapshot snapshot) {
    final TeamCompositionsViewData teamCompositionsViewData =
        GameController.getTeamCompositions(localGameData, snapshot);
    Assert.holds(teamCompositionsViewData != null);

    return ConstrainedScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: localGameData.isAdmin,
        title: Text(teamCompositionsViewData.gameConfig.teaming.teamPlay
            ? 'Team Compositions'
            : 'Turn Order'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: ListView(
                children: teamCompositionsViewData.playerNames
                    .map((t) => _TeamView(playerNames: t))
                    .toList(),
              ),
            ),
          ),
          WideButton(
            onPressed: localGameData.isAdmin
                ? () => _startGame(context, teamCompositionsViewData.gameConfig,
                    teamCompositionsViewData.teamCompositions)
                : null,
            color: MyTheme.accent,
            child: Text('Start Game!'),
            margin: WideButton.bottomButtonMargin,
          ),
        ],
      ),
    );
  }
}
