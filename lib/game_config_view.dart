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
  List<Tab> _buildTabs(int numPlayers) {
    return [
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
        text: 'Players: $numPlayers',
        // TODO: Replace squares with person icons.
        icon: Icon(OMIcons.ballot),
      ),
    ];
  }

  static const int rulesTabIndex = 0;
  static const int teamingTabIndex = 1;
  static const int playersTabIndex = 2;
  static const int numTabs = 3;

  LocalGameData get localGameData => widget.localGameData;
  bool get isAdmin => localGameData.isAdmin;
  bool _navigatedToGame = false;

  TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: numTabs);
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
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => GameView(
            localGameData: localGameData,
          ),
          settings: RouteSettings(name: 'Game'),
        ),
        ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
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

        final tabs = _buildTabs(gameConfig.players.names.length);
        final configViews = [
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
              : throw UnimplementedError('Offline mode not supported yet'),
          /*
                OfflinePlayersConfigView(
                  teamingConfig: gameConfig.teaming,
                  initialPlayersConfig: gameConfig.players,
                  configController: configController,
                ),
          */
        ];
        final startButton = Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: WideButton(
            onPressed: isAdmin ? () => _startGame(gameConfig) : null,
            onPressedDisabled: () {
              final snackBar =
                  SnackBar(content: Text('Only the host can start the game.'));
              Scaffold.of(context).showSnackBar(snackBar);
            },
            color: MyTheme.accent,
            child: Text('Start Game'),
          ),
        );

        const double configBoxWidth = 480;
        const double configBoxMargin = 16;
        final double wideLayoutWidth =
            (configBoxWidth + 2 * configBoxMargin) * numTabs;
        final bool wideLayout =
            MediaQuery.of(context).size.width >= wideLayoutWidth;

        if (!wideLayout) {
          // One-column view for phones and tablets in portrait mode.
          final tabBar = TabBar(
            controller: _tabController,
            tabs: tabs,
          );
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: localGameData.onlineMode
                ? AppBar(
                    automaticallyImplyLeading: false,
                    title: Text('Hat Game ID: ${localGameData.gameID}'),
                    // For some reason PreferredSize affects not only the bottom of
                    // the AppBar but also the title, making it misaligned with the
                    // normal title text position. Hopefully this is not too
                    // noticeable. Without PreferredSize the AppBar is just too fat.
                    bottom: PreferredSize(
                        preferredSize: Size.fromHeight(64.0), child: tabBar),
                  )
                : PreferredSize(
                    preferredSize: Size.fromHeight(64.0),
                    child: AppBar(
                      automaticallyImplyLeading: false,
                      flexibleSpace: SafeArea(child: tabBar),
                    ),
                  ),
            body: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: configViews,
                  ),
                ),
                startButton,
              ],
            ),
          );
        } else {
          final configBoxes = List<Widget>();
          for (int i = 0; i < numTabs; i++) {
            configBoxes.add(
              SizedBox(
                width: configBoxWidth,
                child: Padding(
                  padding: EdgeInsets.all(configBoxMargin),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: MyTheme.primary,
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            tabs[i].text,
                            // Use the same text style as AppBar.
                            // TODO: Why is font bigger than in actual AppBar?
                            style:
                                Theme.of(context).textTheme.headline6.copyWith(
                                      // TODO: Take color from the theme.
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: configViews[i],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          // Multi-column view for tablets in landscape mode and desktops.
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(localGameData.onlineMode
                  ? 'Hat Game ID: ${localGameData.gameID}'
                  : 'Hat Game'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: configBoxes,
                  ),
                ),
                SizedBox(
                  width: wideLayoutWidth,
                  child: startButton,
                )
              ],
            ),
          );
        }
      },
    );
  }
}
