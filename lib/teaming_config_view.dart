import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_data.dart';
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
      title: 'Explain in a circle',
      subtitle: 'The “hat” goes in a circle. '
          'Always explain to the next person in sequence.',
    ),
    OptionDescription(
      value: IndividualPlayStyle.fluidPairs,
      title: 'Each player explains to each',
      subtitle: 'Explainer-guesser pairs change constantly.',
    ),
    OptionDescription(
      value: IndividualPlayStyle.broadcast,
      title: 'Explain to everybody at once',
      subtitle: 'Non-competitive mode. '
          'One player explains, everybody else guesses.',
    ),
  ];
}

class IndividualPlayStyleSelector
    extends EnumOptionSelector<IndividualPlayStyle> {
  IndividualPlayStyleSelector(
      IndividualPlayStyle initialValue, Function changeCallback)
      : super(
          windowTitle: 'Turn Order',
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
      title: 'Random teams',
      subtitle: 'The app divides players into teams.',
    ),
    OptionDescription(
      value: false,
      title: 'Manual teams',
      subtitle: 'You divide players into teams yourself.',
    ),
  ];
}

class RandomizeTeamsSelector extends EnumOptionSelector<bool> {
  RandomizeTeamsSelector(bool initialValue, Function changeCallback)
      : super(
          windowTitle: 'Team Forming',
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
      title: 'Teams of 2',
      subtitle: '(if bigger teams are allowed, some teams may have 3 players)',
    ),
    OptionDescription(
      value: DesiredTeamSize.teamsOf3,
      title: 'Teams of 3',
      subtitle: '(if bigger teams are allowed, some teams may have 4 players)',
    ),
    OptionDescription(
      value: DesiredTeamSize.teamsOf4,
      title: 'Teams of 4',
      subtitle: '(if bigger teams are allowed, some teams may have 5 players)',
    ),
    OptionDescription(
      value: DesiredTeamSize.twoTeams,
      title: 'Two teams total',
    ),
  ];
}

class DesiredTeamSizeSelector extends EnumOptionSelector<DesiredTeamSize> {
  DesiredTeamSizeSelector(DesiredTeamSize initialValue, Function changeCallback)
      : super(
          windowTitle: 'Team Size',
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
      title: 'Allow bigger teams',
      subtitle: 'If players cannot be divided into equally sized teams, '
          'some teams will be bigger.',
    ),
    OptionDescription(
      value: UnequalTeamSize.forbid,
      title: 'Strict team sizes',
      subtitle: "Game won't start if players cannot be divided "
          'into teams of specified size.',
    ),
    OptionDescription(
      value: UnequalTeamSize.dropPlayers,
      title: 'Strict team sizes; drop players',
      // TODO: Make the lot fair (don't ban the same person twice in a row)
      // and comment on this.
      subtitle: "If it's not possible to divide players into "
          'into teams of specified size, some players will skip the round.',
    ),
  ];
}

