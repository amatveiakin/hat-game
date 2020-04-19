import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/theme.dart';

class PlayersView extends StatefulWidget {
  @override
  createState() => _PlayersViewState();
}

class _PlayerData {
  String name;
  TextEditingController controller = TextEditingController();
  FocusNode focusNode = FocusNode();

  _PlayerData(this.name);

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _PlayersViewState extends State<PlayersView> {
  var _players = <_PlayerData>[];
  List<Widget> _items = [];

  void _addPlayer(String name) {
    setState(() {
      final playerData = _PlayerData(name);
      playerData.controller.text = (name);
      playerData.controller.addListener(() {
        // Don't call setState, because TextField updates itself.
        playerData.name = playerData.controller.text;
      });
      playerData.focusNode.requestFocus();
      _players.add(playerData);
    });
  }

  void _deletePlayer(_PlayerData player) {
    player.dispose();
    setState(() {
      _players.remove(player);
    });
  }

  List<Widget> _addDividers(List<ListTile> items) {
    var result = <Widget>[];
    int i = 0;
    for (final item in items) {
      if (i > 0 && i % 2 == 0) {
        result.add(Divider(
          key: UniqueKey(),
          color: MyColors.accent,
          thickness: 3.0,
          height: 20.0,
        ));
      }
      result.add(item);
      i++;
    }
    return result;
  }

  int _getPlayerIndex(int itemIndex) {
    int playerIndex = 0;
    for (int i = 0; i < itemIndex; i++) {
      if (!(_items[i] is Divider)) playerIndex++;
    }
    return min(playerIndex, _players.length - 1);
  }

  void _makeItems() {
    final listItemPadding = EdgeInsets.fromLTRB(10, 1, 10, 1);
    final listItemPaddingSmallRight = EdgeInsets.fromLTRB(listItemPadding.left,
        listItemPadding.top, listItemPadding.right / 2, listItemPadding.bottom);
    var _playerItems = <ListTile>[];
    for (int i = 0; i < _players.length; ++i) {
      final player = _players[i];
      _playerItems.add(ListTile(
        key: UniqueKey(),
        contentPadding: listItemPaddingSmallRight,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                decoration:
                    InputDecoration(filled: true, border: InputBorder.none),
                focusNode: player.focusNode,
                controller: player.controller,
              ),
            ),
            SizedBox(width: 12),
            // TODO: Make sure we don't have two drag handles on iOS.
            Icon(Icons.drag_handle),
            SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.clear),
              onPressed: () => _deletePlayer(player),
            ),
          ],
        ),
      ));
    }
    _playerItems.add(ListTile(
        key: UniqueKey(),
        contentPadding: listItemPadding,
        title: OutlineButton(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          onPressed: () => setState(() {
            _addPlayer('');
          }),
          child: Text('Add player'),
        )));
    _items = _addDividers(_playerItems);
  }

  @override
  void initState() {
    // TODO: Delete before prod release.
    _addPlayer('Vasya');
    _addPlayer('Petya');
    _addPlayer('Masha');
    _addPlayer('Dasha');
    super.initState();
    _makeItems();
  }

  @override
  void setState(fn) {
    super.setState(fn);
    _makeItems();
  }

  @override
  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    super.dispose();
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
          final p = _players.removeAt(oldIndex);
          _players.insert(newIndex, p);
        });
      },
      scrollDirection: Axis.vertical,
      children: _items,
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
