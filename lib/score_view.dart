import 'package:flutter/material.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/game_state.dart';
import 'package:hatgame/theme.dart';

class _PlayerData {
  final String name;
  final int wordsExplained;
  final int wordsGuessed;

  _PlayerData(
      {@required this.name,
      @required this.wordsExplained,
      @required this.wordsGuessed});
}

List<Widget> addSpacing(
    {@required List<Widget> tiles, double horizontal, double vertical}) {
  if (tiles.isEmpty) return tiles;
  return tiles.skip(1).fold(
      [tiles.first],
      (list, tile) =>
          list + [SizedBox(width: horizontal, height: vertical), tile]);
}

class _TeamScoreView extends StatelessWidget {
  final int totalScore;
  final List<_PlayerData> players;

  _TeamScoreView({@required this.totalScore, @required this.players});

  Widget _playerView(_PlayerData player) {
    return Row(
      children: [
        Expanded(
          child: Text(
            player.name,
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
        ),
        Text(
          '${player.wordsExplained} / ${player.wordsGuessed}',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 60.0,
              child: Container(
                color: MyTheme.primary,
                child: Center(
                  child: Text(
                    totalScore.toString(),
                    style: TextStyle(
                      fontSize: 28.0,
                      // TODO: Take the color from theme.
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 2),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: addSpacing(
                      vertical: 4,
                      tiles: players.map(_playerView).toList(),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreView extends StatelessWidget {
  final GameState gameState;

  ScoreView({@required this.gameState});

  @override
  Widget build(BuildContext context) {
    final teamBodies = gameState.teamingStrategy.getAllTeamBodies();
    Assert.holds(teamBodies != null); // TODO: Support individual mode.
    final listTiles = List<Widget>();
    for (final team in teamBodies) {
      final players = List<_PlayerData>();
      int totalScore = 0;
      int totalScoreControl = 0;
      for (final playerIdx in team) {
        final p = gameState.players[playerIdx];
        totalScore += p.wordsExplained.length;
        totalScoreControl += p.wordsGuessed.length;
        players.add(_PlayerData(
          name: p.name,
          wordsExplained: p.wordsExplained.length,
          wordsGuessed: p.wordsGuessed.length,
        ));
      }
      Assert.eq(totalScore, totalScoreControl);
      listTiles.add(_TeamScoreView(totalScore: totalScore, players: players));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Over'),
      ),
      body: Column(
        children: [
          SizedBox(height: 4),
          Expanded(
            child: ListView(
              children: listTiles,
            ),
          ),
        ],
      ),
    );
  }
}
