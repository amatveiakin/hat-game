import 'package:flutter/material.dart';
import 'package:hatgame/game_state.dart';

void main() => runApp(MyApp());

class GameView extends StatefulWidget {
  @override
  createState() => GameViewState();
}

class GameViewState extends State<GameView> {
  final _gameState = GameState.example();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Center(
        child: Text(_gameState.someWord()),
      ),
    );
  }
}

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
            // TODO: remove "back" button
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => GameView()));
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
      title: 'Hat Game',
      home: StartScreen(),
    );
  }
}
