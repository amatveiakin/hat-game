import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/primary_secondary_scaffold.dart';
import 'package:hatgame/widget/spacing.dart';
import 'package:hatgame/widget/wide_button.dart';

// TODO: Allow final results editing on ScoreView.
// TODO: Does it make sense to show words guessed in modes with many guessers?

class _TeamScoreView extends StatelessWidget {
  final TeamScoreViewData data;

  _TeamScoreView({required this.data});

  Widget _playerView(PlayerScoreViewData player) {
    return Row(
      children: [
        Expanded(
          child: Text(
            player.name,
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
        ),
        Text(
          '${player.wordsExplained} / ${player.wordsGuessed}',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 40), // for non-team view
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 60.0,
                child: Container(
                  color: MyTheme.primary,
                  child: Center(
                    child: Text(
                      data.totalScore.toString(),
                      style: TextStyle(
                        fontSize: 28.0,
                        // TODO: Take the color from theme.
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: addSpacing(
                        vertical: 4,
                        tiles: data.players.map(_playerView).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordView extends StatelessWidget {
  final WordInTurnLogViewData data;

  _WordView({required this.data});

  Icon _icon(WordStatus status) {
    switch (status) {
      case WordStatus.notExplained:
        return Icon(Icons.remove_red_eye_outlined, color: _style(status).color);
      case WordStatus.explained:
        // TODO: Find a clearer solution.
        return Icon(Icons.check, color: Colors.transparent);
      case WordStatus.discarded:
        return Icon(Icons.delete);
    }
    Assert.fail('Unknown WordStatus: $status');
  }

  TextStyle _style(WordStatus status) {
    switch (status) {
      case WordStatus.notExplained:
        // TODO: Take the color from the theme.
        return TextStyle(color: Colors.black45);
      case WordStatus.explained:
        return TextStyle();
      case WordStatus.discarded:
        return TextStyle(decoration: TextDecoration.lineThrough);
    }
    Assert.fail('Unknown WordStatus: $status');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _icon(data.status),
        SizedBox(
          width: 4.0,
        ),
        Expanded(
          child: Text(
            data.text,
            style: _style(data.status),
          ),
        ),
      ],
    );
  }
}

class _TurnView extends StatelessWidget {
  final TurnLogViewData data;

  _TurnView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            // TODO: Take the color from the theme.
            color: Colors.black12,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              child: Text(data.party),
            ),
          ),
          Divider(
            height: 0.0,
            thickness: 0.5,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    // TODO: Filter unexplained by default.
                    data.wordsInThisTurn
                        .map((w) => _WordView(data: w))
                        .toList()),
          ),
        ],
      ),
    );
  }
}

class ScoreView extends StatelessWidget {
  final LocalGameData localGameData;
  final GameNavigator navigator =
      GameNavigator(currentPhase: GamePhase.gameOver);

  ScoreView({required this.localGameData});

  void _rematch(BuildContext context, DBDocumentSnapshot snapshot) async {
    try {
      await GameController.rematch(localGameData, snapshot);
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
    );
  }

  Widget buildBody(BuildContext context, DBDocumentSnapshot snapshot) {
    final gameController = GameController.fromSnapshot(localGameData, snapshot);
    final gameData = gameController.gameData;
    return PrimarySecondaryScaffold(
      primaryAutomaticallyImplyLeading: true,
      primaryTitle: tr('game_over'),
      primary: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: ListView(
                children: gameData
                    .scoreData()
                    .map((s) => _TeamScoreView(data: s))
                    .toList(),
              ),
            ),
          ),
          WideButton(
            onPressed: localGameData.isAdmin
                ? () => _rematch(context, snapshot)
                : null,
            coloring: WideButtonColoring.secondary,
            child: Text(tr('rematch')),
            margin: WideButton.bottomButtonMargin,
          ),
        ],
      ),
      secondaryRouteName: '/game-log',
      secondary: Padding(
        padding: EdgeInsets.all(6.0),
        child: ListView(
          children:
              gameData.turnLogData().map((t) => _TurnView(data: t)).toList(),
        ),
      ),
      // TODO: Proper icon.
      secondaryIcon: Icon(Icons.list),
      secondaryTitle: tr('game_log'),
    );
  }
}
