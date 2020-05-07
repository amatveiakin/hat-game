import 'package:flutter/material.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/theme.dart';

// TODO: Allow final results editing on ScoreView.
// TODO: Does it make sense to show words guessed in modes with many guessers?

List<Widget> addSpacing(
    {@required List<Widget> tiles, double horizontal, double vertical}) {
  if (tiles.isEmpty) return tiles;
  return tiles.skip(1).fold(
      [tiles.first],
      (list, tile) =>
          list + [SizedBox(width: horizontal, height: vertical), tile]);
}

class _TeamScoreView extends StatelessWidget {
  final TeamScoreViewData data;

  _TeamScoreView({@required this.data});

  Widget _playerView(PlayerScoreViewData player) {
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
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 40), // for non-team view
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
                      data.totalScore.toString(),
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
                        tiles: data.players.map(_playerView).toList(),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScoreView extends StatelessWidget {
  final GameData gameData;

  ScoreView({@required this.gameData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Over'),
      ),
      body: Column(
        children: [
          SizedBox(height: 4),
          Expanded(
            child: ListView(
              children: gameData
                  .scoreData()
                  .map((s) => _TeamScoreView(data: s))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
