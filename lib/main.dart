import 'package:flutter/material.dart';
import 'package:hatgame/game_config_view.dart';
import 'package:hatgame/theme.dart';

void main() => runApp(MyApp());

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => GameConfigView()));
          },
          child: Text('New Game'),
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
