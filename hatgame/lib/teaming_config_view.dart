import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/local_str.dart';
import 'package:hatgame/widget/enum_option_selector.dart';
import 'package:hatgame/widget/numeric_field.dart';

// TODO: Add icons
List<OptionItem<TeamingStyle>> getTeamingStyleOptions(bool onlineMode) {
  return [
    OptionChoice(
      value: TeamingStyle.individual,
      title: LocalStr.tr('teaming_individual'),
      subtitle: LocalStr.tr('teaming_individual_description'),
    ),
    OptionChoice(
      value: TeamingStyle.oneToAll,
      title: LocalStr.tr('teaming_one_to_all'),
      subtitle: LocalStr.tr('teaming_one_to_all_description'),
    ),
    OptionChoice(
      value: TeamingStyle.randomPairs,
      title: LocalStr.tr('teaming_random_pairs'),
      subtitle: LocalStr.tr('teaming_random_pairs_description'),
    ),
    OptionChoice(
      value: TeamingStyle.randomTeams,
      title: LocalStr.tr('teaming_random_teams'),
      subtitle: LocalStr.tr('teaming_random_teams_description'),
    ),
    OptionChoice(
      value: TeamingStyle.manualTeams,
      title: LocalStr.tr('teaming_manual_teams'),
      subtitle: !onlineMode
          ? LocalStr.tr('teaming_manual_teams_description')
          : LocalStr.tr('teaming_manual_teams_disabled_description'),
      enabled: !onlineMode,
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
  TeamingStyleSelector(
      TeamingStyle initialValue, ValueChanged<TeamingStyle> changeCallback,
      {required bool onlineMode, super.key})
      : super(
          windowTitle: LocalStr.tr('teaming'),
          allValues: getTeamingStyleOptions(onlineMode),
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
    items.add(
      OptionSelectorHeader(
          title: Text(switch (config.teamingStyle) {
            TeamingStyle.individual => context.tr('teaming_individual'),
            TeamingStyle.oneToAll => context.tr('teaming_one_to_all'),
            TeamingStyle.randomPairs => context.tr('teaming_random_pairs'),
            TeamingStyle.randomTeams => context.tr('teaming_random_teams'),
            TeamingStyle.manualTeams => context.tr('teaming_manual_teams'),
            _ => Assert.unexpectedValue(config.teamingStyle),
          }),
          onTap: configController.isReadOnly
              ? null
              : () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (context) => TeamingStyleSelector(
                            config.teamingStyle,
                            (TeamingStyle newValue) => configController.update(
                                (config) => GameConfigController
                                        .fixPlayersForTeamingStyle(
                                            config.rebuild((b) {
                                      b..teaming.teamingStyle = newValue;
                                    }))),
                            onlineMode: onlineMode,
                          )));
                }),
    );
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
                    Text(context.tr('team_number')),
                    Text(
                      _playersPerTeamText(context, numPlayers, config.numTeams),
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

String _playersPerTeamText(BuildContext context, int numPlayers, int numTeams) {
  const enDash = "–";
  final min = numPlayers ~/ numTeams;
  final max = (numPlayers + numTeams - 1) ~/ numTeams;
  if (min < 2) {
    return context.tr('not_enough_players');
  }
  final value = (min == max) ? min.toString() : "${min}${enDash}${max}";
  return context.plural('players_per_team', max, args: [value]);
}
