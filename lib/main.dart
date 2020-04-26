import 'package:flutter/material.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/widget/wide_button.dart';

void main() => runApp(MyApp());

class StartScreen extends StatelessWidget {
  void _newGame(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => GameConfigView()));
  }

  void _joinGame(BuildContext context) {
    // TODO: Remove "back" button.
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => GameView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WideButton(
              onPressed: () => _newGame(context),
              child: Text('New Game'),
            ),
            SizedBox(height: 24),
            WideButton(
              onPressed: () => _joinGame(context),
              child: Text('Join Game'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Increase default font sizes
        textTheme: Theme.of(context).textTheme.apply(fontSizeDelta: 2.0),
        primaryColor: MyTheme.primary,
        primaryColorDark: MyTheme.primaryDark,
        accentColor: MyTheme.accent,
      ),
      title: 'Hat Game',
      home: StartScreen(),
    );
  }
}
