import 'package:flutter/material.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/game_config.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/player_config_view.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/teaming_config_view.dart';
import 'package:hatgame/teaming_strategy.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/wide_button.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class ConfigView extends StatefulWidget {
  @override
  createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView>
    with SingleTickerProviderStateMixin {
  // TODO: Consider: change 'Start Game' button to:
  //   - advance to the next screen unless on the last screen alreay; OR
  //   - move to player tab if players empty or incorrect
  //     - this can be half-official, e.g. the button would be disabled and
  //       display a warning, but still change the tab.
  // (Are there best practices?)
  final tabs = <Tab>[
    Tab(
      text: 'Rules',
      icon: Icon(Icons.settings),
    ),
    Tab(
      text: 'Teaming',
      // TODO: Add arrows / several groups of people / gearwheel.
      icon: Icon(Icons.people),
    ),
    Tab(
      text: 'Players',
      // TODO: Replace squares with person icons.
      icon: Icon(OMIcons.ballot),
    ),
  ];
  static const int rulesTabIndex = 0;
  static const int teamingTabIndex = 1;
  static const int playersTabIndex = 2;

  final _rulesConfig = RulesConfig.dev();
  final _teamingConfig = TeamingConfig();
  var _playersConfig = IntermediatePlayersConfig.dev();

  TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() {
      // Hide virtual keyboard
      FocusScope.of(context).unfocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static PlayersConfig _makePlayersConfig(TeamingConfig teamingConfig,
      IntermediatePlayersConfig intermediateConfig) {
    final result = PlayersConfig();
    // Coversion between `players` and `teamPlayers` might be required if
    // teaming config changed and players haven't been modified since then.
    Assert.ne(intermediateConfig.teamPlayers == null,
        intermediateConfig.players == null);
    if (teamingConfig.teamPlay && !teamingConfig.randomizeTeams) {
      final List<List<String>> teamPlayers =
          intermediateConfig.teamPlayers ?? [intermediateConfig.players];
      result.names = teamPlayers.expand((t) => t).toList();
      result.teamingStrategy = FixedTeamsStrategy.manualTeams(
          teamPlayers.map((t) => t.length).toList(),
          teamingConfig.guessingInLargeTeam);
    } else {
      final List<String> players = List.from(intermediateConfig.players) ??
          intermediateConfig.teamPlayers.expand((t) => t).toList();
      if (teamingConfig.randomizeTeams) {
        players.shuffle();
      }
      result.names = players;
      if (teamingConfig.teamPlay) {
        result.teamingStrategy = FixedTeamsStrategy.generateTeams(
            players.length,
            teamingConfig.desiredTeamSize,
            teamingConfig.unequalTeamSize,
            teamingConfig.guessingInLargeTeam);
      } else {
        result.teamingStrategy = IndividualStrategy(
            players.length, teamingConfig.individualPlayStyle);
      }
    }
    return result;
  }

  void _startGame() {
    final settings = GameConfig();
    settings.rules = _rulesConfig;
    settings.teaming = _teamingConfig;
    try {
      settings.players = _makePlayersConfig(_teamingConfig, _playersConfig);
    } on CannotMakeTeaming catch (e) {
      showDialog(
        context: context,
        // TODO: Add context or replace with a SnackBar.
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(e.message),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      _tabController.animateTo(playersTabIndex);
      return;
    }

    // Hide virtual keyboard
    FocusScope.of(context).unfocus();
    // TODO: Remove "back" button.
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => GameView(settings)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: TabBar(
            controller: _tabController,
            tabs: tabs,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RulesConfigView(
                  config: _rulesConfig,
                  onUpdate: (updater) => setState(() => updater()),
                ),
                TeamingConfigView(
                  config: _teamingConfig,
                  onUpdate: (updater) => setState(() => updater()),
                ),
                PlayersConfigView(
                  teamingConfig: _teamingConfig,
                  initialPlayersConfig: _playersConfig,
                  onPlayersUpdated: (IntermediatePlayersConfig newConfig) =>
                      setState(() {
                    _playersConfig = newConfig;
                  }),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: WideButton(
              onPressed: _startGame,
              color: MyTheme.accent,
              child: Text(
                'Start Game',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
