import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/image_assert_icon.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/spacing.dart';
import 'package:hatgame/widget/wide_button.dart';

enum NavigationState {
  none,
  expected,
  requested,
}

// This is similar to _TeamScoreView from score_view.dart, but not similar
// enough to unify the implementations.
class _TeamView extends StatelessWidget {
  final List<String> playerNames;

  const _TeamView({required this.playerNames});

  Widget _playerView(String name) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 18.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40), // for non-team view
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
  final LocalGameData localGameData;
  final GameNavigator navigator =
      GameNavigator(currentPhase: GamePhase.composeTeams);

  TeamCompositionsView({super.key, required this.localGameData});

  void _regenerateTeamCompositions(GameConfig gameConfig) async {
    // Shouldn't throw, because initial compositions have been generated
    // successfully.
    await GameController.updateTeamCompositions(
        localGameData.gameReference, gameConfig);
  }

  void _startGame(BuildContext context, DBDocumentSnapshot snapshot) async {
    try {
      await GameController.startGame(localGameData, snapshot);
    } on InvalidOperation catch (e) {
      if (context.mounted) {
        showInvalidOperationDialog(context: context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return navigator.buildWrapper(
      context: context,
      localGameData: localGameData,
      buildBody: buildBody,
    );
  }

  Widget buildBody(BuildContext context, DBDocumentSnapshot snapshot) {
    final TeamCompositionsViewData teamCompositionsViewData =
        GameController.getTeamCompositions(localGameData, snapshot)!;
    final teamPlay =
        teamCompositionsViewData.gameConfig.teaming.teamingStyle.teamPlay();

    return ConstrainedScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: localGameData.isAdmin,
        title: Text(teamPlay
            ? context.tr('team_compositions')
            : context.tr('turn_order')),
        actions: [
          if (localGameData.isAdmin)
            IconButton(
              icon: const ImageAssetIcon('images/dice.png'),
              onPressed: () => _regenerateTeamCompositions(
                  teamCompositionsViewData.gameConfig),
              tooltip: teamPlay
                  ? context.tr('new_random_teams_and_turn_order')
                  : context.tr('new_random_turn_order'),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: ListView(
                children: teamCompositionsViewData.playerNames
                    .map((t) => _TeamView(playerNames: t))
                    .toList(),
              ),
            ),
          ),
          WideButton(
            onPressed: localGameData.isAdmin
                ? () => _startGame(context, snapshot)
                : null,
            coloring: WideButtonColoring.secondary,
            margin: WideButton.bottomButtonMargin,
            child: Text(context.tr('start_game')),
          ),
        ],
      ),
    );
  }
}
