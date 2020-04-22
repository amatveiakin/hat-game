import 'package:flutter/material.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/game_config.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/player_config_view.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/teaming_config_view.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class ConfigView extends StatefulWidget {
  @override
  createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView>
    with SingleTickerProviderStateMixin {
  // TODO: Change tab order: Options, Teaming, Players (?)
  // TODO: Consider: make FAB advance to the next screen unless on the
  // last screen alreay. (Are there best practices?)
  final tabs = <Tab>[
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
    Tab(
      text: 'Options',
      icon: Icon(Icons.settings),
    ),
  ];
  static const int teamingTabIndex = 0;
  static const int playersTabIndex = 1;
  static const int optionsTabIndex = 2;

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

  void _startGame() {
    final settings = GameConfig();
    settings.rules = _rulesConfig;
    settings.teaming = _teamingConfig;
    final PlayersConfig playersConfig = settings.players;

    if (_playersConfig.players != null) {
      final players = _playersConfig.players;
      // TODO: Use TeamingStrategy to check teaming validity.
      if (players.length < 2 || players.length % 2 == 1) {
        showDialog(
          context: context,
          // TODO: Add context or replace with a SnackBar.
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Invalid number of players: ${players.length}'),
              actions: <Widget>[
                FlatButton(
                  child: Text('I see'),
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
      int playerIdx = 0;
      playersConfig.teamPlayers = [];
      for (final player in players) {
        if (playerIdx % 2 == 0) {
          playersConfig.teamPlayers.add([]);
        }
        playersConfig.teamPlayers.last.add(player);
        playerIdx++;
      }
    } else {
      Assert.holds(_playersConfig.teamPlayers != null);
      playersConfig.teamPlayers = _playersConfig.teamPlayers;
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
      body: TabBarView(
        controller: _tabController,
        children: [
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
          RulesConfigView(
            config: _rulesConfig,
            onUpdate: (updater) => setState(() => updater()),
          ),
        ],
      ),
      // TODO: Convert to normal button, similarly to 'Next round'.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startGame,
        label: Text('Start Game'),
        icon: Icon(Icons.arrow_forward),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
