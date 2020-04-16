import 'package:flutter/material.dart';
import 'package:hatgame/game_state.dart';

class TeamView extends StatelessWidget {
  final TeamViewData _data;
  static const _textStyle = TextStyle(fontSize: 16.0);

  TeamView(this._data);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            _data.performer.name,
            textAlign: TextAlign.right,
            style: _textStyle,
          ),
        ),
        Text(
          ' → ',
          textAlign: TextAlign.center,
          style: _textStyle,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _data.recipients
                .map((player) => Text(
                      player.name,
                      textAlign: TextAlign.left,
                      style: _textStyle,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class GameView extends StatefulWidget {
  @override
  createState() => GameViewState();
}

class GameViewState extends State<GameView> {
  final GameState _gameState = GameState.example();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Column(
        children: [
          TeamView(_gameState.currentTeamViewData()),
          Expanded(
            child: Center(
              child: Text(_gameState.someWord()),
            ),
          ),
        ],
      ),
    );
  }
}
