import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/enum_option_selector.dart';
import 'package:hatgame/widget/multi_line_list_tile.dart';
import 'package:hatgame/widget/switch_button.dart';

// TODO: Add explanation images (ideally: animated) for the selection option
// on top of each subwindow, as in Android settings.

// =============================================================================
// IndividualPlayStyle

getIndividualPlayStyleOptions() {
  return [
    OptionDescription(
      value: IndividualPlayStyle.chain,
      title: tr('explain_in_a_circle'),
      subtitle: tr('explain_in_a_circle_comment'),
    ),
    OptionDescription(
      value: IndividualPlayStyle.fluidPairs,
      title: tr('each_explains_to_each'),
      subtitle: tr('each_explains_to_each_comment'),
    ),
    OptionDescription(
      value: IndividualPlayStyle.broadcast,
      title: tr('explain_to_everybody'),
      subtitle: tr('explain_to_everybody_comment'),
    ),
  ];
}

class IndividualPlayStyleSelector
    extends EnumOptionSelector<IndividualPlayStyle> {
  IndividualPlayStyleSelector(
      IndividualPlayStyle initialValue, Function changeCallback,
      {super.key})
      : super(
          windowTitle: tr('turn_order'),
          allValues: getIndividualPlayStyleOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => IndividualPlayStyleSelectorState();
}

class IndividualPlayStyleSelectorState extends EnumOptionSelectorState<
    IndividualPlayStyle, IndividualPlayStyleSelector> {}

// =============================================================================
// Random teams

getRandomizeTeamsOptions() {
  return [
    OptionDescription(
      value: true,
      title: tr('random_teams'),
      subtitle: tr('random_teams_comment'),
    ),
    OptionDescription(
      value: false,
      title: tr('manual_teams'),
      subtitle: tr('manual_teams_comment'),
    ),
  ];
}

class RandomizeTeamsSelector extends EnumOptionSelector<bool> {
  RandomizeTeamsSelector(bool initialValue, Function changeCallback, {super.key})
      : super(
          windowTitle: tr('team_forming'),
          allValues: getRandomizeTeamsOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => RandomizeTeamsSelectorState();
}

class RandomizeTeamsSelectorState
    extends EnumOptionSelectorState<bool, RandomizeTeamsSelector> {}

// =============================================================================
// DesiredTeamSize

getDesiredTeamSizeOptions() {
  return [
    OptionDescription(
      value: DesiredTeamSize.teamsOf2,
      title: tr('teams_of_2'),
      subtitle: tr('teams_of_2_comment'),
    ),
    OptionDescription(
      value: DesiredTeamSize.teamsOf3,
      title: tr('teams_of_3'),
      subtitle: tr('teams_of_3_comment'),
    ),
    OptionDescription(
      value: DesiredTeamSize.teamsOf4,
      title: tr('teams_of_4'),
      subtitle: tr('teams_of_4_comment'),
    ),
    OptionDescription(
      value: DesiredTeamSize.twoTeams,
      title: tr('two_teams_total'),
    ),
  ];
}

class DesiredTeamSizeSelector extends EnumOptionSelector<DesiredTeamSize> {
  DesiredTeamSizeSelector(DesiredTeamSize initialValue, Function changeCallback,
      {super.key})
      : super(
          windowTitle: tr('team_size'),
          allValues: getDesiredTeamSizeOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => DesiredTeamSizeSelectorState();
}

class DesiredTeamSizeSelectorState
    extends EnumOptionSelectorState<DesiredTeamSize, DesiredTeamSizeSelector> {}

// =============================================================================
// UnequalTeamSize

getUnequalTeamSizeOptions() {
  return [
    OptionDescription(
      value: UnequalTeamSize.expandTeams,
      title: tr('allow_bigger_teams'),
      subtitle: tr('allow_bigger_teams_comment'),
    ),
    OptionDescription(
      value: UnequalTeamSize.forbid,
      title: tr('strict_team_sizes'),
      subtitle: tr('strict_team_sizes_comment'),
    ),
    OptionDescription(
      value: UnequalTeamSize.dropPlayers,
      title: tr('drop_players'),
      // TODO: Make the lot fair (don't ban the same person twice in a row)
      // and comment on this.
      subtitle: tr('drop_players_comment'),
    ),
  ];
}

class UnequalTeamSizeSelector extends EnumOptionSelector<UnequalTeamSize> {
  UnequalTeamSizeSelector(UnequalTeamSize initialValue, Function changeCallback,
      {super.key})
      : super(
          windowTitle: tr('unequal_team_sizes'),
          allValues: getUnequalTeamSizeOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => UnequalTeamSizeSelectorState();
}

class UnequalTeamSizeSelectorState
    extends EnumOptionSelectorState<UnequalTeamSize, UnequalTeamSizeSelector> {}

// =============================================================================
// GuessingInLargeTeam

getGuessingInLargeTeamOptions() {
  // TODO: Are subtitles required here?
  return [
    OptionDescription(
      value: IndividualPlayStyle.fluidPairs,
      title: tr('one_team_member_guesses'),
      subtitle: tr('one_team_member_guesses_comment'),
    ),
    OptionDescription(
      value: IndividualPlayStyle.broadcast,
      title: tr('the_whole_team_guesses'),
      subtitle: tr('the_whole_team_guesses_comment'),
    ),
  ];
}

class GuessingInLargeTeamSelector
    extends EnumOptionSelector<IndividualPlayStyle> {
  GuessingInLargeTeamSelector(
      IndividualPlayStyle initialValue, Function changeCallback,
      {super.key})
      : super(
          windowTitle: tr('guessing_in_large_teams'),
          allValues: getGuessingInLargeTeamOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => GuessingInLargeTeamSelectorState();
}

class GuessingInLargeTeamSelectorState extends EnumOptionSelectorState<
    IndividualPlayStyle, GuessingInLargeTeamSelector> {}

// =============================================================================
// Main part

class TeamingConfigView extends StatelessWidget {
  final bool onlineMode;
  final TeamingConfig config;
  final GameConfigController configController;

  const TeamingConfigView(
      {super.key,
      required this.onlineMode,
      required this.config,
      required this.configController});

  static int _maxPossbleTeamSize(TeamingConfig config) {
    const int infinity = 1000;
    if (!config.randomizeTeams) {
      return infinity;
    }
    int baseTeamSize = 0;
    switch (config.desiredTeamSize) {
      case DesiredTeamSize.teamsOf2:
        baseTeamSize = 2;
        break;
      case DesiredTeamSize.teamsOf3:
        baseTeamSize = 3;
        break;
      case DesiredTeamSize.teamsOf4:
        baseTeamSize = 4;
        break;
      case DesiredTeamSize.twoTeams:
        return infinity;
    }
    return config.unequalTeamSize == UnequalTeamSize.expandTeams
        ? baseTeamSize + 1
        : baseTeamSize;
  }

  // TODO: Irrelevant settings: hide or disable?
  @override
  Widget build(BuildContext context) {
    final int maxPossbleTeamSize = _maxPossbleTeamSize(config);
    var items = <Widget>[];
    if (configController.isReadOnly) {
      items.add(
        MultiLineListTile(
          title:
              Text(config.teamPlay ? tr('team_mode') : tr('individual_mode')),
        ),
      );
    } else {
      items.add(
        MultiLineListTile(
          title: SwitchButton(
            options: [tr('team_mode'), tr('individual_mode')],
            selectedOption: config.teamPlay ? 0 : 1,
            onSelectedOptionChanged: configController.isReadOnly
                ? null
                : (int newOption) =>
                    configController.updateTeaming((config) => config.rebuild(
                          (b) => b..teamPlay = (newOption == 0),
                        )),
          ),
        ),
      );
    }
    if (!config.teamPlay) {
      final onTap = configController.isReadOnly
          ? null
          : () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => IndividualPlayStyleSelector(
                        config.individualPlayStyle,
                        (IndividualPlayStyle newValue) => configController
                            .updateTeaming((config) => config.rebuild(
                                (b) => b..individualPlayStyle = newValue)),
                      )));
            };
      switch (config.individualPlayStyle) {
        case IndividualPlayStyle.chain:
          items.add(
            OptionSelectorHeader(
                title: Text(tr('explain_in_a_circle')), onTap: onTap),
          );
          break;
        case IndividualPlayStyle.fluidPairs:
          items.add(
            OptionSelectorHeader(
                title: Text(tr('each_explains_to_each')), onTap: onTap),
          );
          break;
        case IndividualPlayStyle.broadcast:
          items.add(
            OptionSelectorHeader(
                title: Text(tr('explain_to_everybody')), onTap: onTap),
          );
          break;
      }
    }
    if (config.teamPlay && !onlineMode) {
      final onTap = configController.isReadOnly
          ? null
          : () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => RandomizeTeamsSelector(
                        config.randomizeTeams,
                        (bool newValue) => configController.updateTeaming(
                            (config) => config
                                .rebuild((b) => b..randomizeTeams = newValue)),
                      )));
            };
      switch (config.randomizeTeams) {
        case true:
          items.add(OptionSelectorHeader(
            title: Text(tr('random_teams')),
            onTap: onTap,
          ));
          break;
        case false:
          items.add(OptionSelectorHeader(
            title: Text(tr('manual_teams')),
            onTap: onTap,
          ));
          break;
      }
    }
    if (config.teamPlay && config.randomizeTeams) {
      final onTap = configController.isReadOnly
          ? null
          : () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DesiredTeamSizeSelector(
                        config.desiredTeamSize,
                        (DesiredTeamSize newValue) =>
                            configController.updateTeaming((config) => config
                                .rebuild((b) => b..desiredTeamSize = newValue)),
                      )));
            };
      switch (config.desiredTeamSize) {
        case DesiredTeamSize.teamsOf2:
          items.add(OptionSelectorHeader(
            title: Text(tr('teams_of_2')),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.teamsOf3:
          items.add(OptionSelectorHeader(
            title: Text(tr('teams_of_3')),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.teamsOf4:
          items.add(OptionSelectorHeader(
            title: Text(tr('teams_of_4')),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.twoTeams:
          items.add(OptionSelectorHeader(
            title: Text(tr('two_teams_total')),
            onTap: onTap,
          ));
          break;
      }
    }
    if (config.teamPlay && config.randomizeTeams) {
      final onTap = configController.isReadOnly
          ? null
          : () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UnequalTeamSizeSelector(
                        config.unequalTeamSize,
                        (UnequalTeamSize newValue) =>
                            configController.updateTeaming((config) => config
                                .rebuild((b) => b..unequalTeamSize = newValue)),
                      )));
            };
      switch (config.unequalTeamSize) {
        case UnequalTeamSize.expandTeams:
          items.add(OptionSelectorHeader(
            title: Text(tr('allow_bigger_teams')),
            onTap: onTap,
          ));
          break;
        case UnequalTeamSize.forbid:
          items.add(OptionSelectorHeader(
            title: Text(tr('strict_team_sizes')),
            onTap: onTap,
          ));
          break;
        case UnequalTeamSize.dropPlayers:
          items.add(OptionSelectorHeader(
            title: Text(tr('drop_players')),
            onTap: onTap,
          ));
          break;
      }
    }
    if (config.teamPlay && maxPossbleTeamSize > 2) {
      final onTap = configController.isReadOnly
          ? null
          : () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => GuessingInLargeTeamSelector(
                        config.guessingInLargeTeam,
                        (IndividualPlayStyle newValue) => configController
                            .updateTeaming((config) => config.rebuild(
                                (b) => b..guessingInLargeTeam = newValue)),
                      )));
            };
      switch (config.guessingInLargeTeam) {
        case IndividualPlayStyle.fluidPairs:
          items.add(
            OptionSelectorHeader(
              title: Text(tr('one_team_member_guesses')),
              onTap: onTap,
            ),
          );
          break;
        case IndividualPlayStyle.broadcast:
          items.add(
            OptionSelectorHeader(
              title: Text(tr('the_whole_team_guesses')),
              onTap: onTap,
            ),
          );
          break;
        case IndividualPlayStyle.chain:
          Assert.fail(
              'IndividualPlayStyle.chain is not supported in teams mode');
      }
    }
    return ListView(
      children: items,
    );
  }
}
