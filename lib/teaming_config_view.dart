import 'package:flutter/material.dart';
import 'package:hatgame/enum_option_selector.dart';

// TODO: Add explanation images (ideally: animated) for the selection option
// on top of each subwindow, as in Android settings.

enum SinglePlayStyle {
  circle,
  clique,
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

getAllSinglePlayStyles() {
  return [
    OptionDescription(
      value: SinglePlayStyle.circle,
      title: 'Circle',
      // TODO: Detailed description (mention star seating).
      subtitle: 'The hat goes in a circle. '
          'Each player explains to the next person.',
    ),
    OptionDescription(
      value: SinglePlayStyle.clique,
      title: 'Clique',
      // TODO: Detailed description.
      subtitle: 'Everybody explains to everybody.',
    ),
  ];
}

class SinglePlayStyleSelector extends EnumOptionSelector<SinglePlayStyle> {
  SinglePlayStyleSelector(
      SinglePlayStyle initialPlayStyle, Function changeCallback)
      : super(
          windowTitle: 'Select Play Style',
          allValues: getAllSinglePlayStyles(),
          initialValue: initialPlayStyle,
          changeCallback: changeCallback,
        );

  @override
  createState() => SinglePlayStyleSelectorState();
}

class SinglePlayStyleSelectorState
    extends EnumOptionSelectorState<SinglePlayStyle, SinglePlayStyleSelector> {}

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
    return ListView(
      children: [
        SwitchListTile(
          title: Text('Team play'),
          // TODO: Subtitle.
          value: teamPlay,
          onChanged: (bool checked) => setState(() {
            teamPlay = checked;
          }),
        ),
        SwitchListTile(
          title: Text(teamPlay ? 'Random teams' : 'Random turn order'),
          // TODO: Subtitle.
          value: randomizeTeams,
          onChanged: (bool checked) => setState(() {
            randomizeTeams = checked;
          }),
        ),
        if (!teamPlay)
          ListTile(
            title: Text(singlePlayStyle == SinglePlayStyle.circle
                ? 'Play style: Circle'
                : 'Play style: Clique'),
            subtitle: Text(singlePlayStyle == SinglePlayStyle.circle
                ? 'Each player explains to the next person'
                : 'Everybody explains to everybody'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SinglePlayStyleSelector(
                          singlePlayStyle,
                          (SinglePlayStyle newValue) => setState(() {
                                singlePlayStyle = newValue;
                              }))));
            },
          ),
        if (teamPlay && randomizeTeams)
          // TODO: ...
          ListTile(
            title: Text('Teams of 2'),
            subtitle: Text('Several teams of 2 people'),
            onTap: () {
              // TODO:
            },
          ),
        if (teamPlay && randomizeTeams)
          ListTile(
            title: Text(excessivePlayers == ExcessivePlayers.expandTeams
                ? 'Uneven teams: Allow'
                : 'Uneven teams: Forbid'),
            subtitle: Text(excessivePlayers == ExcessivePlayers.expandTeams
                // TODO: 'even' / 'divisible by 3' / ...
                ? 'Allow the number of players {TODO}'
                : ''),
            onTap: () {
              // TODO:
            },
          ),
        if (teamPlay && largeTeamsPossible)
          ListTile(
            title: Text(largeTeamPlayStyle == LargeTeamPlayStyle.duplex
                ? 'Large teams style: One to one'
                : 'Large teams style: One to all'),
            subtitle: Text(largeTeamPlayStyle == LargeTeamPlayStyle.duplex
                ? 'Exactly one person listens every turn. '
                    'Teams of more than two people have internal rotation.'
                : 'Everybody can guess in teams of more than two people'),
            onTap: () {
              // TODO:
            },
          ),
      ],
    );
  }
}
