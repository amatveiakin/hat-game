import 'package:flutter/material.dart';
import 'package:hatgame/enum_option_selector.dart';
import 'package:hatgame/multi_line_list_tile.dart';

// TODO: Add explanation images (ideally: animated) for the selection option
// on top of each subwindow, as in Android settings.

// TODO: Rename enums and enum values to better match UI names.
// (This data is not entirely private, as it will probably leak to JSON.)
enum SinglePlayStyle {
  circle,
  clique,
  // TODO: Add "each to all" (non-competitive) mode?
}

enum TeamSize {
  teamsOf2,
  teamsOf3,
  teamsOf4,
  twoTeams,
}

enum ExcessivePlayers {
  expandTeams,
  drop,
}

enum LargeTeamPlayStyle {
  duplex,
  broadcast,
}

// =============================================================================
// SinglePlayStyle

getAllSinglePlayStyles() {
  return [
    OptionDescription(
      value: SinglePlayStyle.circle,
      title: 'Chain sequence',
      subtitle: 'The “hat” goes in a circle. '
          'Each player explains to the next person.',
    ),
    OptionDescription(
      value: SinglePlayStyle.clique,
      title: 'Each to each',
      subtitle: 'Everybody will eventually explain to everybody.',
    ),
  ];
}

class SinglePlayStyleSelector extends EnumOptionSelector<SinglePlayStyle> {
  SinglePlayStyleSelector(SinglePlayStyle initialValue, Function changeCallback)
      : super(
          windowTitle: 'Play Style',
          allValues: getAllSinglePlayStyles(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => SinglePlayStyleSelectorState();
}

class SinglePlayStyleSelectorState
    extends EnumOptionSelectorState<SinglePlayStyle, SinglePlayStyleSelector> {}

// =============================================================================
// TeamSize

getTeamSize() {
  return [
    OptionDescription(
      value: TeamSize.teamsOf2,
      title: 'Teams of 2',
      subtitle: 'Each teams has 2 players. '
          'If unequal teams are allowed, teams will be bigger '
          'when the total number of players is odd.',
    ),
    OptionDescription(
      value: TeamSize.teamsOf3,
      title: 'Teams of 3',
      subtitle: 'Each teams has 3 players. '
          'If unequal teams are allowed, teams will be bigger '
          'when the total number of players is not divisible by 3.',
    ),
    OptionDescription(
      value: TeamSize.teamsOf4,
      title: 'Teams of 4',
      subtitle: 'Each teams has 4 players. '
          'If unequal teams are allowed, teams will be bigger '
          'when the total number of players is not divisible by 4.',
    ),
    OptionDescription(
      value: TeamSize.twoTeams,
      title: 'Two teams',
      subtitle: 'Divide all player into two teams.',
    ),
  ];
}

class TeamSizeSelector extends EnumOptionSelector<TeamSize> {
  TeamSizeSelector(TeamSize initialValue, Function changeCallback)
      : super(
          windowTitle: 'Team Size',
          allValues: getTeamSize(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => TeamSizeSelectorState();
}

class TeamSizeSelectorState
    extends EnumOptionSelectorState<TeamSize, TeamSizeSelector> {}

// =============================================================================
// ExcessivePlayers

getAllExcessivePlayerss() {
  return [
    OptionDescription(
      value: ExcessivePlayers.expandTeams,
      title: 'Allow unequal teams',
      subtitle: 'If players cannot be divided into teams of equal sizes, '
          'some teams are going to be bigger.',
    ),
    OptionDescription(
      value: ExcessivePlayers.drop,
      title: 'Teams must be equal',
      // TODO: Make the lot fair (don't ban the same person twice in a row)
      // and comment on this.
      subtitle: 'Each team must have the same number of players. '
          'If this is not possible, '
          'a lot is drawn to determine the players who skip the round. ',
    ),
  ];
}

class ExcessivePlayersSelector extends EnumOptionSelector<ExcessivePlayers> {
  ExcessivePlayersSelector(
      ExcessivePlayers initialValue, Function changeCallback)
      : super(
          windowTitle: 'Unequal teams',
          allValues: getAllExcessivePlayerss(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => ExcessivePlayersSelectorState();
}

class ExcessivePlayersSelectorState extends EnumOptionSelectorState<
    ExcessivePlayers, ExcessivePlayersSelector> {}

// =============================================================================
// LargeTeamPlayStyle

getAllLargeTeamPlayStyles() {
  return [
    OptionDescription(
      value: LargeTeamPlayStyle.duplex,
      title: 'Always one guesser',
      subtitle: 'Exactly one person guesses every turn. '
          'Teams with more than two players rotate roles.',
    ),
    OptionDescription(
      value: LargeTeamPlayStyle.broadcast,
      title: 'The whole team guesses',
      subtitle: 'In teams with more than two players '
          'each team member except the presenter can guess.',
    ),
  ];
}

class LargeTeamPlayStyleSelector
    extends EnumOptionSelector<LargeTeamPlayStyle> {
  LargeTeamPlayStyleSelector(
      LargeTeamPlayStyle initialValue, Function changeCallback)
      : super(
          windowTitle: 'Guessing in large teams',
          allValues: getAllLargeTeamPlayStyles(),
          initialValue: initialValue,
          changeCallback: changeCallback,
        );

  @override
  createState() => LargeTeamPlayStyleSelectorState();
}

class LargeTeamPlayStyleSelectorState extends EnumOptionSelectorState<
    LargeTeamPlayStyle, LargeTeamPlayStyleSelector> {}

// =============================================================================
// Main part

class TeamingConfigView extends StatefulWidget {
  @override
  createState() => _TeamingConfigViewState();
}

class _TeamingConfigViewState extends State<TeamingConfigView> {
  bool teamPlay = true;
  bool randomizeTeams = false;
  SinglePlayStyle singlePlayStyle = SinglePlayStyle.clique;
  TeamSize teamSize = TeamSize.teamsOf2;
  ExcessivePlayers excessivePlayers = ExcessivePlayers.expandTeams;
  LargeTeamPlayStyle largeTeamPlayStyle = LargeTeamPlayStyle.duplex;

  // TODO: Irrelevant settings: hide or disable?
  @override
  Widget build(BuildContext context) {
    final bool largeTeamsPossible = teamSize != TeamSize.teamsOf2 ||
        excessivePlayers == ExcessivePlayers.expandTeams ||
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
            builder: (context) => SinglePlayStyleSelector(
                singlePlayStyle,
                (SinglePlayStyle newValue) => setState(() {
                      singlePlayStyle = newValue;
                    }))));
      };
      switch (singlePlayStyle) {
        case SinglePlayStyle.circle:
          items.add(
            MultiLineListTile(
                title: Text('Chain sequence'),
                subtitle: Text('The “hat” goes in a circle. '
                    'Each player explains to the next person.'),
                onTap: onTap),
          );
          break;
        case SinglePlayStyle.clique:
          items.add(
            MultiLineListTile(
                title: Text('Each to each'),
                subtitle:
                    Text('Everybody will eventually explain to everybody.'),
                onTap: onTap),
          );
          break;
      }
    }
    if (teamPlay && randomizeTeams) {
      final onTap = () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => TeamSizeSelector(
                teamSize,
                (TeamSize newValue) => setState(() {
                      teamSize = newValue;
                    }))));
      };
      switch (teamSize) {
        case TeamSize.teamsOf2:
          items.add(MultiLineListTile(
            title: Text('Teams of 2'),
            subtitle: Text('Minimum team size is 2 players.'),
            onTap: onTap,
          ));
          break;
        case TeamSize.teamsOf3:
          items.add(MultiLineListTile(
            title: Text('Teams of 3'),
            subtitle: Text('Minimum team size is 3 players.'),
            onTap: onTap,
          ));
          break;
        case TeamSize.teamsOf4:
          items.add(MultiLineListTile(
            title: Text('Teams of 4'),
            subtitle: Text('Minimum team size is 4 players.'),
            onTap: onTap,
          ));
          break;
        case TeamSize.twoTeams:
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
            builder: (context) => ExcessivePlayersSelector(
                excessivePlayers,
                (ExcessivePlayers newValue) => setState(() {
                      excessivePlayers = newValue;
                    }))));
      };
      switch (excessivePlayers) {
        case ExcessivePlayers.expandTeams:
          String subtitle;
          switch (teamSize) {
            case TeamSize.teamsOf2:
            case TeamSize.twoTeams:
              subtitle = 'Teams will be unequal '
                  'if the total number of players is odd.';
              break;
            case TeamSize.teamsOf3:
              subtitle = 'Teams will be unequal '
                  'if the total number of players is not divisible by 3.';
              break;
            case TeamSize.teamsOf4:
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
        case ExcessivePlayers.drop:
          String subtitle;
          switch (teamSize) {
            case TeamSize.teamsOf2:
            case TeamSize.twoTeams:
              subtitle = 'One player will skip the round '
                  'if the total number of players is odd.';
              break;
            case TeamSize.teamsOf3:
              subtitle = 'Some players will skip the round '
                  'if the total number of players is not divisible by 3.';
              break;
            case TeamSize.teamsOf4:
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
            builder: (context) => LargeTeamPlayStyleSelector(
                largeTeamPlayStyle,
                (LargeTeamPlayStyle newValue) => setState(() {
                      largeTeamPlayStyle = newValue;
                    }))));
      };
      switch (largeTeamPlayStyle) {
        case LargeTeamPlayStyle.duplex:
          items.add(
            MultiLineListTile(
                title: Text('Always one guesser'),
                subtitle: Text('Exactly one person guesses every turn. '
                    'Teams with more than two players rotate roles.'),
                onTap: onTap),
          );
          break;
        case LargeTeamPlayStyle.broadcast:
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
