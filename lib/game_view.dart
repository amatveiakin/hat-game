import 'package:flutter/material.dart';
import 'package:hatgame/game_state.dart';

class TeamView extends StatelessWidget {
  final TeamViewData _teamData;
  final TurnPhase _turnPhase;
  final TextStyle _textStyle;

  TeamView(this._teamData, this._turnPhase)
      : _textStyle = TextStyle(
            fontSize: 16.0,
            // TODO: Use theme colors.
            // TODO: Fade out animation.
            color: _turnPhase == TurnPhase.prepare
                ? Colors.black
                : Colors.black45);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            _teamData.performer.name,
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
            children: _teamData.recipients
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

class WordView extends StatelessWidget {
  final GameViewState _gameViewState;
  final GameState gameState;

  WordView(this._gameViewState) : gameState = _gameViewState.gameState;

  @override
  Widget build(BuildContext context) {
    switch (gameState.turnPhase()) {
      case TurnPhase.prepare:
        return RaisedButton(
          onPressed: () => _gameViewState.update(() {
            gameState.startExplaning();
          }),
          child: Text("Go!"),
        );
      case TurnPhase.explain:
        return RaisedButton(
          onPressed: () => _gameViewState.update(() {
            gameState.wordGuessed();
          }),
          child: Text(gameState.currentWord()),
        );
      case TurnPhase.review:
        return ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: gameState
                .wordsInThisTurnViewData()
                .map((w) => CheckboxListTile(
                    onChanged: (bool checked) {
                      // TODO: Change word status.
                    },
                    value: w.status == WordInTurnStatus.explained,
                    title: Text(w.text)))
                .toList(),
          ).toList(),
        );
    }
  }
}

class GameView extends StatefulWidget {
  @override
  createState() => GameViewState();
}

class GameViewState extends State<GameView> {
  final GameState gameState = GameState.example();

  void update(Function updater) {
    setState(updater);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hat Game'),
      ),
      body: Column(
        children: [
          TeamView(gameState.currentTeamViewData(), gameState.turnPhase()),
          Expanded(
            child: Center(
              child: WordView(this),
            ),
          ),
        ],
      ),
    );
  }
}
