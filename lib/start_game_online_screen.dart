import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/app_info.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/local_storage.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/checked_text_field.dart';
import 'package:hatgame/widget/constrained_scaffold.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/wide_button.dart';

// TODO: Consider using Form + TextFormField instead.

enum JoinGameErrorSource {
  gameID,
  playerName,
}

// Local checks only
InvalidOperation checkGameID(String gameID) {
  if (gameID.isEmpty) {
    return InvalidOperation('Game ID is empty');
  }
}

class NewGameOnlineScreen extends StatefulWidget {
  static const String routeName = '/new-game-online';

  final playerNameController =
      CheckedTextFieldController(checker: checkPlayerName);

  @override
  State<StatefulWidget> createState() => NewGameOnlineScreenState();
}

class NewGameOnlineScreenState extends State<NewGameOnlineScreen> {
  LocalStorage get localStorage => LocalStorage.instance;
  CheckedTextFieldController get playerNameController =>
      widget.playerNameController;

  Future<void> _createGame(BuildContext context) async {
    if (!checkTextFields([
      playerNameController,
    ])) {
      return;
    }
    LocalGameData localGameData;
    try {
      localGameData = await GameController.newLobby(
          Firestore.instance, playerNameController.textController.text);
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => GameConfigView(
          localGameData: localGameData,
        ),
        settings: RouteSettings(name: GameConfigView.routeName),
      ),
      ModalRoute.withName('/'),
    );
  }

  @override
  void initState() {
    playerNameController.textController.text =
        localStorage.get(LocalColPlayerName());
    playerNameController.textController.addListener(() {
      localStorage.set(
          LocalColPlayerName(), playerNameController.textController.text);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    playerNameController.focusNode.requestFocus();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text('New Game Online'),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              child: CheckedTextField(
                textInputAction: TextInputAction.go,
                labelText: 'Player name',
                controller: playerNameController,
                onSubmitted: (_) => _createGame(context),
              ),
            ),
            Expanded(child: Container()),
            WideButton(
              onPressed: () => _createGame(context),
              color: MyTheme.accent,
              child: Text('Create Game'),
              margin: WideButton.bottomButtonMargin,
            ),
          ],
        ),
      ),
    );
  }
}

class JoinGameOnlineScreen extends StatefulWidget {
  static const String routeName = '/join-game-online';

  final gameIDController = CheckedTextFieldController(checker: checkGameID);
  final playerNameController =
      CheckedTextFieldController(checker: checkPlayerName);

  static String makeLink(String gameID) {
    // TODO: Make link redirect to app on mobile.
    return '$webAppPath$routeName/$gameID';
  }

  JoinGameOnlineScreen();

  factory JoinGameOnlineScreen.fromRoute(RouteSettings settings) {
    final String routePrefix = '$routeName/';
    if (!settings.name.startsWith(routePrefix)) {
      return null;
    }
    final String gameID = settings.name.substring(routePrefix.length);
    final screen = JoinGameOnlineScreen();
    screen.gameIDController.textController.text = gameID;
    return screen;
  }

  @override
  State<StatefulWidget> createState() => JoinGameOnlineScreenState();
}

class JoinGameOnlineScreenState extends State<JoinGameOnlineScreen> {
  LocalStorage get localStorage => LocalStorage.instance;
  CheckedTextFieldController get gameIDController => widget.gameIDController;
  CheckedTextFieldController get playerNameController =>
      widget.playerNameController;

  Future<void> _joinGame(BuildContext context) async {
    if (!checkTextFields([
      gameIDController,
      playerNameController,
    ])) {
      return;
    }
    LocalGameData localGameData;
    try {
      localGameData = await GameController.joinLobby(
          Firestore.instance,
          playerNameController.textController.text,
          gameIDController.textController.text);
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
      if (e.tag<JoinGameErrorSource>() == JoinGameErrorSource.playerName) {
        playerNameController.focusNode.requestFocus();
      } else {
        gameIDController.focusNode.requestFocus();
      }
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => GameConfigView(
          localGameData: localGameData,
        ),
        settings: RouteSettings(name: GameConfigView.routeName),
      ),
      ModalRoute.withName('/'),
    );
  }

  @override
  void initState() {
    playerNameController.textController.text =
        localStorage.get(LocalColPlayerName());
    playerNameController.textController.addListener(() {
      localStorage.set(
          LocalColPlayerName(), playerNameController.textController.text);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (gameIDController.textController.text.isEmpty) {
      gameIDController.focusNode.requestFocus();
    } else {
      playerNameController.focusNode.requestFocus();
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    playerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        title: Text('Join Game Online'),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              child: Column(
                // TODO: Field order?
                children: [
                  CheckedTextField(
                    textInputAction: TextInputAction.next,
                    labelText: 'Game ID',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      WhitelistingTextInputFormatter(RegExp(r'[.0-9]+'))
                    ],
                    controller: gameIDController,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  CheckedTextField(
                    textInputAction: TextInputAction.go,
                    labelText: 'Player name',
                    controller: playerNameController,
                    onSubmitted: (_) => _joinGame(context),
                  ),
                ],
              ),
            ),
            Expanded(child: Container()),
            WideButton(
              onPressed: () => _joinGame(context),
              color: MyTheme.accent,
              child: Text('Join Game'),
              margin: WideButton.bottomButtonMargin,
            ),
          ],
        ),
      ),
    );
  }
}
