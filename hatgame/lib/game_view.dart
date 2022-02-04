import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/functions.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/sounds.dart';
import 'package:hatgame/util/vibration.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/image_assert_icon.dart';
import 'package:hatgame/widget/padlock.dart';
import 'package:hatgame/widget/timer.dart';
import 'package:hatgame/widget/wide_button.dart';

class PartyView extends StatelessWidget {
  final PartyViewData party;
  final TurnPhase turnPhase;
  final int? myPlayerID;

  PartyView(this.party, this.turnPhase, this.myPlayerID);

  Widget _playerView(PlayerViewData playerData) {
    Widget textWidget = Text(playerData.name!);
    final animationDuration = turnPhase == TurnPhase.prepare
        ? Duration.zero
        : Duration(milliseconds: 300);
    // TODO: Why do we need to specify color?
    // TODO: Take color from the theme.
    if (playerData.id == myPlayerID) {
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
          _playerView(party.performer),
          if (party.recipients.isNotEmpty) Text(' → '),
          if (party.recipients.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: party.recipients
                  .map((player) => _playerView(player))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

Widget _getWordFeedbackIcon(
    WordFeedback? feedback, bool menuButton, bool active) {
  if (feedback == null) {
    return menuButton
        ? Icon(Icons.thumbs_up_down_outlined)
        : Icon(Icons.clear_outlined);
  }
  switch (feedback) {
    case WordFeedback.good:
      return active
          ? Icon(Icons.thumb_up, color: MyTheme.accent)
          : Icon(Icons.thumb_up_outlined);
    case WordFeedback.bad:
      return active
          ? Icon(Icons.thumb_down, color: MyTheme.accent)
          : Icon(Icons.thumb_down_outlined);
    case WordFeedback.tooEasy:
      return active
          ? ImageAssetIcon('images/too_easy_filled.png', color: MyTheme.accent)
          : ImageAssetIcon('images/too_easy_outlined.png');
    case WordFeedback.tooHard:
      return active
          ? ImageAssetIcon('images/too_hard_filled.png', color: MyTheme.accent)
          : ImageAssetIcon('images/too_hard_outlined.png');
  }
  Assert.fail("Reached end of _getWordFeedbackIcon");
}

String _getWordFeedbackText(WordFeedback feedback) {
  if (feedback == null) {
    return tr('word_feedback_clear');
  }
  switch (feedback) {
    case WordFeedback.good:
      return tr('word_feedback_nice');
    case WordFeedback.bad:
      return tr('word_feedback_ugly');
    case WordFeedback.tooEasy:
      return tr('word_feedback_too_easy');
    case WordFeedback.tooHard:
      return tr('word_feedback_too_hard');
  }
  Assert.fail("Reached end of _getWordFeedbackText");
}

class WordReviewItem extends StatelessWidget {
  final String? text;
  final WordStatus status;
  final WordFeedback? feedback;
  final bool hasFlag;
  final void Function(WordStatus)? setStatus;
  final void Function(WordFeedback?)? setFeedback;
  final void Function(bool)? setFlag;

  WordReviewItem(
      {required this.text,
      required this.status,
      required this.feedback,
      this.hasFlag = false,
      required this.setStatus,
      required this.setFeedback,
      required this.setFlag});

  @override
  Widget build(BuildContext context) {
    bool _statusToChecked(WordStatus status) {
      return status == WordStatus.explained;
    }

    WordStatus _checkedToStatus(bool checked) {
      return checked ? WordStatus.explained : WordStatus.notExplained;
    }

    // TODO: Consider using LabeledCheckbox.
    return InkWell(
      onTap: () {
        setStatus!(_checkedToStatus(!_statusToChecked(status)));
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Row(
          children: [
            Checkbox(
              value: _statusToChecked(status),
              onChanged: setStatus != null
                  ? (bool? newValue) => setStatus!(_checkedToStatus(newValue!))
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
                      text!,
                      style: TextStyle(
                          decoration: status == WordStatus.discarded
                              ? TextDecoration.lineThrough
                              : TextDecoration.none),
                    ),
            ),
            if (hasFlag && setFlag == null)
              // Padding and icon size constants are mimicing an icon button.
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Tooltip(
                  child: Icon(Icons.error, color: MyTheme.primary),
                  message: tr('somebody_flagged_the_word'),
                ),
              ),
            if (setFlag != null)
              IconButton(
                icon: hasFlag
                    ? Icon(Icons.error, color: MyTheme.accent)
                    : Icon(Icons.error_outline),
                tooltip: tr('flag_the_word'),
                onPressed: () => setFlag!(!hasFlag),
              ),
            if (setStatus != null)
              IconButton(
                icon: Icon(status == WordStatus.discarded
                    ? Icons.restore_from_trash
                    : Icons.delete_outline),
                tooltip: status == WordStatus.discarded
                    ? tr('restore_word')
                    : tr('discard_word'),
                onPressed: () {
                  setStatus!(status == WordStatus.discarded
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
                  setFeedback!(newFeedback == feedback ? null : newFeedback);
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
  final LocalGameState localGameState;

  PlayArea({
    required this.localGameData,
    required this.gameController,
    required this.gameData,
    required this.localGameState,
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
  TurnState? get turnState => gameData.turnState;
  LocalGameState get localGameState => widget.localGameState;

  AnimationController? _padlockAnimationController;
  bool _turnActive = false;

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
    if (value) {
      gameController.resumeExplaning();
    } else {
      gameController.pauseExplaning();
    }
  }

  void _wordGuessed() {
    final int combo = gameData.currentCombo();
    Sounds.play(Sounds
        .wordGuessedCombo[min(Sounds.wordGuessedCombo.length - 1, combo)]);
    HapticFeedback.mediumImpact();
    gameController.wordGuessed();
  }

  void _endTurn(int turnRestriction) {
    if (gameData.turnIndex() == turnRestriction &&
        turnState!.turnPhase == TurnPhase.explain) {
      Sounds.play(Sounds.timeOver);
      MyVibration.heavyVibration();
      gameController.finishExplanation();
    }
  }

  void _endBonusTime(int turnRestriction) {
    if (gameData.turnIndex() == turnRestriction &&
        turnState!.turnPhase == TurnPhase.review) {
      Sounds.play(Sounds.bonusTimeOver);
      MyVibration.mediumVibration();
    }
  }

  void _setWordStatus(int wordId, WordStatus status) {
    gameController.setWordStatus(wordId, status);
  }

  void _setWordFeedback(int wordId, WordFeedback? feedback) {
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
    _padlockAnimationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (gameController.isActivePlayer()) {
      return _buildActivePlayer(context);
    } else {
      return _buildInactivePlayer(context);
    }
  }

  Widget _buildInactivePlayer(BuildContext context) {
    final wordReviewItems = gameData
        .wordsInThisTurnData()
        .map((w) => w.status != WordStatus.notExplained
            ? WordReviewItem(
                text: w.text,
                status: w.status,
                feedback: w.feedback,
                hasFlag: w.flaggedByActivePlayer,
                setStatus: null,
                setFeedback: (WordFeedback? feedback) =>
                    _setWordFeedback(w.id, feedback),
                setFlag: (bool hasFlag) => _setWordFlag(w.id, hasFlag),
              )
            : WordReviewItem(
                text: null,
                status: w.status,
                feedback: null,
                hasFlag: false,
                setStatus: null,
                setFeedback: null,
                setFlag: null,
              ))
        .toList();
    final wordReviewView = ListView(
      children: wordReviewItems,
    );

    switch (turnState!.turnPhase) {
      case TurnPhase.prepare:
        return Container();
      case TurnPhase.explain:
        return Column(children: [
          Expanded(
            child: wordReviewView,
          ),
          // Use unique key to make sure Flutter doesn't cache timer state,
          // therefore updates from gameState are effective.
          // Flutter usually uses parent-owned controllers for this.
          // OPTIMIZATION POTENTIAL: The cost of recreating animation
          // controller (inside the timer) may turn out to be non-zero, in
          // which case Flutter approach would be faster.
          if (NtpTime.initialized && turnState!.turnTimeStart != null)
            turnState!.turnPaused!
                ? TimerView(
                    key: UniqueKey(),
                    style: TimerViewStyle.turnTime,
                    duration: Duration(seconds: gameConfig.rules.turnSeconds),
                    startTime: turnState!.turnTimeBeforePause,
                    startPaused: true,
                  )
                : TimerView(
                    key: UniqueKey(),
                    style: TimerViewStyle.turnTime,
                    duration: Duration(seconds: gameConfig.rules.turnSeconds),
                    startTime: turnState!.turnTimeBeforePause! +
                        anyMax(
                            Duration.zero,
                            NtpTime.nowUtcOrThrow()
                                .difference(turnState!.turnTimeStart!)),
                  ),
          SizedBox(height: 12.0),
        ]);
      case TurnPhase.review:
        return Column(children: [
          Expanded(
            child: wordReviewView,
          ),
          if (NtpTime.initialized && turnState!.bonusTimeStart != null)
            TimerView(
              key: UniqueKey(),
              style: TimerViewStyle.bonusTime,
              duration: Duration(seconds: gameConfig.rules.bonusSeconds),
              startTime: anyMax(
                  Duration.zero,
                  NtpTime.nowUtcOrThrow()
                      .difference(turnState!.bonusTimeStart!)),
              hideOnTimeEnded: true,
            ),
          SizedBox(height: 12.0),
        ]);
    }
    Assert.holds(gameData.gameFinished());
    return Container();
  }

  Widget _buildActivePlayer(BuildContext context) {
    final wordsInHatWidget = Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child:
          Text(tr('words_in_hat', args: [gameData.numWordsInHat().toString()])),
    );
    switch (turnState!.turnPhase) {
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
                        _padlockAnimationController!.forward(from: 0.0),
                    coloring: WideButtonColoring.secondary,
                    child: Text(
                      tr('start'),
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
                coloring: WideButtonColoring.neutral,
                child: Text(
                  gameData.currentWordText(),
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              // Don't set start time and paused state from gameState for
              // smoother experience for explaining players and more precise
              // time tracking.
              // Set key to make sure Flutter keeps the timer, because its
              // internal state is the source of truth for turn time.
              child: TimerView(
                key: ValueKey('turn_timer'),
                style: TimerViewStyle.turnTime,
                onTimeEnded: () => _endTurn(gameData.turnIndex()),
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
                    feedback: localGameData.onlineMode ? w.feedback : null,
                    hasFlag: w.flaggedByOthers,
                    setStatus: (WordStatus status) =>
                        _setWordStatus(w.id, status),
                    setFeedback: localGameData.onlineMode
                        ? (WordFeedback? feedback) =>
                            _setWordFeedback(w.id, feedback)
                        : null,
                    setFlag: null,
                  ))
              .toList();
          return Column(children: [
            Expanded(
              child: ListView(
                children: wordReviewItems,
              ),
            ),
            TimerView(
              key: ValueKey('bonus_timer'),
              style: TimerViewStyle.bonusTime,
              onTimeEnded: () => _endBonusTime(gameData.turnIndex()),
              duration: Duration(seconds: gameConfig.rules.bonusSeconds),
              hideOnTimeEnded: true,
            ),
            SizedBox(height: 28.0),
            WideButton(
              onPressed: _reviewDone,
              coloring: WideButtonColoring.secondary,
              child: Text(tr('done')),
              margin: WideButton.bottomButtonMargin,
            ),
          ]);
        }
    }
    Assert.holds(gameData.gameFinished());
    return Container();
  }
}

class GameView extends StatefulWidget {
  final LocalGameData localGameData;

  GameView({required this.localGameData});

  @override
  State<StatefulWidget> createState() => GameViewState();
}

class GameViewState extends State<GameView> {
  final GameNavigator navigator = GameNavigator(currentPhase: GamePhase.play);
  final LocalGameState localGameState = LocalGameState();

  LocalGameData get localGameData => widget.localGameData;

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
    return ConstrainedScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tr('hat_game')),
      ),
      body: Container(
        child: Column(
          children: [
            PartyView(
              gameData.currentPartyViewData(),
              gameData.turnState!.turnPhase,
              localGameData.myPlayerID,
            ),
            Expanded(
              child: PlayArea(
                localGameData: localGameData,
                gameController: gameController,
                gameData: gameData,
                localGameState: localGameState,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
