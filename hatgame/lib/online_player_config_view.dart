import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_controller.dart';
import 'package:hatgame/game_data.dart';
import 'package:hatgame/widget/dialog.dart';

// TODO: Support or ban manual teams.
class OnlinePlayersConfigView extends StatelessWidget {
  final LocalGameData localGameData;
  final PlayersConfig? playersConfig;

  const OnlinePlayersConfigView({
    super.key,
    required this.localGameData,
    required this.playersConfig,
  });

  static Future<bool> _kickConfimationDialog(BuildContext context,
      {required String playerName}) async {
    return multipleChoiceDialog<bool>(
      context: context,
      contentText: context.tr('confirm_kick_player', args: [playerName]),
      choices: [
        DialogChoice(false, context.tr('cancel')),
        DialogChoice(true, context.tr('kick')),
      ],
      defaultChoice: false,
    );
  }

  bool _canKick(int playerID) =>
      localGameData.isAdmin && localGameData.myPlayerID != playerID;

  void _kickPlayer(BuildContext context,
      {required int playerID, required String playerName}) async {
    final bool kick =
        await _kickConfimationDialog(context, playerName: playerName);
    if (kick) {
      GameController.kickPlayer(localGameData.gameReference, playerID);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<int, String>> entries =
        playersConfig!.names.entries.toList();
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
                  if (_canKick(e.key)) const SizedBox(width: 4),
                  if (_canKick(e.key))
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.clear),
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
