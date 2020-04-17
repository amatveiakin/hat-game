import 'package:flutter/material.dart';
import 'package:hatgame/game_state.dart';
import 'package:hatgame/timer.dart';

class TeamView extends StatefulWidget {
  final TeamViewData teamData;
  final TurnPhase turnPhase;

  TeamView(this.teamData, this.turnPhase);

  @override
  createState() => TeamViewState();
}

// TODO: Swicth to animation controllers or make the widget stateless.
class TeamViewState extends State<TeamView> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final animationDuration = widget.turnPhase == TurnPhase.prepare
        ? Duration.zero
        : Duration(milliseconds: 300);
    return AnimatedDefaultTextStyle(
      duration: animationDuration,
      style: TextStyle(
        fontSize: 18.0,
        fontWeight: widget.turnPhase == TurnPhase.prepare
            ? FontWeight.bold
            : FontWeight.normal,
        // TODO: Why do we need to specify color?
        // TODO: Take color from the theme.
        color: Colors.black,
      ),
      child: AnimatedOpacity(
        duration: animationDuration,
        opacity: widget.turnPhase == TurnPhase.prepare ? 1.0 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.teamData.performer.name,
                textAlign: TextAlign.right,
              ),
            ),
            Text(
              ' → ',
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.teamData.recipients
                    .map((player) => Text(
                          player.name,
                          textAlign: TextAlign.left,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
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
        return Column(children: [
          Expanded(
            child: Center(
              child: RaisedButton(
                onPressed: () => _gameViewState.update(() {
                  gameState.wordGuessed();
                }),
                padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
                child: Text(
                  gameState.currentWord(),
                  style: TextStyle(fontSize: 24.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: TimerView(
                duration: Duration(seconds: 5),
              ),
            ),
          ),
        ]);
      case TurnPhase.review:
        return Column(children: [
          Expanded(
            child: ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: gameState
                    .wordsInThisTurnViewData()
                    .map((w) => CheckboxListTile(
                        onChanged: (bool checked) => _gameViewState.update(() {
                              gameState.setWordStatus(
                                  w.id,
                                  checked
                                      ? WordInTurnStatus.explained
                                      : WordInTurnStatus.notExplained);
                            }),
                        value: w.status == WordInTurnStatus.explained,
                        title: Text(w.text),
                        controlAffinity: ListTileControlAffinity.leading))
                    .toList(),
              ).toList(),
            ),
          ),
          RaisedButton(
            onPressed: () => _gameViewState.update(() {
              gameState.newTurn();
            }),
            child: Text('Next round'),
          ),
        ]);
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
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Column(
          children: [
            TeamView(gameState.currentTeamViewData(), gameState.turnPhase()),
            Expanded(
              child: Center(
                child: WordView(this),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
