import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/util/assertion.dart';

class OnlinePlayersConfigView extends StatelessWidget {
  final LocalGameData localGameData;
  final PlayersConfig playersConfig;

  OnlinePlayersConfigView({
    @required this.localGameData,
    @required this.playersConfig,
  });

  static Future<bool> _kickConfimationDialog(BuildContext context,
      {@required String playerName}) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('Are you sure you want to kick $playerName?'),
          actions: [
            FlatButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FlatButton(
              child: Text('Kick'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  bool _canKick(int playerID) =>
      localGameData.isAdmin && localGameData.myPlayerID != playerID;

  void _kickPlayer(BuildContext context,
      {@required int playerID, @required String playerName}) async {
    final bool kick =
        await _kickConfimationDialog(context, playerName: playerName) ?? false;
    if (kick) {
      GameController.kickPlayer(localGameData.gameReference, playerID);
    }
  }

  @override
  Widget build(BuildContext context) {
    Assert.holds(playersConfig.names != null);
    final List<MapEntry<int, String>> entries =
        playersConfig.names.entries.toList();
    // BuiltMap does not sort by key.
    entries.sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      children: entries
          .map(
            (e) => ListTile(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(e.value),
                  ),
                  if (_canKick(e.key)) SizedBox(width: 4),
                  if (_canKick(e.key))
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.clear),
                      onPressed: () => _kickPlayer(context,
                          playerID: e.key, playerName: e.value),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
