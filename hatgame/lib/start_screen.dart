import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/about_screen.dart';
import 'package:hatgame/app_settings.dart';
import 'package:hatgame/app_version.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/rules_screen.dart';
import 'package:hatgame/start_game_online_screen.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/wide_button.dart';

enum _AdditionalAction {
  gameRules,
  aboutApp,
}

class StartScreen extends StatefulWidget {
  static const String routeName = '/';

  const StartScreen({super.key});

  @override
  State<StatefulWidget> createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  Future<void> _newGameOffline(BuildContext context) async {
    LocalGameData localGameData = await GameController.newGameOffine();
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => GameConfigView(
          localGameData: localGameData,
        ),
        settings: const RouteSettings(name: GameConfigView.routeName),
      ));
    }
  }

  Future<void> _newGameOnline(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => NewGameOnlineScreen(),
      settings: const RouteSettings(name: NewGameOnlineScreen.routeName),
    ));
  }

  Future<void> _joinGame(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => JoinGameOnlineScreen(),
      settings: const RouteSettings(name: JoinGameOnlineScreen.routeName),
    ));
  }

  void _openSettings() {
    Navigator.of(context).pushNamed(AppSettingsView.routeName);
  }

  void _executeAdditionalAction(_AdditionalAction action) {
    switch (action) {
      case _AdditionalAction.gameRules:
        Navigator.of(context).pushNamed(RulesScreen.routeName);
        break;
      case _AdditionalAction.aboutApp:
        Navigator.of(context).pushNamed(AboutScreen.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.longestSide < 960) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text(tr('hat_game')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<_AdditionalAction>(
                value: _AdditionalAction.gameRules,
                child: Text(tr('hat_game_rules')),
              ),
              PopupMenuItem<_AdditionalAction>(
                value: _AdditionalAction.aboutApp,
                child: Text(tr('about_the_app')),
              ),
            ],
            onSelected: _executeAdditionalAction,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Text(
              tr('app_version', args: [appVersion]),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.0, color: Colors.black45),
            ),
            Expanded(child: Container()),
            WideButton(
              onPressed: () => _newGameOffline(context),
              coloring: WideButtonColoring.neutral,
              child: Text(tr('new_local_game')),
            ),
            const SizedBox(height: 24),
            WideButton(
              onPressed: () => _newGameOnline(context),
              coloring: WideButtonColoring.neutral,
              child: Text(tr('new_game_online')),
            ),
            const SizedBox(height: 24),
            WideButton(
              onPressed: () => _joinGame(context),
              coloring: WideButtonColoring.neutral,
              child: Text(tr('join_game')),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }
}
