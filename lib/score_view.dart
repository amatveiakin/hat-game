import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/theme.dart';
import 'package:hatgame/util/assertion.dart';

// TODO: Allow final results editing on ScoreView.
// TODO: Does it make sense to show words guessed in modes with many guessers?

class _PlayerPerformance {
  int wordsExplained = 0;
  int wordsGuessed = 0;
}

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

// TODO: Include score computation in the scope of GameController unit test.
Map<int, _PlayerPerformance> _parseTurnLog(
    GameConfig config, List<TurnRecord> turnLog) {
  final Map<int, _PlayerPerformance> playerPerformance = config.players.names
      .map((id, name) => MapEntry(id, _PlayerPerformance()))
      .toMap();
  for (final t in turnLog) {
    final int numWordsScored =
        t.wordsInThisTurn.where((w) => w.status == WordStatus.explained).length;
    playerPerformance[t.party.performer].wordsExplained += numWordsScored;
    for (final p in t.party.recipients) {
      playerPerformance[p].wordsGuessed += numWordsScored;
    }
  }
  return playerPerformance;
}

class ScoreView extends StatelessWidget {
  final GameData gameData;

  ScoreView({@required this.gameData});

  @override
  Widget build(BuildContext context) {
    final Map<int, _PlayerPerformance> playerPerformance =
        _parseTurnLog(gameData.config, gameData.turnLog);
    final teams = gameData.initialState.teams;
    final listTiles = List<_TeamScoreView>();
    if (teams != null) {
      for (final team in teams) {
        final players = List<_PlayerData>();
        int totalWordsExplained = 0;
        int totalWordsGuessed = 0;
        for (final playerID in team) {
          final performance = playerPerformance[playerID];
          totalWordsExplained += performance.wordsExplained;
          totalWordsGuessed += performance.wordsGuessed;
          players.add(_PlayerData(
            name: gameData.config.players.names[playerID],
            wordsExplained: performance.wordsExplained,
            wordsGuessed: performance.wordsGuessed,
          ));
        }
        if (gameData.config.teaming.guessingInLargeTeam !=
            IndividualPlayStyle.broadcast) {
          Assert.eq(totalWordsExplained, totalWordsGuessed);
        }
        listTiles.add(
            _TeamScoreView(totalScore: totalWordsExplained, players: players));
      }
    } else {
      gameData.config.players.names.forEach((playerID, name) {
        final performance = playerPerformance[playerID];
        listTiles.add(
          _TeamScoreView(
            totalScore: performance.wordsExplained + performance.wordsGuessed,
            players: [
              _PlayerData(
                name: name,
                wordsExplained: performance.wordsExplained,
                wordsGuessed: performance.wordsGuessed,
              ),
            ],
          ),
        );
      });
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
