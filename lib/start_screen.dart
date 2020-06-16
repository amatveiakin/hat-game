import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/about_screen.dart';
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

  @override
  State<StatefulWidget> createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  Future<void> _newGameOffline(BuildContext context) async {
    LocalGameData localGameData = await GameController.newGameOffine();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => GameConfigView(
        localGameData: localGameData,
      ),
      settings: RouteSettings(name: GameConfigView.routeName),
    ));
  }

  Future<void> _newGameOnline(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => NewGameOnlineScreen(),
      settings: RouteSettings(name: NewGameOnlineScreen.routeName),
    ));
  }

  Future<void> _joinGame(BuildContext context) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => JoinGameOnlineScreen(),
      settings: RouteSettings(name: JoinGameOnlineScreen.routeName),
    ));
  }

  void executeAdditionalAction(_AdditionalAction action) {
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
        title: Text(tr('app_title')),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<_AdditionalAction>(
                value: _AdditionalAction.gameRules,
                child: Text('Hat game rules'),
              ),
              PopupMenuItem<_AdditionalAction>(
                value: _AdditionalAction.aboutApp,
                child: Text('About the app'),
              ),
            ],
            onSelected: executeAdditionalAction,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 6),
            Text(
              'This app is in Beta. Version: $appVersion',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.0, color: Colors.black45),
            ),
            Expanded(child: Container()),
            WideButton(
              onPressed: () => _newGameOffline(context),
              child: Text('New Local Game'),
            ),
            SizedBox(height: 24),
            WideButton(
              onPressed: () => _newGameOnline(context),
              child: Text('New Game Online'),
            ),
            SizedBox(height: 24),
            WideButton(
              onPressed: () => _joinGame(context),
              child: Text('Join Game'),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }
}
