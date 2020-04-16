import 'package:flutter/material.dart';
import 'package:hatgame/game_state.dart';

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
