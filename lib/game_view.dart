import 'package:flutter/material.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/game_config.dart';
import 'package:hatgame/game_state.dart';
import 'package:hatgame/padlock.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/timer.dart';
import 'package:hatgame/wide_button.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

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

Icon _GetWordFeedbackIcon(WordFeedback feedback, bool menuButton, bool active) {
  Assert.holds(feedback != null);
  switch (feedback) {
    case WordFeedback.none:
      return menuButton ? Icon(OMIcons.thumbsUpDown) : Icon(OMIcons.clear);
    case WordFeedback.good:
      return active
          ? Icon(Icons.thumb_up, color: MyTheme.accent)
          : Icon(OMIcons.thumbUp);
    case WordFeedback.bad:
      return active
          ? Icon(Icons.thumb_down, color: MyTheme.accent)
          : Icon(OMIcons.thumbDown);
    case WordFeedback.tooEasy:
      // TODO: Find a proper icon.
      return active
          ? Icon(Icons.cake, color: MyTheme.accent)
          : Icon(OMIcons.cake);
    case WordFeedback.tooHard:
      // TODO: Find a proper icon.
      return active
          ? Icon(Icons.sentiment_very_dissatisfied, color: MyTheme.accent)
          : Icon(OMIcons.sentimentVeryDissatisfied);
  }
  throw AssertionError("Reached end of _GetWordFeedbackIcon");
}

String _GetWordFeedbackText(WordFeedback feedback) {
  Assert.holds(feedback != null);
  switch (feedback) {
    case WordFeedback.none:
      return 'Clear';
    case WordFeedback.good:
      return 'Nice';
    case WordFeedback.bad:
      return 'Ugly';
    case WordFeedback.tooEasy:
      return 'Too easy';
    case WordFeedback.tooHard:
      return 'Too hard';
  }
  throw AssertionError("Reached end of _GetWordFeedbackText");
}

class WordReviewItem extends StatelessWidget {
  final String text;
  final WordInTurnStatus status;
  final WordFeedback feedback;
  final Function setStatus;
  final Function setFeedback;

  WordReviewItem(
      {@required this.text,
      @required this.status,
      @required this.feedback,
      @required this.setStatus,
      @required this.setFeedback});

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
        setStatus(_checkedToStatus(!_statusToChecked(status)));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Row(
          children: [
            Checkbox(
              value: _statusToChecked(status),
              onChanged: (bool newValue) {
                setStatus(_checkedToStatus(newValue));
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
              tooltip:
                  status == WordInTurnStatus.discarded ? 'Restore' : 'Discard',
              onPressed: () {
                setStatus(status == WordInTurnStatus.discarded
                    ? WordInTurnStatus.notExplained
                    : WordInTurnStatus.discarded);
              },
            ),
            PopupMenuButton(
              icon: _GetWordFeedbackIcon(feedback, true, true),
              itemBuilder: (BuildContext context) {
                var result = <PopupMenuItem<WordFeedback>>[];
                result.addAll(WordFeedback.values
                    .where((wf) => (wf != WordFeedback.none))
                    .map((wf) => PopupMenuItem<WordFeedback>(
                          value: wf,
                          child: ListTile(
                              leading: _GetWordFeedbackIcon(
                                  wf, false, wf == feedback),
                              title: Text(_GetWordFeedbackText(wf))),
                        ))
                    .toList());
                return result;
              },
              onSelected: (WordFeedback newFeedback) {
                setFeedback(
                    newFeedback == feedback ? WordFeedback.none : newFeedback);
              },
            )
          ],
        ),
      ),
    );
  }
}

class PlayArea extends StatefulWidget {
  final GameViewState _gameViewState;

  PlayArea(this._gameViewState);

  @override
  State<StatefulWidget> createState() => PlayAreaState(_gameViewState);
}

class PlayAreaState extends State<PlayArea>
    with SingleTickerProviderStateMixin {
  final GameViewState _gameViewState;
  final GameState gameState;
  final GameConfig gameSettings;
  AnimationController _padlockAnimationController;

  PlayAreaState(this._gameViewState)
      : gameState = _gameViewState.gameState,
        gameSettings = _gameViewState.widget.gameSettings;

  @override
  void initState() {
    super.initState();
    _padlockAnimationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
  }

  @override
  void dispose() {
    _padlockAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordsInHatWidget = Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Text('Words in hat: ${gameState.numWordsInHat()}'),
    );
    switch (gameState.turnPhase()) {
      case TurnPhase.prepare:
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  child: GestureDetector(
                    child: WideButton(
                      onPressed: _gameViewState.startButtonEnabled
                          ? () {
                              _gameViewState.update(() {
                                _gameViewState.startButtonEnabled = false;
                                gameState.startExplaning();
                                int turn = gameState.currentTurn();
                                Future.delayed(
                                    Duration(
                                        seconds: gameSettings
                                            .rules.turnSeconds), () {
                                  _gameViewState.update(() {
                                    gameState.finishExplanation(
                                        turnRestriction: turn);
                                  });
                                });
                              });
                            }
                          : null,
                      color: MyTheme.accent,
                      child: Text(
                        'Start!',
                        style: TextStyle(fontSize: 24.0),
                      ),
                    ),
                    // Cannot put this into the button, because it will become
                    // enabled if it has a callback.
                    onTap: _gameViewState.startButtonEnabled
                        ? null
                        : () => _padlockAnimationController.forward(from: 0.0),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padlock(
                  onUnlocked: () => _gameViewState.update(() {
                    _gameViewState.startButtonEnabled = true;
                  }),
                  animationController: _padlockAnimationController,
                ),
              ),
            ),
            wordsInHatWidget,
          ],
        );
      case TurnPhase.explain:
        return Column(children: [
          Expanded(
            child: Center(
              child: WideButton(
                onPressed: () => _gameViewState.update(() {
                  gameState.wordGuessed();
                }),
                child: Text(
                  gameState.currentWord(),
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: TimerView(
                duration: Duration(seconds: gameSettings.rules.turnSeconds),
              ),
            ),
          ),
          // TODO: Dim text color similarly to team name.
          wordsInHatWidget,
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
                          feedback: w.feedback,
                          setStatus: (WordInTurnStatus status) =>
                              _gameViewState.update(() {
                            gameState.setWordStatus(w.id, status);
                          }),
                          setFeedback: (WordFeedback feedback) =>
                              _gameViewState.update(() {
                            gameState.setWordFeedback(w.id, feedback);
                          }),
                        ))
                    .toList(),
              ).toList(),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: WideButton(
              onPressed: () => _gameViewState.update(() {
                gameState.newTurn();
              }),
              color: MyTheme.accent,
              child: Text(
                'Next Round',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
          ),
          SizedBox(height: 12),
        ]);
    }
  }
}

class GameView extends StatefulWidget {
  final GameConfig gameSettings;

  GameView(this.gameSettings);

  @override
  createState() => GameViewState(gameSettings);
}

class GameViewState extends State<GameView> {
  final GameState gameState;
  bool startButtonEnabled = false;

  GameViewState(GameConfig gameSettings) : gameState = GameState(gameSettings);

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
