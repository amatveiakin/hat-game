import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/dictionary_selector.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/local_str.dart';
import 'package:hatgame/util/markdown.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/divider.dart';
import 'package:hatgame/widget/enum_option_selector.dart';
import 'package:hatgame/widget/highlightable.dart';
import 'package:hatgame/widget/numeric_field.dart';

List<OptionItem<GameVariant>> getGameVariantOptions(bool onlineMode) {
  return [
    OptionChoice(
      value: GameVariant.standard,
      title: LocalStr.tr('variant_standard'),
      subtitle: LocalStr.tr('variant_standard_description'),
    ),
    OptionChoice(
      value: GameVariant.writeWords,
      title: LocalStr.tr('variant_write_words'),
      subtitle: onlineMode
          ? LocalStr.tr('variant_write_words_description')
          : LocalStr.tr('variant_write_words_disabled_description'),
      enabled: onlineMode,
    ),
    OptionChoice(
      value: GameVariant.taboo,
      title: LocalStr.tr('variant_taboo'),
      subtitle: LocalStr.tr('variant_taboo_description'),
    ),
    OptionChoice(
      value: GameVariant.pluralias,
      title: LocalStr.tr('variant_pluralias'),
      subtitle: LocalStr.tr('variant_pluralias_description'),
      onInfo: (context) => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (context) => const PluraliasHelpScreen())),
    ),
  ];
}

List<OptionItem<GameExtent>> getGameExtentOptions(bool onlineMode) {
  return [
    OptionChoice(
      value: GameExtent.fixedWordSet,
      title: LocalStr.tr('extent_fixed_word_set'),
      subtitle: LocalStr.tr('extent_fixed_word_set_description'),
    ),
    OptionChoice(
      value: GameExtent.fixedNumRounds,
      title: LocalStr.tr('extent_fixed_num_rounds'),
      subtitle: LocalStr.tr('extent_fixed_num_rounds_description'),
    ),
  ];
}

class GameVariantSelector extends EnumOptionSelector<GameVariant> {
  GameVariantSelector(
      GameVariant initialValue, ValueChanged<GameVariant> changeCallback,
      {required bool onlineMode, super.key})
      : super(
          windowTitle: LocalStr.tr('variant'),
          allValues: getGameVariantOptions(onlineMode),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => GameVariantSelectorState();
}

class GameVariantSelectorState
    extends EnumOptionSelectorState<GameVariant, GameVariantSelector> {}

class GameExtentSelector extends EnumOptionSelector<GameExtent> {
  GameExtentSelector(
      GameExtent initialValue, ValueChanged<GameExtent> changeCallback,
      {required bool onlineMode, super.key})
      : super(
          windowTitle: LocalStr.tr('variant'),
          allValues: getGameExtentOptions(onlineMode),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => GameExtentSelectorState();
}

class GameExtentSelectorState
    extends EnumOptionSelectorState<GameExtent, GameExtentSelector> {}

class RulesConfigViewController {
  final turnTimeController = TextEditingController();
  final bonusTimeController = TextEditingController();
  final wordsPerPlayerController = TextEditingController();
  final numRoundsController = TextEditingController();
  final HighlightableController dictionariesHighlightController;
  bool _updatingFromConfig = false;
  bool get updatingFromConfig => _updatingFromConfig;

  RulesConfigViewController({required TickerProvider vsync})
      : dictionariesHighlightController = HighlightableController(vsync: vsync);

  static void _updateText(TextEditingController controller, String text) {
    if (controller.text != text) {
      // TODO: Does this ever happen?
      controller.text = text;
    }
  }

  void updateFromConfig(RulesConfig config) {
    _updatingFromConfig = true;
    _updateText(turnTimeController, config.turnSeconds.toString());
    _updateText(bonusTimeController, config.bonusSeconds.toString());
    _updateText(wordsPerPlayerController, config.wordsPerPlayer.toString());
    _updateText(numRoundsController, config.numRounds.toString());
    _updatingFromConfig = false;
  }

  void dispose() {
    turnTimeController.dispose();
    bonusTimeController.dispose();
    wordsPerPlayerController.dispose();
    numRoundsController.dispose();
    dictionariesHighlightController.dispose();
  }
}

class RulesConfigView extends StatefulWidget {
  final bool onlineMode;
  final RulesConfigViewController viewController;
  final RulesConfig config;
  final GameConfigController configController;

  const RulesConfigView({
    super.key,
    required this.onlineMode,
    required this.viewController,
    required this.config,
    required this.configController,
  });

  @override
  State<StatefulWidget> createState() => RulesConfigViewState();
}

class RulesConfigViewState extends State<RulesConfigView> {
  static const List<int> timeGoldenValues = [
    0,
    3,
    5,
    7,
    10,
    15,
    20,
    25,
    30,
    40,
    50,
    60,
    90,
    120,
    150,
    180,
    240,
    300,
  ];

  static final List<int> turnTimeGoldenValues =
      timeGoldenValues.where((t) => t > 0).toList();

  static const List<int> nonTimeGoldenValues = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    10,
    12,
    15,
    20,
    25,
    30,
    40,
    50,
    60,
    80,
    100,
  ];

  bool get onlineMode => widget.onlineMode;
  RulesConfigViewController get viewController => widget.viewController;
  RulesConfig get config => widget.config;
  GameConfigController get configController => widget.configController;

