import 'package:easy_localization/easy_localization.dart';
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
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/image_assert_icon.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/sections_scaffold.dart';
import 'package:hatgame/widget/wide_button.dart';

// TODO: 'Revert to default' button.

class GameConfigView extends StatefulWidget {
  static const String routeName = '/game-config'; // for offline only

  final LocalGameData localGameData;

  const GameConfigView({super.key, required this.localGameData});

  @override
  createState() => _GameConfigViewState();
}

class _GameConfigViewState extends State<GameConfigView>
    with TickerProviderStateMixin {
  final GameNavigator navigator =
      GameNavigator(currentPhase: GamePhase.configure);

  SectionTitleData rulesSectionTitle() => SectionTitleData(
        icon: const ImageAssetIcon('images/rules_config.png'),
      );
  SectionTitleData playersSectionTitle() => SectionTitleData(
        icon: const ImageAssetIcon('images/players_config.png'),
      );

  static const int rulesTabIndex = 0;
  static const int playersTabIndex = 1;
  static const int numTabs = 2;

  LocalGameData get localGameData => widget.localGameData;
  bool get isAdmin => localGameData.isAdmin;

  late TabController _tabController;
  late RulesConfigViewController _rulesConfigViewController;
  late TeamingConfigViewController _teamingConfigViewController;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: numTabs);
    _tabController.addListener(() {
      // Hide virtual keyboard
      FocusScope.of(context).unfocus();
    });
    _rulesConfigViewController = RulesConfigViewController(vsync: this);
    _teamingConfigViewController = TeamingConfigViewController();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rulesConfigViewController.dispose();
    _teamingConfigViewController.dispose();
    super.dispose();
  }

  void _getJoinLink() {
    // TODO: Make link redirect to app on mobile.
    // TODO: Hint that this is the same as site address in web version.
    final String link = localGameData.gameUrl;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('game_join_link')),
          content: Row(
            children: [
              Expanded(
                child: Text(link),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link)).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(tr('link_copied_to_clipboard'))));
                  }, onError: (error) {
                    // TODO: Log to firebase.
                    debugPrint('Cannot copy to clipboard. Error: $error');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(tr('cannot_copy_link_to_clipboard'))));
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(tr('ok')),
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
      GameController.preGameCheck(gameConfig);
    } on InvalidOperation catch (e) {
      await showInvalidOperationDialog(context: context, error: e);
      final errorSource = e.tag<StartGameErrorSource>();
      if (errorSource != null) {
        switch (errorSource) {
          case StartGameErrorSource.players:
            _tabController.animateTo(playersTabIndex);
            break;
          case StartGameErrorSource.dictionaries:
            _tabController.animateTo(rulesTabIndex);
            _rulesConfigViewController.dictionariesHighlightController
                .highlight();
            break;
        }
      }
      return;
    }

    if (gameConfig.rules.writeWords) {
      await GameController.toWriteWordsPhase(localGameData.gameReference);
    } else {
      await GameController.updateTeamCompositions(
          localGameData.gameReference, gameConfig);
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

    _rulesConfigViewController.updateFromConfig(gameConfig.rules);
    _teamingConfigViewController.updateFromConfig(gameConfig.teaming);
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
        title: playersSectionTitle(),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Material(
              elevation: 5.0,
              child: TeamingConfigView(
                onlineMode: localGameData.onlineMode,
                viewController: _teamingConfigViewController,
                config: gameConfig.teaming,
                configController: configController,
                numPlayers: gameConfig.players!.names.length,
              ),
            ),
          ),
          Expanded(
            child: localGameData.onlineMode
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
        ]),
      ),
    ];
    Assert.eq(sections.length, numTabs);
    final startButton = WideButton(
      onPressed: isAdmin ? () => _next(gameConfig) : null,
      onPressedDisabled: isAdmin
          ? null
          : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Only the host can proceed'))), // TODO: tr
      coloring: WideButtonColoring.secondary,
      margin: WideButton.bottomButtonMargin,
      child: GoNextButtonCaption(gameConfig.rules.writeWords
          ? tr('write_words_titlecase')
          : tr('next')),
    );

    return SectionsScaffold(
      appBarAutomaticallyImplyLeading: false,
      appTitle: localGameData.onlineMode
          ? tr('hat_game_id', args: [localGameData.gameID.toString()])
          : tr('hat_game'),
      appTitlePresentInNarrowMode: localGameData.onlineMode,
      actions: localGameData.onlineMode
          ? [
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: () => _getJoinLink(),
              )
            ]
          : [],
      sections: sections,
      tabController: _tabController,
      bottomWidget: startButton,
    );
  }
}
