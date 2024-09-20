import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/enum_option_selector.dart';
import 'package:hatgame/widget/numeric_field.dart';

// TODO: Add icons
getTeamingStyleOptions() {
  return [
    OptionDescription(
      value: TeamingStyle.individual,
      title: tr('teaming_individual'),
      subtitle: tr('teaming_individual_description'),
    ),
    OptionDescription(
      value: TeamingStyle.oneToAll,
      title: tr('teaming_one_to_all'),
      subtitle: tr('teaming_one_to_all_description'),
    ),
    OptionDescription(
      value: TeamingStyle.randomPairs,
      title: tr('teaming_random_pairs'),
      subtitle: tr('teaming_random_pairs_description'),
    ),
    OptionDescription(
      value: TeamingStyle.randomTeams,
      title: tr('teaming_random_teams'),
      subtitle: tr('teaming_random_teams_description'),
    ),
    OptionDescription(
      value: TeamingStyle.manualTeams,
      title: tr('teaming_manual_teams'),
      subtitle: tr('teaming_manual_teams_description'),
    ),
    // OptionDescription(
    //   value: TeamingStyle.namedTeams,
    //   title: "Party mode",
    //   subtitle:
    //       "Set a number of teams. Players are not be specified. Feel free to join and leave in the middle of the game!",
    // ),
  ];
}

class TeamingStyleSelector extends EnumOptionSelector<TeamingStyle> {
  TeamingStyleSelector(TeamingStyle initialValue, Function changeCallback,
      {super.key})
      : super(
          windowTitle: "Teaming",
          allValues: getTeamingStyleOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => TeamingStyleSelectorState();
}

class TeamingStyleSelectorState
    extends EnumOptionSelectorState<TeamingStyle, TeamingStyleSelector> {}

// =============================================================================
// Main part

class TeamingConfigViewController {
  final numTeamsController = TextEditingController();
  bool _updatingFromConfig = false;
  bool get updatingFromConfig => _updatingFromConfig;

  TeamingConfigViewController();

  static void _updateText(TextEditingController controller, String text) {
    if (controller.text != text) {
      // TODO: Does this ever happen?
      controller.text = text;
    }
  }

  void updateFromConfig(TeamingConfig config) {
    _updatingFromConfig = true;
    _updateText(numTeamsController, config.numTeams.toString());
    _updatingFromConfig = false;
  }

  void dispose() {
    numTeamsController.dispose();
  }
}

class TeamingConfigView extends StatefulWidget {
  final bool onlineMode;
  final TeamingConfigViewController viewController;
  final TeamingConfig config;
  final GameConfigController configController;
  final int numPlayers;

  const TeamingConfigView(
      {super.key,
      required this.onlineMode,
      required this.viewController,
      required this.config,
      required this.configController,
      required this.numPlayers});

  @override
  State<StatefulWidget> createState() => TeamingConfigViewState();
}

class TeamingConfigViewState extends State<TeamingConfigView> {
  bool get onlineMode => widget.onlineMode;
  TeamingConfigViewController get viewController => widget.viewController;
  TeamingConfig get config => widget.config;
  GameConfigController get configController => widget.configController;
  int get numPlayers => widget.numPlayers;

  @override
  void initState() {
    super.initState();

    viewController.numTeamsController.addListener(() {
      final int? newValue =
          int.tryParse(viewController.numTeamsController.text);
      if (newValue != null && !viewController.updatingFromConfig) {
        configController.updateTeaming(
            (config) => config.rebuild((b) => b..numTeams = newValue));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const _numericFieldPadding = EdgeInsets.symmetric(vertical: 2.0);
    var items = <Widget>[];
    {
      final onTap = configController.isReadOnly
          ? null
          : () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => TeamingStyleSelector(
                        config.teamingStyle,
                        (TeamingStyle newValue) =>
                            configController.updateTeaming((config) => config
                                .rebuild((b) => b..teamingStyle = newValue)),
                      )));
            };
      final title = switch (config.teamingStyle) {
        TeamingStyle.individual => tr('teaming_individual'),
        TeamingStyle.oneToAll => tr('teaming_one_to_all'),
        TeamingStyle.randomPairs => tr('teaming_random_pairs'),
        TeamingStyle.randomTeams => tr('teaming_random_teams'),
        TeamingStyle.manualTeams => tr('teaming_manual_teams'),
        _ => Assert.unexpectedValue(config.teamingStyle),
      };
      items.add(
        OptionSelectorHeader(title: Text(title), onTap: onTap),
      );
    }
    if (config.teamingStyle == TeamingStyle.randomTeams) {
      items.add(
        ListTile(
          title: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Team number"),
                    Text(
                      _playersPerTeamText(numPlayers, config.numTeams),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: _numericFieldPadding,
                child: NumericField(
                  readOnly: configController.isReadOnly,
                  controller: viewController.numTeamsController,
                  minValue: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}

String _playersPerTeamText(int numPlayers, int numTeams) {
  const enDash = "–";
  final min = numPlayers ~/ numTeams;
  final max = (numPlayers + numTeams - 1) ~/ numTeams;
  if (min < 2) {
    return "Not enough players";
  }
  final value = (min == max) ? min.toString() : "${min}${enDash}${max}";
  return "${value} players per team";
}
