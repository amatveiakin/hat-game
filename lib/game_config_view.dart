import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/offline_player_config_view.dart';
import 'package:hatgame/online_player_config_view.dart';
import 'package:hatgame/partying_strategy.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/teaming_config_view.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/wide_button.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class GameConfigView extends StatefulWidget {
  final LocalGameData localGameData;

  GameConfigView({@required this.localGameData});

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

  LocalGameData get localGameData => widget.localGameData;
  bool get isAdmin => localGameData.isAdmin;
  bool _navigatedToGame = false;

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
    try {
      GameController.startGame(localGameData.gameReference, gameConfig);
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
      _tabController.animateTo(playersTabIndex);
      return;
    }
  }

  void _goToGame() {
    // Hide virtual keyboard
    FocusScope.of(context).unfocus();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => GameView(
                  localGameData: localGameData,
                )),
        ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: localGameData.onlineMode
          ? AppBar(
              automaticallyImplyLeading: false,
              title: localGameData.onlineMode
                  ? Text('Game ID: ${localGameData.gameID}')
                  : null,
              // For some reason PreferredSize affects not only the botton of
              // the AppBar but also the title, making it misaligned with the
              // normal title text position. Hopefully this is not too visible.
              // Without PreferredSize the AppBar is just too fat.
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(64.0),
                child: TabBar(
                  controller: _tabController,
                  tabs: tabs,
                ),
              ),
            )
          : PreferredSize(
              preferredSize: Size.fromHeight(64.0),
              child: AppBar(
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: TabBar(
                    controller: _tabController,
                    tabs: tabs,
                  ),
                ),
              ),
            ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: localGameData.gameReference.snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
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
          final configController =
              GameConfigController(localGameData.gameReference);
          final GameConfigReadResult gameConfigReadResult =
              GameConfigController.configFromSnapshot(snapshot.data);
          final GameConfig gameConfig = gameConfigReadResult.config;
          Assert.holds(gameConfig != null);
          if (gameConfigReadResult.gameHasStarted) {
            // Cannot navigate from within `build`.
            if (!_navigatedToGame) {
              Future.delayed(Duration.zero, () => _goToGame());
              _navigatedToGame = true;
            }
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
                      configController: configController,
                    ),
                    TeamingConfigView(
                      onlineMode: localGameData.onlineMode,
                      config: gameConfig.teaming,
                      configController: configController,
                    ),
                    localGameData.onlineMode
                        ? OnlinePlayersConfigView(
                            playersConfig: gameConfig.players,
                          )
                        : OfflinePlayersConfigView(
                            teamingConfig: gameConfig.teaming,
                            initialPlayersConfig: gameConfig.players,
                            configController: configController,
                          ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: WideButton(
                  onPressed: isAdmin ? () => _startGame(gameConfig) : null,
                  onPressedDisabled: () {
                    final snackBar = SnackBar(
                        content: Text('Only the host can start the game.'));
                    Scaffold.of(context).showSnackBar(snackBar);
                  },
                  color: MyTheme.accent,
                  child: Text('Start Game'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
