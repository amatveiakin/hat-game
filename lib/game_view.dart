import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/score_view.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/sounds.dart';
import 'package:hatgame/util/vibration.dart';
import 'package:hatgame/widget/padlock.dart';
import 'package:hatgame/widget/timer.dart';
import 'package:hatgame/widget/wide_button.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class PartyView extends StatelessWidget {
  final PartyViewData teamData;
  final TurnPhase turnPhase;
  final int myPlayerID;

  PartyView(this.teamData, this.turnPhase, this.myPlayerID);

  Widget _playerView(PlayerState playerState) {
    Widget textWidget = Text(playerState.name);
    final animationDuration = turnPhase == TurnPhase.prepare
        ? Duration.zero
        : Duration(milliseconds: 300);
    // TODO: Why do we need to specify color?
    // TODO: Take color from the theme.
    if (playerState.id != myPlayerID) {
      return AnimatedDefaultTextStyle(
          duration: animationDuration,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: turnPhase == TurnPhase.prepare
                ? FontWeight.w900
                : FontWeight.normal,
            decoration: TextDecoration.underline,
            decorationColor: MyTheme.accent,
            decorationThickness: turnPhase == TurnPhase.prepare ? 2.0 : 1.0,
            color: Colors.black,
          ),
          child: textWidget);
    } else {
      return AnimatedDefaultTextStyle(
          duration: animationDuration,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: turnPhase == TurnPhase.prepare
                ? FontWeight.w600
                : FontWeight.normal,
            color: Colors.black,
          ),
          child: textWidget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _playerView(teamData.performer),
          Text(' → '),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: teamData.recipients
                .map((player) => _playerView(player))
                .toList(),
          ),
        ],
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
  final bool hasFlag;
  final void Function(WordStatus) setStatus;
  final void Function(WordFeedback) setFeedback;
  final void Function(bool) setFlag;

  WordReviewItem(
      {@required this.text,
      @required this.status,
      @required this.feedback,
      @required this.hasFlag,
      @required this.setStatus,
      @required this.setFeedback,
      @required this.setFlag});

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
              onChanged: setStatus != null
                  ? (bool newValue) => setStatus(_checkedToStatus(newValue))
                  : null,
            ),
            Expanded(
              child: text == null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Image(
                            image: AssetImage('images/word_censored.png'),
                            height: 32.0,
                          ),
                        )
                      ],
                    )
                  : Text(
                      text,
                      style: TextStyle(
                          decoration: status == WordStatus.discarded
                              ? TextDecoration.lineThrough
                              : TextDecoration.none),
                    ),
            ),
            if (hasFlag || setFlag != null)
              IconButton(
                icon: hasFlag
                    ? Icon(Icons.error,
                        color:
                            setFlag != null ? MyTheme.accent : MyTheme.primary)
                    : Icon(Icons.error_outline),
                tooltip: setFlag != null
                    ? 'Raise a problem with the word '
                        '(invalid explanation, word not actually guessed)'
                    : 'Somebody thinks there was a problem with the word '
                        '(invalid explanation, word not actually guessed)',
                onPressed: setFlag != null ? () => setFlag(!hasFlag) : () {},
              ),
            if (setStatus != null)
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
            if (setFeedback != null)
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
  GameData get gameData => widget.gameData;
  GameState get gameState => gameData.state;
  DerivedGameState get derivedGameState => gameData.derivedState;
  PersonalState get personalState => gameData.personalState;
  LocalGameState get localGameState => gameData.localState;

  AnimationController _padlockAnimationController;
  bool _turnActive = false;
  bool _bonusTimeActive = false;

  void _unlockStartExplaning() {
    setState(() {
      localGameState.startButtonEnabled = true;
    });
  }

  void _startExplaning() {
    setState(() {
      localGameState.startButtonEnabled = false;
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
    HapticFeedback.mediumImpact();
    gameController.wordGuessed();
  }

  void _endTurn(int turnRestriction) {
    if (gameState.turn == turnRestriction &&
        gameState.turnPhase == TurnPhase.explain) {
      Sounds.play(Sounds.timeOver);
      MyVibration.heavyVibration();
      gameController.finishExplanation();
      setState(() {
        _bonusTimeActive = gameConfig.rules.bonusSeconds > 0;
      });
    }
  }

  void _endBonusTime(int turnRestriction) {
    if (gameState.turn == turnRestriction) {
      MyVibration.mediumVibration();
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

  void _setWordFlag(int wordId, bool hasFlag) {
    gameController.setWordFlag(wordId, hasFlag);
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
    if (gameController.isActivePlayer) {
      return _buildActivePlayer(context);
    } else {
      return _buildInactivePlayer(context);
    }
  }

  Widget _buildInactivePlayer(BuildContext context) {
    final wordReviewItems = gameData
        .wordsInThisTurnData()
        .map((w) => WordReviewItem(
              text: w.status == WordStatus.notExplained ? null : w.text,
              status: w.status,
              feedback: personalState.wordFeedback[w.id],
              hasFlag: personalState.wordFlags.contains(w.id),
              setStatus: null,
              setFeedback: (WordFeedback feedback) =>
                  _setWordFeedback(w.id, feedback),
              setFlag: (bool hasFlag) => _setWordFlag(w.id, hasFlag),
            ))
        .toList();
    switch (gameState.turnPhase) {
      case TurnPhase.prepare:
        return Container();
      case TurnPhase.explain:
      case TurnPhase.review:
        {
          return Column(children: [
            Expanded(
              child: ListView(
                children: wordReviewItems,
              ),
            ),
          ]);
        }
    }
    Assert.holds(gameState.gameFinished,
        lazyMessage: () => gameState.toString());
    return Container();
  }

  Widget _buildActivePlayer(BuildContext context) {
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
                    onPressed: localGameState.startButtonEnabled
                        ? _startExplaning
                        : null,
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
        {
          final wordReviewItems = gameData
              .wordsInThisTurnData()
              .map((w) => WordReviewItem(
                    text: w.text,
                    status: w.status,
                    feedback: personalState.wordFeedback[w.id],
                    hasFlag: derivedGameState.flaggedWords.contains(w.id),
                    setStatus: (WordStatus status) =>
                        _setWordStatus(w.id, status),
                    setFeedback: (WordFeedback feedback) =>
                        _setWordFeedback(w.id, feedback),
                    setFlag: null,
                  ))
              .toList();
          return Column(children: [
            Expanded(
              child: ListView(
                children: wordReviewItems,
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
    }
    Assert.holds(gameState.gameFinished,
        lazyMessage: () => gameState.toString());
    return Container();
  }
}

class GameView extends StatefulWidget {
  final GameController gameController;
  final LocalGameData localGameData;

  GameView({@required this.localGameData})
      : gameController = GameController.fromFirestore(localGameData);

  @override
  State<StatefulWidget> createState() => GameViewState();
}

class GameViewState extends State<GameView> {
  bool _navigatedToScoreboard = false;

  GameController get gameController => widget.gameController;
  LocalGameData get localGameData => widget.localGameData;

  Future<bool> _onBackPressed() {
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

  void _goToScoreboard(GameData gameData) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ScoreView(gameData: gameData),
          settings: RouteSettings(name: 'Scoreboard'),
        ),
        ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onBackPressed(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Hat Game'),
        ),
        body: StreamBuilder<GameData>(
          stream: gameController.stateUpdatesStream,
          builder: (BuildContext context, AsyncSnapshot<GameData> snapshot) {
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
            final gameData = snapshot.data;

            if (gameData.state.gameFinished) {
              // Cannot navigate from within `build`.
              if (!_navigatedToScoreboard) {
                Future.delayed(Duration.zero, () => _goToScoreboard(gameData));
                _navigatedToScoreboard = true;
              }
              return Center(child: CircularProgressIndicator());
            }

            return Container(
              child: Column(
                children: [
                  PartyView(
                    gameData.currentPartyViewData(),
                    gameData.state.turnPhase,
                    localGameData.myPlayerID,
                  ),
                  Expanded(
                    child: PlayArea(
                      localGameData: localGameData,
                      gameController: gameController,
                      gameData: gameData,
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
