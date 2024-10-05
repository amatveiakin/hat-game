import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/markdown.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/enum_option_selector.dart';

class GameInfoView extends StatelessWidget {
  final LocalGameData localGameData;
  final GameData gameData;

  const GameInfoView(
      {super.key, required this.localGameData, required this.gameData});

  @override
  Widget build(BuildContext context) {
    // TODO: Add Abort button.
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(context.tr('game_info_title')),
      ),
      body: Markdown(
        data: _describeGame(context, localGameData, gameData),
        styleSheet: MarkdownUtil.defaultStyle(context).copyWith(
          p: TextStyle(height: 1.2),
          listBullet: TextStyle(height: 1.2),
        ),
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

  final progress = gameData.gameProgress();
  switch (progress) {
    case FixedWordSetProgress():
      addTitle(context.tr('game_info_fixed_word_set', args: [
        progress.numWords.toString(),
        progress.initialNumWords.toString(),
      ]));
      break;
    case FixedNumRoundsProgress():
      addTitle(context.tr('game_info_fixed_num_rounds', args: [
        (progress.roundIndex + 1).toString(),
        progress.numRounds.toString(),
        (progress.roundTurnIndex + 1).toString(),
        progress.numTurnsPerRound.toString(),
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