  @override
  void initState() {
    super.initState();

    viewController.turnTimeController.addListener(() {
      final int? newValue =
          int.tryParse(viewController.turnTimeController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateRules(
            (config) => config.rebuild((b) => b..turnSeconds = newValue));
      }
    });

    viewController.bonusTimeController.addListener(() {
      final int? newValue =
          int.tryParse(viewController.bonusTimeController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateRules(
            (config) => config.rebuild((b) => b..bonusSeconds = newValue));
      }
    });

    viewController.wordsPerPlayerController.addListener(() {
      final int? newValue =
          int.tryParse(viewController.wordsPerPlayerController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateRules(
            (config) => config.rebuild((b) => b..wordsPerPlayer = newValue));
      }
    });

    viewController.numRoundsController.addListener(() {
      final int? newValue =
          int.tryParse(viewController.numRoundsController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateRules(
            (config) => config.rebuild((b) => b..numRounds = newValue));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dictionariesOnTap = configController.isReadOnly
        ? null
        : () {
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (context) {
              isValidDictionary(DictionaryKind kind) {
                return config.variant == GameVariant.taboo
                    ? kind == DictionaryKind.taboo
                    : kind == DictionaryKind.standard;
              }

              return DictionarySelector(
                allValues: Lexicon.allDictionaries()
                    .where((d) =>
                        isValidDictionary(Lexicon.dictionaryMetadata(d).kind))
                    .toList(),
                initialValues: config.dictionaries.toList(),
                onChanged: (List<String> newValue) =>
                    configController.updateRules((config) => config
                        .rebuild((b) => b..dictionaries.replace(newValue))),
              );
            }));
          };
    final dictionaryNames =
        config.dictionaries.map((d) => Lexicon.dictionaryMetadata(d).uiName);
    final String dictionariesCaption = dictionaryNames.isEmpty
        ? context.tr('dictionaries_none')
        : dictionaryNames.length == 1
            ? context.tr('dictionary_one') + dictionaryNames.first
            : context.tr('dictionaries_many') +
                '\n' +
                dictionaryNames.map((d) => '        $d').join('\n');

    return ListView(
      children: [
        SectionDivider(
          title: context.tr('timer'),
          firstSection: true,
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(context.tr('turn_time')),
              ),
              NumericField(
                readOnly: configController.isReadOnly,
                controller: viewController.turnTimeController,
                goldenValues: turnTimeGoldenValues,
                suffixText: context.tr('s'),
              ),
            ],
          ),
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(context.tr('bonus_time')),
              ),
              NumericField(
                readOnly: configController.isReadOnly,
                controller: viewController.bonusTimeController,
                goldenValues: timeGoldenValues,
                suffixText: context.tr('s'),
              ),
            ],
          ),
        ),
        SectionDivider(
          title: context.tr('words'),
        ),
        OptionSelectorHeader(
            title: Text(switch (config.variant) {
              GameVariant.standard => context.tr('variant_standard'),
              GameVariant.writeWords => context.tr('variant_write_words'),
              GameVariant.taboo => context.tr('variant_taboo'),
              GameVariant.pluralias => context.tr('variant_pluralias'),
              _ => Assert.unexpectedValue(config.variant),
            }),
            onTap: configController.isReadOnly
                ? null
                : () {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (context) => GameVariantSelector(
                              config.variant,
                              (GameVariant newValue) => configController.update(
                                  (config) => GameConfigController
                                      .fixDictionariesForGameVariant(
                                          config.rebuild((b) =>
                                              b..rules.variant = newValue))),
                              onlineMode: onlineMode,
                            )));
                  }),
        if (config.variant != GameVariant.writeWords)
          OptionSelectorHeader(
              title: Text(switch (config.extent) {
                GameExtent.fixedWordSet => context.tr('extent_fixed_word_set'),
                GameExtent.fixedNumRounds =>
                  context.tr('extent_fixed_num_rounds'),
                _ => Assert.unexpectedValue(config.variant),
              }),
              onTap: configController.isReadOnly
                  ? null
                  : () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (context) => GameExtentSelector(
                                config.extent,
                                (GameExtent newValue) => configController
                                    .update((config) => GameConfigController
                                        .fixGameExtentForGameVariant(
                                            config.rebuild((b) =>
                                                b..rules.extent = newValue))),
                                onlineMode: onlineMode,
                              )));
                    }),
        ListTile(
          title: Row(
            children: switch (config.extent) {
              GameExtent.fixedWordSet => [
                  Expanded(
                    child: Text(context.tr('words_per_player')),
                  ),
                  NumericField(
                    readOnly: configController.isReadOnly,
                    controller: viewController.wordsPerPlayerController,
                    goldenValues: nonTimeGoldenValues,
                  ),
                ],
              GameExtent.fixedNumRounds => [
                  Expanded(
                    child: Text(context.tr('num_rounds')),
                  ),
                  NumericField(
                    readOnly: configController.isReadOnly,
                    controller: viewController.numRoundsController,
                    goldenValues: nonTimeGoldenValues,
                  ),
                ],
              _ => Assert.unexpectedValue(config.extent),
            },
          ),
        ),
        if (config.variant != GameVariant.writeWords)
          Highlightable(
            controller: viewController.dictionariesHighlightController,
            child: ListTile(
                title: Text(dictionariesCaption),
                trailing: dictionariesOnTap == null
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: dictionariesOnTap),
          ),
      ],
    );
  }
}

class PluraliasHelpScreen extends StatelessWidget {
  // TODO: Should we also use the named path when opening pluralias help from
  // rules config?
  static const String routeName = '/pluralias';

  const PluraliasHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(context.tr('pluralias_help_title')),
      ),
      body: Markdown(
        data: context.tr('pluralias_help_body'),
        styleSheet: MarkdownUtil.defaultStyle(context),
      ),
    );
  }
}
