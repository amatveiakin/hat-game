import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/built_value/word.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_info_view.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/decorated_text.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/functions.dart';
import 'package:hatgame/util/ntp_time.dart';
import 'package:hatgame/util/sounds.dart';
import 'package:hatgame/util/vibration.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/image_assert_icon.dart';
import 'package:hatgame/widget/padlock.dart';
import 'package:hatgame/widget/round_progress_indicator.dart';
import 'package:hatgame/widget/timer.dart';
import 'package:hatgame/widget/wide_button.dart';

class GlowingWidget extends AnimatedWidget {
  final Widget child;
  final bool enableGlow;

  const GlowingWidget(
      {super.key,
      required this.child,
      required Animation<double> animation,
      this.enableGlow = true})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Container(
        decoration: enableGlow
            ? BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: MyTheme.secondaryIntense,
                    blurRadius: 6.0,
                    spreadRadius: animation.value * 5.0,
                  ),
                ],
              )
            : null,
        child: child);
  }
}

class PartyView extends StatelessWidget {
  final PartyViewData party;
  final TurnPhase turnPhase;
  final int? myPlayerID;

  const PartyView(this.party, this.turnPhase, this.myPlayerID, {super.key});

  Widget _playerView(PlayerViewData playerData) {
    Widget textWidget = Text(playerData.name!);
    final animationDuration = turnPhase == TurnPhase.prepare
        ? Duration.zero
        : const Duration(milliseconds: 300);
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
            decorationColor: MyTheme.secondary,
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _playerView(party.performer),
          if (party.recipients.isNotEmpty) const Text(' → '),
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
        ? const Icon(Icons.thumbs_up_down_outlined)
        : const Icon(Icons.clear_outlined);
  }
  return switch (feedback) {
    WordFeedback.good => active
        ? const Icon(Icons.thumb_up, color: MyTheme.secondary)
        : const Icon(Icons.thumb_up_outlined),
    WordFeedback.bad => active
        ? const Icon(Icons.thumb_down, color: MyTheme.secondary)
        : const Icon(Icons.thumb_down_outlined),
    WordFeedback.tooEasy => active
        ? const ImageAssetIcon('images/too_easy_filled.png',
            color: MyTheme.secondary)
        : const ImageAssetIcon('images/too_easy_outlined.png'),
    WordFeedback.tooHard => active
        ? const ImageAssetIcon('images/too_hard_filled.png',
            color: MyTheme.secondary)
        : const ImageAssetIcon('images/too_hard_outlined.png'),
    _ => Assert.unexpectedValue(feedback),
  };
}

String _getWordFeedbackText(BuildContext context, WordFeedback feedback) {
  return switch (feedback) {
    WordFeedback.good => context.tr('word_feedback_nice'),
    WordFeedback.bad => context.tr('word_feedback_ugly'),
    WordFeedback.tooEasy => context.tr('word_feedback_too_easy'),
    WordFeedback.tooHard => context.tr('word_feedback_too_hard'),
    _ => Assert.unexpectedValue(feedback),
  };
}

class WordReviewItem extends StatelessWidget {
  final GameConfig gameConfig;
  final String? text;
  final WordStatus status;
  final WordFeedback? feedback;
  final bool hasFlag;
  final void Function(WordStatus)? setStatus;
  final void Function(WordFeedback?)? setFeedback;
  final void Function(bool)? setFlag;

  const WordReviewItem(
      {super.key,
      required this.gameConfig,
      required this.text,
      required this.status,
      required this.feedback,
      this.hasFlag = false,
      required this.setStatus,
      required this.setFeedback,
      required this.setFlag});

