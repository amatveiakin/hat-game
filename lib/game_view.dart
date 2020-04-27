import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/score_view.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/padlock.dart';
import 'package:hatgame/widget/timer.dart';
import 'package:hatgame/widget/wide_button.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class PartyView extends StatefulWidget {
  final PartyViewData teamData;
  final TurnPhase turnPhase;

  PartyView(this.teamData, this.turnPhase);

  @override
  createState() => PartyViewState();
}

// TODO: Add haptic feedback for main events.
// TODO: Swicth to animation controllers or make the widget stateless.
class PartyViewState extends State<PartyView> with TickerProviderStateMixin {
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

Icon _getWordFeedbackIcon(WordFeedback feedback, bool menuButton, bool active) {
  if (feedback == null) {
    return menuButton ? Icon(OMIcons.thumbsUpDown) : Icon(OMIcons.clear);
  }
  switch (feedback) {
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
  Assert.fail("Reached end of _getWordFeedbackIcon");
}

String _getWordFeedbackText(WordFeedback feedback) {
  if (feedback == null) {
    return 'Clear';
  }
  switch (feedback) {
    case WordFeedback.good:
      return 'Nice';
    case WordFeedback.bad:
      return 'Ugly';
    case WordFeedback.tooEasy:
      return 'Too easy';
    case WordFeedback.tooHard:
      return 'Too hard';
  }
  Assert.fail("Reached end of _getWordFeedbackText");
}

class WordReviewItem extends StatelessWidget {
  final String text;
  final WordStatus status;
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
    bool _statusToChecked(WordStatus status) {
      return status == WordStatus.explained;
    }

    WordStatus _checkedToStatus(bool checked) {
      return checked ? WordStatus.explained : WordStatus.notExplained;
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
                    decoration: status == WordStatus.discarded
                        ? TextDecoration.lineThrough
                        : TextDecoration.none),
              ),
            ),
            IconButton(
              icon: Icon(status == WordStatus.discarded
                  ? Icons.restore_from_trash
                  : Icons.delete_outline),
              tooltip: status == WordStatus.discarded ? 'Restore' : 'Discard',
              onPressed: () {
                setStatus(status == WordStatus.discarded
                    ? WordStatus.notExplained
                    : WordStatus.discarded);
              },
            ),
            PopupMenuButton(
              icon: _getWordFeedbackIcon(feedback, true, true),
              itemBuilder: (BuildContext context) {
                var result = <PopupMenuItem<WordFeedback>>[];
                result.addAll(WordFeedback.values
                    .where((wf) => (wf != null))
                    .map((wf) => PopupMenuItem<WordFeedback>(
                          value: wf,
                          child: ListTile(
                              leading: _getWordFeedbackIcon(
                                  wf, false, wf == feedback),
                              title: Text(_getWordFeedbackText(wf))),
                        ))
                    .toList());
                return result;
              },
              onSelected: (WordFeedback newFeedback) {
                setFeedback(newFeedback == feedback ? null : newFeedback);
              },
            )
          ],
        ),
      ),
    );
  }
}

class PlayArea extends StatefulWidget {
  // TODO: Which of these do we actually need?
  final LocalGameData localGameData;
  final GameController gameController;
  final GameData gameData;

  PlayArea({
    @required this.localGameData,
    @required this.gameController,
    @required this.gameData,
  });

  @override
  State<StatefulWidget> createState() => PlayAreaState();
}

