import 'package:flutter/material.dart';
import 'package:hatgame/game_view.dart';

class PlayersView extends StatefulWidget {
  @override
  createState() => _PlayersViewState();
}

class _PlayersViewState extends State<PlayersView> {
  var players = <String>[
    'Vasya',
    'Petya',
    'Masha',
    'Dasha',
  ];
  List<Widget> items = [];

  List<Widget> _addDividers(List<ListTile> items) {
    var result = <Widget>[];
    int i = 0;
    for (final item in items) {
      if (i > 0 && i % 2 == 0) {
        result.add(Divider(key: UniqueKey()));
      }
      result.add(item);
      i++;
    }
    return result;
  }

  int _getPlayerIndex(int itemIndex) {
    int playerIndex = 0;
    for (int i = 0; i < itemIndex; i++) {
      if (!(items[i] is Divider)) playerIndex++;
    }
    return playerIndex;
  }

  void _makeItems() {
    items = _addDividers(players
        .map((name) => ListTile(
              key: UniqueKey(),
              title: Text(name),
            ))
        .toList());
  }

  @override
  void initState() {
    super.initState();
    _makeItems();
  }

  @override
  void setState(fn) {
    super.setState(fn);
    _makeItems();
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          // TODO: Swap teams instead (?)
          oldIndex = _getPlayerIndex(oldIndex);
          newIndex = _getPlayerIndex(newIndex);
          if (newIndex > oldIndex) {
            newIndex--;
          }
          final p = players.removeAt(oldIndex);
          players.insert(newIndex, p);
        });
      },
      scrollDirection: Axis.vertical,
      children: items,
    );
  }
}

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
            Center(child: PlayersView()),
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
