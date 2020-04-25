import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/player_config_view.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/teaming_config_view.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/wide_button.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class GameConfigView extends StatefulWidget {
  @override
  createState() => _GameConfigViewState();
}

class _GameConfigViewState extends State<GameConfigView>
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

  var _configController = GameConfigController.devConfig();

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

  void _startGame(GameConfig gameConfig) {
    GameController gameController;
    try {
      gameController = GameController.newState(gameConfig);
    } on CannotMakePartyingStrategy catch (e) {
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
        context,
        MaterialPageRoute(
            builder: (context) => GameView(
                  gameConfig: gameConfig,
                  gameController: gameController,
                )));
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
      body: StreamBuilder<GameConfig>(
        stream: _configController.stateUpdatesStream,
        builder: (BuildContext context, AsyncSnapshot<GameConfig> snapshot) {
          // TODO: Deal with errors and loading.
          if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error getting game config:\n' + snapshot.error.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final GameConfig gameConfig = snapshot.data;
          if (gameConfig == null) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RulesConfigView(
                      config: gameConfig.rules,
                      configController: _configController,
                    ),
                    TeamingConfigView(
                      config: gameConfig.teaming,
                      configController: _configController,
                    ),
                    PlayersConfigView(
                      teamingConfig: gameConfig.teaming,
                      initialPlayersConfig: gameConfig.players,
                      configController: _configController,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: WideButton(
                  onPressed: () => _startGame(gameConfig),
                  color: MyTheme.accent,
                  child: Text(
                    'Start Game',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
