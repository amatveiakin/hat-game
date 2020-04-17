import 'package:flutter/material.dart';
import 'package:hatgame/game_view.dart';

class GameConfigView extends StatefulWidget {
  @override
  createState() => _GameConfigViewState();
}

class _GameConfigViewState extends State<GameConfigView> {
  final tabs = <Tab>[
    Tab(
      text: 'Players',
      icon: Icon(Icons.people),
    ),
    Tab(
      text: 'Options',
      icon: Icon(Icons.settings),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: TabBar(
              tabs: tabs,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: Text('players')),
            Center(child: Text('settings')),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // TODO: remove "back" button
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => GameView()));
          },
          label: Text('Start Game'),
          icon: Icon(Icons.arrow_forward),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
