import 'package:flutter/material.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/theme.dart';

// TODO: Allow final results editing on ScoreView.
// TODO: Does it make sense to show words guessed in modes with many guessers?

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
      ),
    );
  }
}

class ScoreView extends StatelessWidget {
  final GameData gameData;

  ScoreView({@required this.gameData});

  @override
  Widget build(BuildContext context) {
    final teams = gameData.teams();
    final listTiles = List<_TeamScoreView>();
    if (teams != null) {
      for (final team in teams) {
        final players = List<_PlayerData>();
        final totalWordsExplained = List<int>();
        final totalWordsGuessed = List<int>();
        for (final playerIdx in team) {
          final p = gameData.state.players[playerIdx];
          totalWordsExplained.addAll(p.wordsExplained);
          totalWordsGuessed.addAll(p.wordsGuessed);
          players.add(_PlayerData(
            name: p.name,
            wordsExplained: p.wordsExplained.length,
            wordsGuessed: p.wordsGuessed.length,
          ));
        }
        // There is always only one explaining player, so no need to de-dup.
        // Frankly, the score could've been computed directly as:
        //   totalScore += p.wordsExplained.length;
        // The sets are just for sanity-checking.
        final totalScore = totalWordsExplained.length;
        Assert.eq(totalScore, totalWordsExplained.toSet().length);
        Assert.eq(totalScore, totalWordsGuessed.toSet().length);
        listTiles.add(_TeamScoreView(totalScore: totalScore, players: players));
      }
    } else {
      for (final p in gameData.state.players) {
        listTiles.add(
          _TeamScoreView(
            totalScore: p.wordsExplained.length + p.wordsGuessed.length,
            players: [
              _PlayerData(
                name: p.name,
                wordsExplained: p.wordsExplained.length,
                wordsGuessed: p.wordsGuessed.length,
              ),
            ],
          ),
        );
      }
    }
    listTiles.sort((a, b) => b.totalScore.compareTo(a.totalScore));

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
