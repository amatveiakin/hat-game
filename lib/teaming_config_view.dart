import 'package:flutter/material.dart';
import 'package:hatgame/enum_option_selector.dart';
import 'package:hatgame/multi_line_list_tile.dart';

// TODO: Add explanation images (ideally: animated) for the selection option
// on top of each subwindow, as in Android settings.

enum IndividualPlayStyle {
  chain,
  fluidPairs,
  // TODO: Add "each to all" (non-competitive) mode?
}

enum DesiredTeamSize {
  teamsOf2,
  teamsOf3,
  teamsOf4,
  twoTeams,
}

enum UnequalTeamSize {
  expandTeams,
  dropPlayers,
}

enum GuessingInLargeTeam {
  oneGuesser,
  everybodyGuesser,
}

// =============================================================================
// IndividualPlayStyle

getIndividualPlayStyleOptions() {
  return [
    OptionDescription(
      value: IndividualPlayStyle.chain,
      title: 'Chain sequence',
      subtitle: 'The “hat” goes in a circle. '
          'You always explain to the next person in sequence.',
    ),
    OptionDescription(
      value: IndividualPlayStyle.fluidPairs,
      title: 'Fluid pairs',
      subtitle: 'You explain to a new person every time '
          '(until you\'ve been paired up with every other player, '
          'at which point the loop starts anew).',
    ),
  ];
}

