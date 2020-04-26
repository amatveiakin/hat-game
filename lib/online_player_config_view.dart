import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/util/assertion.dart';

class OnlinePlayersConfigView extends StatelessWidget {
  final PlayersConfig playersConfig;

  OnlinePlayersConfigView({@required this.playersConfig});

  @override
  Widget build(BuildContext context) {
    Assert.holds(playersConfig.names != null);
    return ListView(
      children: playersConfig.names
          .map((name) => ListTile(
                title: Text(name),
              ))
          .toList(),
    );
  }
}
