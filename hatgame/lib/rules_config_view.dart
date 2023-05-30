import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/dictionary_selector.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/lexicon.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/divider.dart';
import 'package:hatgame/widget/highlightable.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/multi_line_list_tile.dart';
import 'package:hatgame/widget/numeric_field.dart';
import 'package:hatgame/widget/switch_button.dart';

class RulesConfigViewController {
  final turnTimeController = TextEditingController();
  final bonusTimeController = TextEditingController();
  final wordsPerPlayerController = TextEditingController();
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
    _updatingFromConfig = false;
  }

  void dispose() {
    turnTimeController.dispose();
    bonusTimeController.dispose();
    wordsPerPlayerController.dispose();
    dictionariesHighlightController.dispose();
  }
}

class RulesConfigView extends StatefulWidget {
  final bool onlineMode;
  final RulesConfigViewController viewController;
  final RulesConfig config;
  final GameConfigController configController;

  const RulesConfigView({
    Key? key,
    required this.onlineMode,
    required this.viewController,
    required this.config,
    required this.configController,
  }) : super(key: key);

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

  static const List<int> wordsPerPlayerGoldenValues = [
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
  ];

  static const _numericFieldPadding = EdgeInsets.symmetric(vertical: 2.0);

  bool get onlineMode => widget.onlineMode;
  RulesConfigViewController get viewController => widget.viewController;
  RulesConfig get config => widget.config;
  GameConfigController get configController => widget.configController;

  Future<void> _setWriteWords(bool writeWords) async {
    if (writeWords && !onlineMode) {
      // TODO: Support writing words in offline mode.
      await showInvalidOperationDialog(
          context: context,
          error: InvalidOperation(
              'Writing words in offline mode is not supported (yet).'));
      return;
    }
    configController.updateRules(
        (config) => config.rebuild((b) => b..writeWords = writeWords));
  }

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
  }

  @override
  Widget build(BuildContext context) {
    final dictionariesOnTap = configController.isReadOnly
        ? null
        : () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DictionarySelector(
                      allValues: Lexicon.allDictionaries(),
                      initialValues: config.dictionaries!.toList(),
                      onChanged: (List<String> newValue) => configController
                          .updateRules((config) => config.rebuild(
                              (b) => b..dictionaries.replace(newValue))),
                    )));
          };
    final dictionaryNames =
        config.dictionaries?.map((d) => Lexicon.dictionaryMetadata(d).uiName);
    final String dictionariesCaption =
        dictionaryNames == null || dictionaryNames.isEmpty
            ? tr('dictionaries_none')
            : dictionaryNames.length == 1
                ? tr('dictionary_one') + dictionaryNames.first
                : tr('dictionaries_many') +
                    '\n' +
                    dictionaryNames.map((d) => '        $d').join('\n');

    return ListView(
      children: [
        SectionDivider(
          title: tr('timer'),
          firstSection: true,
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(tr('turn_time')),
              ),
              Padding(
                padding: _numericFieldPadding,
                child: NumericField(
                  readOnly: configController.isReadOnly,
                  controller: viewController.turnTimeController,
                  goldenValues: turnTimeGoldenValues,
                  suffixText: tr('s'),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(tr('bonus_time')),
              ),
              Padding(
                padding: _numericFieldPadding,
                child: NumericField(
                  readOnly: configController.isReadOnly,
                  controller: viewController.bonusTimeController,
                  goldenValues: timeGoldenValues,
                  suffixText: tr('s'),
                ),
              ),
            ],
          ),
        ),
        SectionDivider(
          title: tr('words'),
        ),
        MultiLineListTile(
          title: SwitchButton(
            options: [tr('random_words'), tr('write_words')],
            selectedOption: config.writeWords ? 1 : 0,
            onSelectedOptionChanged: configController.isReadOnly
                ? null
                : (int newOption) => _setWriteWords(newOption == 1),
          ),
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(tr('words_per_player')),
              ),
              Padding(
                padding: _numericFieldPadding,
                child: NumericField(
                  readOnly: configController.isReadOnly,
                  controller: viewController.wordsPerPlayerController,
                  goldenValues: wordsPerPlayerGoldenValues,
                ),
              ),
            ],
          ),
        ),
        if (!config.writeWords)
          Highlightable(
            controller: viewController.dictionariesHighlightController,
            child: MultiLineListTile(
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