  @override
  Widget build(BuildContext context) {
    bool statusToChecked(WordStatus status) {
      return status == WordStatus.explained;
    }

    WordStatus checkedToStatus(bool checked) {
      return checked ? WordStatus.explained : WordStatus.notExplained;
    }

    // TODO: Consider using LabeledCheckbox.
    return InkWell(
      onTap: () {
        setStatus!(checkedToStatus(!statusToChecked(status)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Row(
          children: [
            Checkbox(
              value: statusToChecked(status),
              onChanged: setStatus != null
                  ? (bool? newValue) => setStatus!(checkedToStatus(newValue!))
                  : null,
            ),
            Expanded(
              child: text == null
                  ? const Row(
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
                padding: const EdgeInsets.all(8.0),
                child: Tooltip(
                  message: context.tr('somebody_flagged_the_word'),
                  child: const Icon(Icons.error, color: MyTheme.primary),
                ),
              ),
            if (setFlag != null)
              IconButton(
                icon: hasFlag
                    ? const Icon(Icons.error, color: MyTheme.secondary)
                    : const Icon(Icons.error_outline),
                tooltip: context.tr('flag_the_word'),
                onPressed: () => setFlag!(!hasFlag),
              ),
            if (setStatus != null &&
                gameConfig.rules.extent == GameExtent.fixedWordSet)
              IconButton(
                icon: Icon(status == WordStatus.discarded
                    ? Icons.restore_from_trash
                    : Icons.delete_outline),
                tooltip: status == WordStatus.discarded
                    ? context.tr('restore_word')
                    : context.tr('discard_word'),
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
                      .map((wf) => PopupMenuItem<WordFeedback>(
                            value: wf,
                            child: ListTile(
                                leading: _getWordFeedbackIcon(
                                    wf, false, wf == feedback),
                                title: Text(_getWordFeedbackText(context, wf))),
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

  const PlayArea({
    super.key,
    required this.localGameData,
    required this.gameController,
    required this.gameData,
    required this.localGameState,
  });

  @override
  State<StatefulWidget> createState() => PlayAreaState();
}

class PlayAreaState extends State<PlayArea> with TickerProviderStateMixin {
  LocalGameData get localGameData => widget.localGameData;
  GameController get gameController => widget.gameController;
  GameConfig get gameConfig => gameData.config;
  GameData get gameData => widget.gameData;
  TurnState? get turnState => gameData.turnState;
  LocalGameState get localGameState => widget.localGameState;

  late AnimationController _glowAnimationController;
  late Animation<double> _glowAnimation;
  late AnimationController _padlockAnimationController;
  ValueNotifier<bool> _padlockReadyToOpen = ValueNotifier(false);
  bool _turnActive = false;

  void _startExplaning() {
    setState(() {
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

  void _setWordStatus(WordId wordId, WordStatus status) {
    gameController.setWordStatus(wordId, status);
  }

  void _setWordFeedback(WordId wordId, WordFeedback? feedback) {
    gameController.setWordFeedback(wordId, feedback);
  }

  void _setWordFlag(WordId wordId, bool hasFlag) {
    gameController.setWordFlag(wordId, hasFlag);
  }

  void _reviewDone() {
    gameController.nextTurn();
  }

  @override
  void initState() {
    super.initState();
    _padlockAnimationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _glowAnimationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _glowAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_glowAnimationController);
    _padlockReadyToOpen.addListener(() {
      if (_padlockReadyToOpen.value) {
        _glowAnimationController.reset();
        _glowAnimationController.repeat(reverse: true);
      } else {
        _glowAnimationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _padlockAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (gameController.isActivePlayer()) {
      return LayoutBuilder(builder: _buildActivePlayer);
    } else {
      return _buildInactivePlayer(context);
    }
  }

  Widget _buildInactivePlayer(BuildContext context) {
    final wordReviewView = () {
      return ListView(
        children: gameData
            .wordsInThisTurnData()
            .map((w) => w.status != WordStatus.notExplained
                ? WordReviewItem(
                    gameConfig: gameConfig,
                    text: w.content.text,
                    status: w.status,
                    feedback: w.feedback,
                    hasFlag: w.flaggedByActivePlayer,
                    setStatus: null,
                    setFeedback: (WordFeedback? feedback) =>
                        _setWordFeedback(w.id, feedback),
                    setFlag: (bool hasFlag) => _setWordFlag(w.id, hasFlag),
                  )
                : WordReviewItem(
                    gameConfig: gameConfig,
                    text: null,
                    status: w.status,
                    feedback: null,
                    hasFlag: false,
                    setStatus: null,
                    setFeedback: null,
                    setFlag: null,
                  ))
            .toList(),
      );
    };

    switch (turnState!.turnPhase) {
      case TurnPhase.prepare:
        // TODO: Display game progress for inactive players too.
        return Container();
      case TurnPhase.explain:
        return Column(children: [
          Expanded(
            child: wordReviewView(),
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
          const SizedBox(height: 12.0),
        ]);
      case TurnPhase.review:
      case TurnPhase.rereview:
        return Column(children: [
          Expanded(
            child: wordReviewView(),
          ),
          if (gameConfig.rules.bonusSeconds > 0 &&
              NtpTime.initialized &&
              turnState!.bonusTimeStart != null &&
              turnState!.turnPhase == TurnPhase.review)
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
          const SizedBox(height: 12.0),
        ]);
    }
    Assert.holds(gameData.gameFinished());
    return Container();
  }

  Widget _buildActivePlayer(BuildContext context, BoxConstraints constraints) {
    final double bottomWidgetHeight = min(500, constraints.maxHeight * 0.60);
    final double bottomWidgetWidth =
        min(bottomWidgetHeight, min(200, constraints.maxWidth * 0.6));
    final bottomWidgetSize = Size(bottomWidgetWidth, bottomWidgetHeight);
    final topPadding = constraints.maxHeight * 0.18;

    final gameProgressWidget = () {
      final body = switch (gameData.gameProgress()) {
        FixedWordSetProgress(:final numWords) =>
          Text(context.tr('words_in_hat', args: [numWords.toString()])),
        FixedNumRoundsProgress(
          :final roundIndex,
          :final numRounds,
          :final roundTurnIndex,
          :final numTurnsPerRound
        ) =>
          Column(
            children: [
              Text((numRounds == 1)
                  ? context.tr('single_round')
                  : context.tr(
                      (roundTurnIndex == 0 && numTurnsPerRound > 1)
                          ? 'round_begins'
                          : 'round_index',
                      args: [
                          (roundIndex + 1).toString(),
                          numRounds.toString()
                        ])),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: RoundProgressIndicator(
                  roundIndex: roundIndex,
                  numRounds: numRounds,
                  roundProgress: roundTurnIndex / numTurnsPerRound,
                  baseColor: MyTheme.secondarySemiIntense.withOpacity(0.85),
                  completionColor: MyTheme.primary,
                ),
              ),
            ],
          ),
      };
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: body,
      );
    };

    switch (turnState!.turnPhase) {
      case TurnPhase.prepare:
        return Column(
          children: [
            SizedBox(
              height: topPadding,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ListenableBuilder(
                      listenable: _padlockReadyToOpen,
                      builder: (BuildContext context, Widget? child) {
                        return GlowingWidget(
                            animation: _glowAnimation,
                            enableGlow: _padlockReadyToOpen.value,
                            // TODO: Replace disabled button with smth else. It's
                            // not really disabled, it's just not a button. Also,
                            // glow is low contrast with button background.
                            child: WideButton(
                              // TODO: Use start button for non-touch devices.
                              // onPressed: _startExplaning,
                              onPressed: null,
                              onPressedDisabled: () =>
                                  _padlockAnimationController.forward(
                                      from: 0.0),
                              coloring: _padlockReadyToOpen.value
                                  ? WideButtonColoring.secondaryAlwaysActive
                                  : WideButtonColoring.secondary,
                              child: Text(
                                _padlockReadyToOpen.value
                                    ? context.tr('release_to_start')
                                    : context.tr('pull_to_start'),
                                style: const TextStyle(fontSize: 24.0),
                              ),
                            ));
                      }),
                  Padlock(
                    size: bottomWidgetSize,
                    onUnlocked: _startExplaning,
                    animationController: _padlockAnimationController,
                    wordsInHat: gameData.numWordsInHat(),
                    readyToOpen: _padlockReadyToOpen,
                  ),
                ],
              ),
            ),
            gameProgressWidget(),
          ],
        );
      case TurnPhase.explain:
        final wordContent = gameData.currentWordContent();
        return Column(children: [
          SizedBox(
            height: topPadding,
          ),
          Expanded(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              WideButton(
                onPressed: _turnActive ? _wordGuessed : null,
                coloring: WideButtonColoring.neutral,
                child: DecoratedText(
                  text: wordContent.text,
                  highlightFirst: wordContent.highlightFirst,
                  highlightLast: wordContent.highlightLast,
                  lineColor: MyTheme.primary.shade400.withOpacity(0.8),
                  textStyle: DefaultTextStyle.of(context)
                      .style
                      .copyWith(fontSize: 24.0, fontWeight: FontWeight.w500),
                ),
              ),
              // Don't set start time and paused state from gameState for
              // smoother experience for explaining players and more precise
              // time tracking.
              // Set key to make sure Flutter keeps the timer, because its
              // internal state is the source of truth for turn time.
              SizedBox.fromSize(
                size: bottomWidgetSize,
                child: Align(
                  alignment: Alignment.center,
                  child: TimerView(
                    key: const ValueKey('turn_timer'),
                    style: TimerViewStyle.turnTime,
                    onTimeEnded: () => _endTurn(gameData.turnIndex()),
                    onRunningChanged: _setTurnActive,
                    duration: Duration(seconds: gameConfig.rules.turnSeconds),
                  ),
                ),
              ),
            ]),
          ),
          // TODO: Dim text color similarly to team name.
          gameProgressWidget(),
        ]);
      case TurnPhase.review:
      case TurnPhase.rereview:
        {
          final wordReviewItems = gameData
              .wordsInThisTurnData()
              .map((w) => (!localGameData.onlineMode &&
                      gameConfig.rules.extent == GameExtent.fixedWordSet &&
                      w.status == WordStatus.notExplained &&
                      turnState!.turnPhase == TurnPhase.rereview)
                  // Hide words that go back to hat during rereview. The typical
                  // case for going back to the last turn results is to make
                  // sure that the player before you explained their words
                  // correctly. For this, seeing explained words is useful, but
                  // words that go back to hat are a spoiler.
                  ? WordReviewItem(
                      gameConfig: gameConfig,
                      text: null,
                      status: w.status,
                      feedback: null,
                      hasFlag: false,
                      setStatus: (WordStatus status) =>
                          _setWordStatus(w.id, status),
                      setFeedback: null,
                      setFlag: null,
                    )
                  : WordReviewItem(
                      gameConfig: gameConfig,
                      text: w.content.text,
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
            if (gameConfig.rules.bonusSeconds > 0 &&
                turnState!.turnPhase == TurnPhase.review)
              TimerView(
                key: const ValueKey('bonus_timer'),
                style: TimerViewStyle.bonusTime,
                onTimeEnded: () => _endBonusTime(gameData.turnIndex()),
                duration: Duration(seconds: gameConfig.rules.bonusSeconds),
                hideOnTimeEnded: true,
              ),
            const SizedBox(height: 28.0),
            WideButton(
              onPressed: _reviewDone,
              coloring: WideButtonColoring.secondary,
              margin: WideButton.bottomButtonMargin,
              child: Text(context.tr('done')),
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

  const GameView({super.key, required this.localGameData});

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
    final turnPhase = gameData.turnState!.turnPhase;
    return ConstrainedScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(turnPhase == TurnPhase.rereview
            ? context.tr('rereview_title')
            : context.tr('hat_game')),
        actions: [
          // Don't show game info during rereview, because it is not clear what
          // state should be displayed. Both the state reverted to the last turn
          // and the present state feel potentially confusing.
          if (turnPhase != TurnPhase.rereview)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (context) =>
                          GameInfoView(gameController: gameController))),
            ),
        ],
      ),
      body: Column(
        children: [
          PartyView(
            gameData.currentPartyViewData(),
            turnPhase,
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
    );
  }
}