class IndividualPlayStyleSelector
    extends EnumOptionSelector<IndividualPlayStyle> {
  IndividualPlayStyleSelector(
      IndividualPlayStyle initialValue, Function changeCallback)
      : super(
          windowTitle: 'Individual Play Style',
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
// DesiredTeamSize

getDesiredTeamSizeOptions() {
  return [
    OptionDescription(
      value: DesiredTeamSize.teamsOf2,
      title: 'Teams of 2',
      subtitle: 'Each teams has 2 players. '
          'If unequal teams are allowed, teams will be bigger '
          'when the total number of players is odd.',
    ),
    OptionDescription(
      value: DesiredTeamSize.teamsOf3,
      title: 'Teams of 3',
      subtitle: 'Each teams has 3 players. '
          'If unequal teams are allowed, teams will be bigger '
          'when the total number of players is not divisible by 3.',
    ),
    OptionDescription(
      value: DesiredTeamSize.teamsOf4,
      title: 'Teams of 4',
      subtitle: 'Each teams has 4 players. '
          'If unequal teams are allowed, teams will be bigger '
          'when the total number of players is not divisible by 4.',
    ),
    OptionDescription(
      value: DesiredTeamSize.twoTeams,
      title: 'Two teams',
      subtitle: 'Divide all player into two teams.',
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
      title: 'Allow unequal teams',
      subtitle: 'If players cannot be divided into teams of equal sizes, '
          'some teams are going to be bigger.',
    ),
    OptionDescription(
      value: UnequalTeamSize.dropPlayers,
      title: 'Teams must be equal',
      // TODO: Make the lot fair (don't ban the same person twice in a row)
      // and comment on this.
      subtitle: 'Each team must have the same number of players. '
          'If this is not possible, '
          'a lot is drawn to determine the players who skip the round. ',
    ),
  ];
}

class UnequalTeamSizeSelector extends EnumOptionSelector<UnequalTeamSize> {
  UnequalTeamSizeSelector(UnequalTeamSize initialValue, Function changeCallback)
      : super(
          windowTitle: 'Unequal teams',
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
      value: GuessingInLargeTeam.oneGuesser,
      title: 'Always one guesser',
      subtitle: 'Exactly one person guesses every turn. '
          'Teams with more than two players rotate roles.',
    ),
    OptionDescription(
      value: GuessingInLargeTeam.everybodyGuesser,
      title: 'The whole team guesses',
      subtitle: 'In teams with more than two players '
          'each team member except the presenter can guess.',
    ),
  ];
}

class GuessingInLargeTeamSelector
    extends EnumOptionSelector<GuessingInLargeTeam> {
  GuessingInLargeTeamSelector(
      GuessingInLargeTeam initialValue, Function changeCallback)
      : super(
          windowTitle: 'Guessing in large teams',
          allValues: getGuessingInLargeTeamOptions(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => GuessingInLargeTeamSelectorState();
}

class GuessingInLargeTeamSelectorState extends EnumOptionSelectorState<
    GuessingInLargeTeam, GuessingInLargeTeamSelector> {}

// =============================================================================
// Main part

class TeamingConfigView extends StatefulWidget {
  @override
  createState() => _TeamingConfigViewState();
}

class _TeamingConfigViewState extends State<TeamingConfigView> {
  bool teamPlay = true;
  bool randomizeTeams = false;
  IndividualPlayStyle individualPlayStyle = IndividualPlayStyle.fluidPairs;
  DesiredTeamSize desiredTeamSize = DesiredTeamSize.teamsOf2;
  UnequalTeamSize unequalTeamSize = UnequalTeamSize.expandTeams;
  GuessingInLargeTeam guessingInLargeTeam = GuessingInLargeTeam.oneGuesser;

  // TODO: Irrelevant settings: hide or disable?
  @override
  Widget build(BuildContext context) {
    final bool largeTeamsPossible =
        desiredTeamSize != DesiredTeamSize.teamsOf2 ||
            unequalTeamSize == UnequalTeamSize.expandTeams ||
            !randomizeTeams;
    var items = <Widget>[];
    items.add(
      MultiLineSwitchListTile(
        title: Text(teamPlay ? 'Team play: on' : 'Team play: off'),
        subtitle: Text(teamPlay
            ? 'Fixed teams. Score is per team.'
            : 'Fluid pairing. Score is per player.'),
        value: teamPlay,
        onChanged: (bool checked) => setState(() {
          teamPlay = checked;
        }),
      ),
    );
    items.add(
      MultiLineSwitchListTile(
        title: Text(teamPlay
            ? (randomizeTeams ? 'Random teams: on' : 'Random teams: off')
            : (randomizeTeams
                ? 'Random turn order: on'
                : 'Random turn order: off')),
        subtitle: Text(randomizeTeams
            ? (teamPlay
                ? 'Generate random teams and turn order.'
                : 'Generate random turn order.')
            : (teamPlay
                ? 'Manually specify teams and turn order.'
                : 'Manually specify turn order.')),
        value: randomizeTeams,
        onChanged: (bool checked) => setState(() {
          randomizeTeams = checked;
        }),
      ),
    );
    if (!teamPlay) {
      final onTap = () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => IndividualPlayStyleSelector(
                individualPlayStyle,
                (IndividualPlayStyle newValue) => setState(() {
                      individualPlayStyle = newValue;
                    }))));
      };
      switch (individualPlayStyle) {
        case IndividualPlayStyle.chain:
          items.add(
            MultiLineListTile(
                title: Text('Chain sequence'),
                subtitle: Text('The “hat” goes in a circle. '
                    'You always explain to the next person in sequence.'),
                onTap: onTap),
          );
          break;
        case IndividualPlayStyle.fluidPairs:
          items.add(
            MultiLineListTile(
                title: Text('Fluid pairs'),
                subtitle: Text('You explain to a new person every time.'),
                onTap: onTap),
          );
          break;
      }
    }
    if (teamPlay && randomizeTeams) {
      final onTap = () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DesiredTeamSizeSelector(
                desiredTeamSize,
                (DesiredTeamSize newValue) => setState(() {
                      desiredTeamSize = newValue;
                    }))));
      };
      switch (desiredTeamSize) {
        case DesiredTeamSize.teamsOf2:
          items.add(MultiLineListTile(
            title: Text('Teams of 2'),
            subtitle: Text('Minimum team size is 2 players.'),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.teamsOf3:
          items.add(MultiLineListTile(
            title: Text('Teams of 3'),
            subtitle: Text('Minimum team size is 3 players.'),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.teamsOf4:
          items.add(MultiLineListTile(
            title: Text('Teams of 4'),
            subtitle: Text('Minimum team size is 4 players.'),
            onTap: onTap,
          ));
          break;
        case DesiredTeamSize.twoTeams:
          items.add(MultiLineListTile(
            title: Text('Two teams'),
            subtitle: Text('Divide all player into two teams.'),
            onTap: onTap,
          ));
          break;
      }
    }
    if (teamPlay && randomizeTeams) {
      final onTap = () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => UnequalTeamSizeSelector(
                unequalTeamSize,
                (UnequalTeamSize newValue) => setState(() {
                      unequalTeamSize = newValue;
                    }))));
      };
      switch (unequalTeamSize) {
        case UnequalTeamSize.expandTeams:
          String subtitle;
          switch (desiredTeamSize) {
            case DesiredTeamSize.teamsOf2:
            case DesiredTeamSize.twoTeams:
              subtitle = 'Teams will be unequal '
                  'if the total number of players is odd.';
              break;
            case DesiredTeamSize.teamsOf3:
              subtitle = 'Teams will be unequal '
                  'if the total number of players is not divisible by 3.';
              break;
            case DesiredTeamSize.teamsOf4:
              subtitle = 'Teams will be unequal '
                  'if the total number of players is not divisible by 4.';
              break;
          }
          items.add(MultiLineListTile(
            title: Text('Allow unequal teams'),
            subtitle: Text(subtitle),
            onTap: onTap,
          ));
          break;
        case UnequalTeamSize.dropPlayers:
          String subtitle;
          switch (desiredTeamSize) {
            case DesiredTeamSize.teamsOf2:
            case DesiredTeamSize.twoTeams:
              subtitle = 'One player will skip the round '
                  'if the total number of players is odd.';
              break;
            case DesiredTeamSize.teamsOf3:
              subtitle = 'Some players will skip the round '
                  'if the total number of players is not divisible by 3.';
              break;
            case DesiredTeamSize.teamsOf4:
              subtitle = 'Some players will skip the round '
                  'if the total number of players is not divisible by 4.';
              break;
          }
          items.add(MultiLineListTile(
            title: Text('Teams must be equal'),
            subtitle: Text(subtitle),
            onTap: onTap,
          ));
          break;
      }
    }
    if (teamPlay && largeTeamsPossible) {
      final onTap = () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => GuessingInLargeTeamSelector(
                guessingInLargeTeam,
                (GuessingInLargeTeam newValue) => setState(() {
                      guessingInLargeTeam = newValue;
                    }))));
      };
      switch (guessingInLargeTeam) {
        case GuessingInLargeTeam.oneGuesser:
          items.add(
            MultiLineListTile(
                title: Text('Always one guesser'),
                subtitle: Text('Exactly one person guesses every turn. '
                    'Teams with more than two players rotate roles.'),
                onTap: onTap),
          );
          break;
        case GuessingInLargeTeam.everybodyGuesser:
          items.add(
            MultiLineListTile(
                title: Text('The whole team guesses'),
                subtitle: Text(
                    'Everybody can guess in teams with more than two players.'),
                onTap: onTap),
          );
          break;
      }
    }
    return ListView(
      children: items,
    );
  }
}