class UnequalTeamSizeSelector extends EnumOptionSelector<UnequalTeamSize> {
  UnequalTeamSizeSelector(UnequalTeamSize initialValue, Function changeCallback)
      : super(
          windowTitle: 'Unequal Team Sizes',
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
  return [
    OptionDescription(
      value: IndividualPlayStyle.fluidPairs,
      title: 'One team member guesses',
      subtitle: 'Exactly one person guesses every turn. '
          'Teams of three or more rotate roles.',
    ),
    OptionDescription(
      value: IndividualPlayStyle.broadcast,
      title: 'The whole team guesses',
      subtitle: 'In teams of three or more '
          'the whole team guesses together.',
    ),
  ];
}

class GuessingInLargeTeamSelector
    extends EnumOptionSelector<IndividualPlayStyle> {
  GuessingInLargeTeamSelector(
      IndividualPlayStyle initialValue, Function changeCallback)
      : super(
          windowTitle: 'Guessing in Large Teams',
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

  TeamingConfigView(
      {@required this.onlineMode,
      @required this.config,
      @required this.configController});

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
          title: Text(config.teamPlay ? 'Team mode' : 'Individual mode'),
        ),
      );
    } else {
      items.add(
        MultiLineListTile(
          title: SwitchButton(
            options: ['Team mode', 'Individual mode'],
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
                title: Text('Explain in a circle'), onTap: onTap),
          );
          break;
        case IndividualPlayStyle.fluidPairs:
          items.add(
            OptionSelectorHeader(
                title: Text('Each player explains to each'), onTap: onTap),
          );
          break;
        case IndividualPlayStyle.broadcast:
          items.add(
            OptionSelectorHeader(
                title: Text('Explain to everybody at once'), onTap: onTap),
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
            title: Text('Random teams'),
            onTap: onTap,
          ));
          break;
        case false:
          items.add(OptionSelectorHeader(
            title: Text('Manual teams'),
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
            title: Text('Teams of 2'),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.teamsOf3:
          items.add(OptionSelectorHeader(
            title: Text('Teams of 3'),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.teamsOf4:
          items.add(OptionSelectorHeader(
            title: Text('Teams of 4'),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.twoTeams:
          items.add(OptionSelectorHeader(
            title: Text('Two teams total'),
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
          String subtitle;
          switch (config.desiredTeamSize) {
            case DesiredTeamSize.teamsOf2:
            case DesiredTeamSize.twoTeams:
              subtitle = '... if the number of players is odd';
              break;
            case DesiredTeamSize.teamsOf3:
              subtitle = '... if the number of players is not divisible by 3';
              break;
            case DesiredTeamSize.teamsOf4:
              subtitle = '... if the number of players is not divisible by 4';
              break;
          }
          items.add(OptionSelectorHeader(
            title: Text('Allow bigger teams'),
            subtitle: Text(subtitle),
            onTap: onTap,
          ));
          break;
        case UnequalTeamSize.forbid:
          String subtitle;
          switch (config.desiredTeamSize) {
            case DesiredTeamSize.teamsOf2:
            case DesiredTeamSize.twoTeams:
              subtitle = 'The number of players must be even';
              break;
            case DesiredTeamSize.teamsOf3:
              subtitle = 'The number of players must be divisible by 3';
              break;
            case DesiredTeamSize.teamsOf4:
              subtitle = 'The number of players must be divisible by 4';
              break;
          }
          items.add(OptionSelectorHeader(
            title: Text('Strict team sizes'),
            subtitle: Text(subtitle),
            onTap: onTap,
          ));
          break;
        case UnequalTeamSize.dropPlayers:
          String subtitle;
          switch (config.desiredTeamSize) {
            case DesiredTeamSize.teamsOf2:
            case DesiredTeamSize.twoTeams:
              subtitle = 'One player will skip the round '
                  'if the total number of players is odd';
              break;
            case DesiredTeamSize.teamsOf3:
              subtitle = 'Some players will skip the round '
                  'if the total number of players is not divisible by 3';
              break;
            case DesiredTeamSize.teamsOf4:
              subtitle = 'Some players will skip the round '
                  'if the total number of players is not divisible by 4';
              break;
          }
          items.add(OptionSelectorHeader(
            title: Text('Strict team sizes; drop players'),
            subtitle: Text(subtitle),
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
                title: Text('One player guesses each turn'),
                subtitle: maxPossbleTeamSize == 3
                    ? Text('Teams of three rotate roles')
                    : Text('Teams of three or more rotate roles'),
                onTap: onTap),
          );
          break;
        case IndividualPlayStyle.broadcast:
          items.add(
            OptionSelectorHeader(
                title: Text('The whole team guesses'),
                subtitle: maxPossbleTeamSize == 3
                    ? Text('Everybody can guess in teams of three')
                    : Text('Everybody can guess in teams of three or more'),
                onTap: onTap),
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
