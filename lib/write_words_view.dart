import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/built_value/personal_state.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/checkbox_button.dart';
import 'package:hatgame/widget/checked_text_field.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/image_assert_icon.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/wide_button.dart';
import 'package:unicode/unicode.dart' as unicode;

// Note: this is similar to checkPlayerName, should consider syncing changes.
InvalidOperation checkWord(String word) {
  if (word.isEmpty) {
    return InvalidOperation('Word is empty');
  }
  if (word.length > 50) {
    return InvalidOperation('Word is too long');
  }
  for (final c in word.codeUnits) {
    if (unicode.isControl(c) || unicode.isFormat(c)) {
      return InvalidOperation('Word contans invalid character: '
          '${String.fromCharCode(c)} (code $c)');
    }
  }
  return null;
}

class WriteWordsViewController {
  final List<CheckedTextFieldController> controllers;
  BuiltList<String> latestWords;

  WriteWordsViewController({@required int numWords})
      : controllers = List<CheckedTextFieldController>.generate(
          numWords,
          (index) => CheckedTextFieldController(checker: checkWord),
        );

  void updateWords(BuiltList<String> words) {
    Assert.holds(words != null);
    // There can be a mismatch between words.length and controllers.length
    // if you go back to config and change num words per player.
    for (int i = 0; i < min(words.length, controllers.length); i++) {
      controllers[i].textController.text = words[i];
    }
  }

  BuiltList<String> getWords() {
    return BuiltList.of(controllers.map((c) => c.textController.text.trim()));
  }

  void addTextChangedListener(VoidCallback listener) {
    controllers.forEach((c) => c.textController.addListener(() {
          final words = getWords();
          if (latestWords != words) {
            listener();
            latestWords = words;
          }
        }));
  }

  void dispose() {
    controllers.forEach((c) => c.dispose());
  }
}

class WriteWordsView extends StatefulWidget {
  final LocalGameData localGameData;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  WriteWordsView({@required this.localGameData});

  @override
  createState() => WriteWordsViewState();
}

class WriteWordsViewState extends State<WriteWordsView> {
  final GameNavigator navigator =
      GameNavigator(currentPhase: GamePhase.writeWords);
  WriteWordsViewController _viewController;

  LocalGameData get localGameData => widget.localGameData;

  void _generateRandomWord(TextEditingController controller) {
    controller.text = Lexion.randomWord();
    FocusScope.of(context).unfocus();
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

  @override
  void dispose() {
    _viewController.dispose();
    super.dispose();
  }

  void _updateState(PersonalState oldPersonalState, {@required bool ready}) {
    if (ready) {
      ready = checkTextFields(_viewController.controllers);
    }
    GameController.updatePersonalState(
      localGameData,
      oldPersonalState.rebuild(
        (b) => b
          ..words.replace(_viewController.getWords())
          ..wordsReady = ready,
      ),
    );
  }

  void _onBackPressed() {
    GameController.backFromWordWritingPhase(localGameData.gameReference);
  }

  void _next(GameConfig gameConfig) async {
    try {
      await GameController.updateTeamCompositions(
          localGameData.gameReference, gameConfig);
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
    }
  }

  void _showPlayersNotReady(List<String> playersNotReady) async {
    widget.scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text('Waiting for: ' + playersNotReady.join(', ')),
    ));
  }

  Widget buildBody(BuildContext context, DBDocumentSnapshot snapshot) {
    final GameConfig gameConfig =
        GameConfigController.fromSnapshot(localGameData, snapshot)
            .configWithOverrides();
    final WordWritingViewData viewData =
        GameController.getWordWritingViewData(localGameData, snapshot);
    final PersonalState playerState = viewData.playerState;
    Assert.holds(gameConfig.rules.writeWords);

    if (_viewController == null) {
      _viewController =
          WriteWordsViewController(numWords: gameConfig.rules.wordsPerPlayer);
      _viewController.addTextChangedListener(
          () => _updateState(playerState, ready: false));
      if (playerState.words != null) {
        _viewController.updateWords(playerState.words);
      }
    }
    final bool everybodyReady = viewData.numPlayersReady == viewData.numPlayers;

    // Note: keep in sync with offline_player_config_view.dart
    final listItemPaddingSmallRight = EdgeInsets.fromLTRB(10, 1, 5, 1);
    final tiles = _viewController.controllers
        .map(
          (controller) => ListTile(
            contentPadding: listItemPaddingSmallRight,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  // Note: keep style in sync with offline_player_config_view.dart
                  child: CheckedTextField(
                    controller: controller,
                    onEditingComplete: () {
                      // Hide virtual keyboard when 'done' is pressed.
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                IconButton(
                  icon: ImageAssetIcon('images/dice.png'),
                  onPressed: () =>
                      _generateRandomWord(controller.textController),
                  tooltip: 'Generate a random word',
                )
              ],
            ),
          ),
        )
        .toList();
    return ConstrainedScaffold(
      scaffoldKey: widget.scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: localGameData.isAdmin,
        title: Text('Write Your Words'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: ListView(children: tiles),
            ),
          ),
          WideWidget(
            child: CheckboxButton(
              title: Text('Ready'),
              value: playerState.wordsReady ?? false,
              onChanged: (value) => _updateState(playerState, ready: value),
            ),
          ),
          WideButton(
            onPressed: localGameData.isAdmin && everybodyReady
                ? () => _next(gameConfig)
                : null,
            onPressedDisabled: everybodyReady
                ? null
                : () => _showPlayersNotReady(viewData.playersNotReady),
            color: MyTheme.accent,
            // Note: keep text in sync with game_config_view.dart
            child: everybodyReady
                ? GoNextButtonCaption(gameConfig.teaming.teamPlay
                    ? 'Teams & Turn Order'
                    : 'Turn Order')
                : Text(
                    'Ready: '
                    '${viewData.numPlayersReady}/${viewData.numPlayers}',
                  ),
            margin: WideButton.bottomButtonMargin,
          ),
        ],
      ),
    );
  }
}
