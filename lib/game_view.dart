import 'package:flutter/material.dart';
import 'package:hatgame/game_settings.dart';
import 'package:hatgame/game_state.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/timer.dart';

class TeamView extends StatefulWidget {
  final TeamViewData teamData;
  final TurnPhase turnPhase;

  TeamView(this.teamData, this.turnPhase);

  @override
  createState() => TeamViewState();
}

// TODO: Add haptic feedback for main events.
// TODO: Swicth to animation controllers or make the widget stateless.
class TeamViewState extends State<TeamView> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final animationDuration = widget.turnPhase == TurnPhase.prepare
        ? Duration.zero
        : Duration(milliseconds: 300);
    return AnimatedDefaultTextStyle(
      duration: animationDuration,
      style: TextStyle(
        fontSize: 20.0,
        fontWeight: widget.turnPhase == TurnPhase.prepare
            ? FontWeight.bold
            : FontWeight.normal,
        // TODO: Why do we need to specify color?
        // TODO: Take color from the theme.
        color: Colors.black,
      ),
      child: AnimatedOpacity(
        duration: animationDuration,
        opacity: widget.turnPhase == TurnPhase.prepare ? 1.0 : 0.5,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.teamData.performer.name,
                  textAlign: TextAlign.right,
                ),
              ),
              Text(
                ' → ',
                textAlign: TextAlign.center,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.teamData.recipients
                      .map((player) => Text(
                            player.name,
                            textAlign: TextAlign.left,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WordReviewItem extends StatelessWidget {
  final String text;
  final WordInTurnStatus status;
  final Function onChanged;

  WordReviewItem(
      {@required this.text, @required this.status, @required this.onChanged});

  @override
  Widget build(BuildContext context) {
    bool _statusToChecked(WordInTurnStatus status) {
      return status == WordInTurnStatus.explained;
    }

    WordInTurnStatus _checkedToStatus(bool checked) {
      return checked
          ? WordInTurnStatus.explained
          : WordInTurnStatus.notExplained;
    }

    return InkWell(
      onTap: () {
        onChanged(_checkedToStatus(!_statusToChecked(status)));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Row(
          children: [
            Checkbox(
              value: _statusToChecked(status),
              onChanged: (bool newValue) {
                onChanged(_checkedToStatus(newValue));
              },
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    decoration: status == WordInTurnStatus.discarded
                        ? TextDecoration.lineThrough
                        : TextDecoration.none),
              ),
            ),
            IconButton(
              icon: Icon(status == WordInTurnStatus.discarded
                  ? Icons.restore_from_trash
                  : Icons.delete_outline),
              onPressed: () {
                onChanged(status == WordInTurnStatus.discarded
                    ? WordInTurnStatus.notExplained
                    : WordInTurnStatus.discarded);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PlayArea extends StatelessWidget {
  final GameViewState _gameViewState;
  final GameState gameState;
  final GameSettings gameSettings;

  PlayArea(this._gameViewState)
      : gameState = _gameViewState.gameState,
        gameSettings = _gameViewState.gameSettings;

  @override
  Widget build(BuildContext context) {
    switch (gameState.turnPhase()) {
      case TurnPhase.prepare:
        return Column(
          children: [
            Expanded(
              child: Center(
                // TODO: Align with the word button position.
                child: RaisedButton(
                  onPressed: () {
                    _gameViewState.update(() {
                      gameState.startExplaning();
                      int turn = gameState.currentTurn();
                      Future.delayed(
                          Duration(seconds: gameSettings.explanationSeconds),
                          () {
                        _gameViewState.update(() {
                          gameState.finishExplanation(turnRestriction: turn);
                        });
                      });
                    });
                  },
                  color: MyColors.accent,
                  padding:
                      EdgeInsets.symmetric(horizontal: 36.0, vertical: 12.0),
                  child: Text(
                    'Start!',
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Words in hat: ${gameState.numWordsInHat()}',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        );
      case TurnPhase.explain:
        return Column(children: [
          Expanded(
            child: Center(
              child: SizedBox(
                // Get screen size using MediaQuery
                width: MediaQuery.of(context).size.width * 0.8,
                child: RaisedButton(
                  onPressed: () => _gameViewState.update(() {
                    gameState.wordGuessed();
                  }),
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    gameState.currentWord(),
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: TimerView(
                duration: Duration(seconds: gameSettings.explanationSeconds),
              ),
            ),
          ),
        ]);
      case TurnPhase.review:
        return Column(children: [
          Expanded(
            child: ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: gameState
                    .wordsInThisTurnViewData()
                    .map((w) => WordReviewItem(
                          text: w.text,
                          status: w.status,
                          onChanged: (WordInTurnStatus status) =>
                              _gameViewState.update(() {
                            gameState.setWordStatus(w.id, status);
                          }),
                        ))
                    .toList(),
              ).toList(),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: RaisedButton(
              onPressed: () => _gameViewState.update(() {
                gameState.newTurn();
              }),
              color: MyColors.accent,
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Text(
                'Next round',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
          ),
        ]);
    }
  }
}

class GameView extends StatefulWidget {
  @override
  createState() => GameViewState();
}

class GameViewState extends State<GameView> {
  final GameState gameState = GameState.example();
  final GameSettings gameSettings = GameSettings.dev();

  void update(Function updater) {
    setState(updater);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Container(
        child: Column(
          children: [
            TeamView(gameState.currentTeamViewData(), gameState.turnPhase()),
            Expanded(
              child: PlayArea(this),
            ),
          ],
        ),
      ),
    );
  }
}
