import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/colors.dart';
import 'package:hatgame/util/markdown.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/dialog.dart';
import 'package:hatgame/widget/enum_option_selector.dart';

class GameInfoView extends StatelessWidget {
  final GameController gameController;

  const GameInfoView({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final makeAction = (
        {required String title,
        required Icon icon,
        required VoidCallback? action}) {
      return Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge!,
          ),
          SizedBox(width: 12),
          FloatingActionButton.small(
            backgroundColor: (action != null)
                ? theme.colorScheme.primary
                : toGrey(theme.colorScheme.primary),
            foregroundColor: (action != null)
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimary.withOpacity(0.9),
            heroTag: null,
            onPressed: action,
            child: icon,
          ),
        ],
      );
    };

    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(context.tr('game_info_title')),
      ),
      body: Markdown(
        data: _describeGame(
            context, gameController.localGameData, gameController.gameData),
        styleSheet: MarkdownUtil.defaultStyle(context).copyWith(
          p: TextStyle(height: 1.2),
          listBullet: TextStyle(height: 1.2),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      // Would be nice if action availability depended on `isAdmin` rather than
      // `isActivePlayer`, but to do this we either need to switch to
      // transactional writes everywhere, or implement a complicated system
      // where each player can write their request to finish into a personal
      // record that doesn't conflict with others (like word feedback) and it is
      // then executed by the active player.
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        distance: 72,
        childrenAnimation: ExpandableFabAnimation.none,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.construction),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          fabSize: ExpandableFabSize.small,
        ),
        overlayStyle: ExpandableFabOverlayStyle(
          color: theme.colorScheme.surface.withOpacity(0.8),
        ),
        children: [
          // TODO: Add "Finish in the end of round" action. Could be
          // separate actions with stop and stop_circle_outlined icons OR
          // different buttons in the confirmation dialog.
          makeAction(
            title: gameController.isActivePlayer()
                ? context.tr('finish_game_action')
                : context.tr('finish_game_forbidden_when_not_active'),
            icon: Icon(Icons.stop),
            action: gameController.isActivePlayer()
                ? () => _requestFinishGame(context, gameController)
                : null,
          ),
          if (gameController.localGameData.onlineMode)
            makeAction(
              title: context.tr('leave_game_action'),
              icon: Icon(Icons.exit_to_app),
              action: () => GameNavigator.leaveGameWithConfirmation(context,
                  localGameData: gameController.localGameData),
            ),
        ],
      ),
    );
  }
}

String _describeGame(
    BuildContext context, LocalGameData localGameData, GameData gameData) {
  final onlineMode = localGameData.onlineMode;
  final config = gameData.config;
  final initialState = gameData.initialState;
  final variantString =
      optionWithValue(getGameVariantOptions(onlineMode), config.rules.variant)!
          .title
          .value(context);

  final info = <String>[];

  final addParagraph = (String text) {
    info.add(text);
  };
  final addTitle = (String title) {
    info.add('### ' + title);
  };
  final addUnorderedList = (Iterable<String> items) {
    info.add(items.map((item) => '- $item').join('\n'));
  };

  addTitle(context.tr('game_info_variant', args: [variantString]));
  addParagraph(context.tr('game_info_turn_times', args: [
    config.rules.turnSeconds.toString(),
    config.rules.bonusSeconds.toString(),
  ]));
  if (config.rules.variant != GameVariant.writeWords) {
    final dictionaryNames = config.rules.dictionaries
        .map((d) => Lexicon.dictionaryMetadata(d).uiName);
    Assert.gt(dictionaryNames.length, 0);
    if (dictionaryNames.length == 1) {
      addParagraph(
          context.tr('game_info_dictionary', args: [dictionaryNames.first]));
    } else {
      addParagraph(context.tr('game_info_dictionaries'));
      addUnorderedList(dictionaryNames);
    }
  }

  switch (gameData.gameProgress()) {
    case FixedWordSetProgress(:final numWords, :final initialNumWords):
      addTitle(context.tr('game_info_fixed_word_set', args: [
        numWords.toString(),
        initialNumWords.toString(),
      ]));
      break;
    case FixedNumRoundsProgress(
        :final roundIndex,
        :final numRounds,
        :final roundTurnIndex,
        :final numTurnsPerRound
      ):
      addTitle(context.tr('game_info_fixed_num_rounds', args: [
        (roundIndex + 1).toString(),
        numRounds.toString(),
        (roundTurnIndex + 1).toString(),
        numTurnsPerRound.toString(),
      ]));
      break;
  }

  if (initialState.teamCompositions.teams != null) {
    addTitle(context.tr('game_info_teams'));
    addUnorderedList(initialState.teamCompositions.teams!
        .map((team) => team.map((p) => config.players!.names[p]!).join(', ')));
  } else {
    addTitle(context.tr('game_info_individual'));
    addUnorderedList(initialState.teamCompositions.individualOrder!
        .map((p) => config.players!.names[p]!));
  }

  return info.join('\n\n');
}

void _requestFinishGame(
    BuildContext context, GameController gameController) async {
  final finish = await multipleChoiceDialog<bool>(
    context: context,
    titleText: context.tr('finish_game_confirmation'),
    choices: [
      DialogChoice(false, context.tr('finish_game_reject')),
      DialogChoice(true, context.tr('finish_game_accept')),
    ],
    defaultChoice: false,
  );
  if (finish) {
    await gameController.finishGame();
  }
}
