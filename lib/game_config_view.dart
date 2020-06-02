import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_phase.dart';
import 'package:hatgame/db/db_document.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/game_navigator.dart';
import 'package:hatgame/offline_player_config_view.dart';
import 'package:hatgame/online_player_config_view.dart';
import 'package:hatgame/rules_config_view.dart';
import 'package:hatgame/teaming_config_view.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/sections_scaffold.dart';
import 'package:hatgame/widget/wide_button.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

// TODO: 'Revert to default' button.

class GameConfigView extends StatefulWidget {
  static const String routeName = '/game-config'; // for offline only

  final LocalGameData localGameData;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  GameConfigView({@required this.localGameData});

  @override
  createState() => _GameConfigViewState();
}

class _GameConfigViewState extends State<GameConfigView>
    with SingleTickerProviderStateMixin {
  final GameNavigator navigator =
      GameNavigator(currentPhase: GamePhase.configure);

  SectionTitleData rulesSectionTitle() => SectionTitleData(
        text: 'Rules',
        icon: Icon(Icons.settings),
      );
  SectionTitleData teamingSectionTitle() => SectionTitleData(
        text: 'Teaming',
        // TODO: Add arrows / several groups of people / gearwheel.
        icon: Icon(Icons.people),
      );
  SectionTitleData playersSectionTitle(int numPlayers) => SectionTitleData(
        text: 'Players: $numPlayers',
        // TODO: Replace squares with person icons.
        icon: Icon(OMIcons.ballot),
      );

  static const int rulesTabIndex = 0;
  static const int teamingTabIndex = 1;
  static const int playersTabIndex = 2;
  static const int numTabs = 3;

  LocalGameData get localGameData => widget.localGameData;
  bool get isAdmin => localGameData.isAdmin;
  bool _navigatedToKicked = false;
  bool _navigatedToTeamCompositions = false;

  TabController _tabController;
  final _rulesConfigViewController = RulesConfigViewController();

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
    _rulesConfigViewController.dispose();
    super.dispose();
  }

  void _getJoinLink(GlobalKey<ScaffoldState> scaffoldKey) {
    // TODO: Make link redirect to app on mobile.
    // TODO: Hint that this is the same as site address in web version.
    final String link = localGameData.gameUrl;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game join link'),
          content: Row(
            children: [
              Expanded(
                child: Text(link),
              ),
              IconButton(
                icon: Icon(Icons.content_copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link)).then((_) {
                    scaffoldKey.currentState.showSnackBar(
                        SnackBar(content: Text('Link copied to clipboard')));
                  }, onError: (error) {
                    // TODO: Log to firebase.
                    debugPrint('Cannot copy to clipboard. Error: $error');
                    scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text('Cannot copy link to clipboard :(')));
                  });
                },
              ),
            ],
          ),
          actions: [
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
  }

  void _next(GameConfig gameConfig) async {
    try {
      if (gameConfig.rules.writeWords) {
        // Check that teams can be generate, don't write them down yet.
        GameController.generateTeamCompositions(
            localGameData.gameReference, gameConfig);
        await GameController.toWriteWordsPhase(localGameData.gameReference);
      } else {
        await GameController.updateTeamCompositions(
            localGameData.gameReference, gameConfig);
      }
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
      _tabController.animateTo(playersTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return navigator.buildWrapper(
      context: context,
      localGameData: localGameData,
      buildBody: buildBody,
    );
  }

  Widget buildBody(BuildContext context, DBDocumentSnapshot snapshot) {
    final configController =
        GameConfigController.fromSnapshot(localGameData, snapshot);
    final GameConfig gameConfig = configController.configWithOverrides();
    Assert.holds(gameConfig != null);

    _rulesConfigViewController.updateFromConfig(gameConfig.rules);
    final sections = [
      SectionData(
        title: rulesSectionTitle(),
        body: RulesConfigView(
          onlineMode: localGameData.onlineMode,
          viewController: _rulesConfigViewController,
          config: gameConfig.rules,
          configController: configController,
        ),
      ),
      SectionData(
        title: teamingSectionTitle(),
        body: TeamingConfigView(
          onlineMode: localGameData.onlineMode,
          config: gameConfig.teaming,
          configController: configController,
        ),
      ),
      SectionData(
        title: playersSectionTitle(gameConfig.players.names.length),
        body: localGameData.onlineMode
            ? OnlinePlayersConfigView(
                localGameData: localGameData,
                playersConfig: gameConfig.players,
              )
            : OfflinePlayersConfigView(
                teamingConfig: gameConfig.teaming,
                initialPlayersConfig: gameConfig.players,
                configController: configController,
              ),
      ),
    ];
    final startButton = WideButton(
      onPressed: isAdmin ? () => _next(gameConfig) : null,
      color: MyTheme.accent,
      child: GoNextButtonCaption(gameConfig.rules.writeWords
          ? 'Write Words'
          : gameConfig.teaming.teamPlay ? 'Teams & Turn Order' : 'Turn Order'),
      margin: WideButton.bottomButtonMargin,
    );

    return SectionsScaffold(
      scaffoldKey: widget.scaffoldKey,
      appBarAutomaticallyImplyLeading: false,
      appTitle: localGameData.onlineMode
          ? 'Hat Game ID: ${localGameData.gameID}'
          : 'Hat Game',
      appTitlePresentInNarrowMode: localGameData.onlineMode,
      actions: localGameData.onlineMode
          ? [
              IconButton(
                icon: Icon(Icons.link),
                onPressed: () => _getJoinLink(widget.scaffoldKey),
              )
            ]
          : [],
      sections: sections,
      tabController: _tabController,
      bottomWidget: startButton,
    );
  }
}
