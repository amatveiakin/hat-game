import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/widget/numeric_field.dart';

class RulesConfigViewController {
  final turnTimeController = TextEditingController();
  final bonusTimeController = TextEditingController();
  final wordsPerPlayerController = TextEditingController();
  bool _updatingFromConfig = false;
  bool get updatingFromConfig => _updatingFromConfig;

  void updateFromConfig(RulesConfig config) {
    _updatingFromConfig = true;
    turnTimeController.text = config.turnSeconds.toString();
    bonusTimeController.text = config.bonusSeconds.toString();
    wordsPerPlayerController.text = config.wordsPerPlayer.toString();
    _updatingFromConfig = false;
  }

  void dispose() {
    turnTimeController.dispose();
    bonusTimeController.dispose();
    wordsPerPlayerController.dispose();
  }
}

class RulesConfigView extends StatefulWidget {
  final RulesConfigViewController viewController;
  final GameConfigController configController;

  RulesConfigView(
      {@required this.viewController, @required this.configController});

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

  RulesConfigViewController get viewController => widget.viewController;
  GameConfigController get configController => widget.configController;

  @override
  void initState() {
    super.initState();

    viewController.turnTimeController.addListener(() {
      final int newValue = int.tryParse(viewController.turnTimeController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateRules(
            (config) => config.rebuild((b) => b..turnSeconds = newValue));
      }
    });

    viewController.bonusTimeController.addListener(() {
      final int newValue =
          int.tryParse(viewController.bonusTimeController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateRules(
            (config) => config.rebuild((b) => b..bonusSeconds = newValue));
      }
    });

    viewController.wordsPerPlayerController.addListener(() {
      final int newValue =
          int.tryParse(viewController.wordsPerPlayerController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateRules(
            (config) => config.rebuild((b) => b..wordsPerPlayer = newValue));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 4),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text('Turn time'),
              ),
              NumericField(
                controller: viewController.turnTimeController,
                goldenValues: turnTimeGoldenValues,
                suffixText: 's',
              ),
            ],
          ),
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text('Bonus time'),
              ),
              NumericField(
                controller: viewController.bonusTimeController,
                goldenValues: timeGoldenValues,
                suffixText: 's',
              ),
            ],
          ),
        ),
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text('Words per player'),
              ),
              NumericField(
                controller: viewController.wordsPerPlayerController,
                goldenValues: wordsPerPlayerGoldenValues,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