class PlayAreaState extends State<PlayArea>
    with SingleTickerProviderStateMixin {
  LocalGameData get localGameData => widget.localGameData;
  GameController get gameController => widget.gameController;
  GameConfig get gameConfig => gameData.config;
  GameState get gameState => gameData.state;
  GameData get gameData => widget.gameData;

  AnimationController _padlockAnimationController;
  bool _startButtonEnabled = false;
  bool _turnActive = false;
  bool _bonusTimeActive = false;

  void _unlockStartExplaning() {
    setState(() {
      _startButtonEnabled = true;
    });
  }

  void _startExplaning() {
    setState(() {
      _startButtonEnabled = false;
      _turnActive = true;
    });
    gameController.startExplaning();
  }

  void _setTurnActive(bool value) {
    setState(() {
      _turnActive = value;
    });
  }

  void _wordGuessed() {
    gameController.wordGuessed();
  }

  void _endTurn(int turnRestriction) {
    if (gameState.turn == turnRestriction &&
        gameState.turnPhase == TurnPhase.explain) {
      gameController.finishExplanation();
      setState(() {
        _bonusTimeActive = gameConfig.rules.bonusSeconds > 0;
      });
    }
  }

  void _endBonusTime(int turnRestriction) {
    if (gameState.turn == turnRestriction) {
      setState(() {
        _bonusTimeActive = false;
      });
    }
  }

  void _setWordStatus(int wordId, WordStatus status) {
    gameController.setWordStatus(wordId, status);
  }

  void _setWordFeedback(int wordId, WordFeedback feedback) {
    gameController.setWordFeedback(wordId, feedback);
  }

  void _reviewDone() {
    gameController.nextTurn();
  }

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
      child: Text('Words in hat: ${gameState.wordsInHat.length}'),
    );
    switch (gameState.turnPhase) {
      case TurnPhase.prepare:
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  child: WideButton(
                    onPressed: _startButtonEnabled ? _startExplaning : null,
                    onPressedDisabled: () =>
                        _padlockAnimationController.forward(from: 0.0),
                    color: MyTheme.accent,
                    child: Text(
                      'Start!',
                      style: TextStyle(fontSize: 24.0),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padlock(
                  onUnlocked: _unlockStartExplaning,
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
                onPressed: _turnActive ? _wordGuessed : null,
                child: Text(
                  gameData.currentWordText(),
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: TimerView(
                style: TimerViewStyle.turnTime,
                // TODO: Test how this behaves when the app is minimized.
                onTimeEnded: () => _endTurn(gameState.turn),
                onRunningChanged: _setTurnActive,
                duration: Duration(seconds: gameConfig.rules.turnSeconds),
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
                tiles: gameData
                    .wordsInThisTurnData()
                    .map((w) => WordReviewItem(
                          text: w.text,
                          status: w.status,
                          feedback: w.feedback,
                          setStatus: (WordStatus status) =>
                              _setWordStatus(w.id, status),
                          setFeedback: (WordFeedback feedback) =>
                              _setWordFeedback(w.id, feedback),
                        ))
                    .toList(),
              ).toList(),
            ),
          ),
          if (_bonusTimeActive)
            TimerView(
              style: TimerViewStyle.bonusTime,
              onTimeEnded: () => _endBonusTime(gameState.turn),
              duration: Duration(seconds: gameConfig.rules.bonusSeconds),
            ),
          SizedBox(height: 40),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: WideButton(
              onPressed: _reviewDone,
              color: MyTheme.accent,
              child: Text('Done'),
            ),
          ),
          SizedBox(height: 12),
        ]);
    }
    Assert.holds(gameState.gameFinished,
        lazyMessage: () => gameState.toString());
    return Container();
  }
}

class GameView extends StatelessWidget {
  final LocalGameData localGameData;

  GameView({@required this.localGameData});

  Future<bool> _onBackPressed(BuildContext context) {
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
                child: Text('Leave'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              FlatButton(
                child: Text('Stay'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onBackPressed(context),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Hat Game'),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: localGameData.gameReference.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              // TODO: Deal with errors.
              return Center(
                  child: Text(
                'Error getting game data:\n' + snapshot.error.toString(),
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ));
            }
            if (!snapshot.hasData) {
              // TODO: Deal with loading (use snapshot.connectionState?)
              return Center(child: CircularProgressIndicator());
            }
            final gameController = GameController.fromSnapshot(snapshot.data);
            if (gameController == null) {
              return Center(child: CircularProgressIndicator());
            }

            if (gameController.state.gameFinished) {
              // TODO: Avoid double navigation, similarly to ConfigView.
              // Cannot navigate from within `build`.
              Future.delayed(
                Duration.zero,
                () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ScoreView(gameData: gameController.gameData)),
                    ModalRoute.withName('/')),
              );
              return Container();
            }

            return Container(
              child: Column(
                children: [
                  PartyView(gameController.gameData.currentPartyViewData(),
                      gameController.state.turnPhase),
                  Expanded(
                    child: PlayArea(
                      localGameData: localGameData,
                      gameController: gameController,
                      gameData: gameController.gameData,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
