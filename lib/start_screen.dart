import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/app_version.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:hatgame/widget/invalid_operation_dialog.dart';
import 'package:hatgame/widget/wide_button.dart';

Future<String> _newGameOnlineDialog(BuildContext context) async {
  String playerName = '';
  final closeDialog = () => Navigator.of(context).pop(playerName);
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('New Game'),
        content: TextField(
          textInputAction: TextInputAction.go,
          autofocus: true,
          decoration: new InputDecoration(
            labelText: 'Player name',
          ),
          onChanged: (value) {
            playerName = value;
          },
          onSubmitted: (_) => closeDialog(),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Create'),
            onPressed: closeDialog,
          ),
        ],
      );
    },
  );
}

class JoinGameParams {
  String playerName = '';
  String gameID = '';
}

Future<JoinGameParams> _joinGameDialog(BuildContext context) async {
  final params = JoinGameParams();
  final closeDialog = () => Navigator.of(context).pop(params);
  return showDialog<JoinGameParams>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Join Game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              textInputAction: TextInputAction.next,
              autofocus: true,
              decoration: new InputDecoration(
                labelText: 'Game ID',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
              onChanged: (value) {
                params.gameID = value;
              },
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            TextField(
              textInputAction: TextInputAction.go,
              autofocus: true,
              decoration: new InputDecoration(
                labelText: 'Player name',
              ),
              onChanged: (value) {
                params.playerName = value;
              },
              onSubmitted: (_) => closeDialog(),
            ),
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Join'),
            onPressed: closeDialog,
          ),
        ],
      );
    },
  );
}

class StartScreen extends StatelessWidget {
  Future<void> _newGameOnline(BuildContext context) async {
    final String playerName = await _newGameOnlineDialog(context);
    if (playerName == null) {
      return;
    }
    LocalGameData localGameData;
    try {
      localGameData = await GameController.newLobby(playerName);
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GameConfigView(
                  localGameData: localGameData,
                )));
  }

  Future<void> _joinGame(BuildContext context) async {
    final JoinGameParams params = await _joinGameDialog(context);
    if (params == null) {
      return;
    }
    LocalGameData localGameData;
    try {
      localGameData =
          await GameController.joinLobby(params.playerName, params.gameID);
    } on InvalidOperation catch (e) {
      showInvalidOperationDialog(context: context, error: e);
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GameConfigView(
                  localGameData: localGameData,
                )));
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.longestSide < 960) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
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
