import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/util/assertion.dart';

class OnlinePlayersConfigView extends StatelessWidget {
  final PlayersConfig playersConfig;

  OnlinePlayersConfigView({@required this.playersConfig});

  @override
  Widget build(BuildContext context) {
    Assert.holds(playersConfig.names != null);
    final List<MapEntry<int, String>> entries =
        playersConfig.names.entries.toList();
    // BuiltMap does not sort by key.
    entries.sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      children: entries
          .map((e) => ListTile(
                title: Text(e.value),
              ))
          .toList(),
    );
  }
}
