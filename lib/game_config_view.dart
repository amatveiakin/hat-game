import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/game_settings.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/teaming_config_view.dart';
import 'package:hatgame/theme.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

class PlayersView extends StatefulWidget {
  final void Function(List<String>) playersUpdatedCallback;

  PlayersView(this.playersUpdatedCallback);

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
  final _players = <_PlayerData>[];
  final List<Widget> _items = [];

  void _notifyPlayersUpdate() {
    widget.playersUpdatedCallback(_players.map((p) => p.name).toList());
  }

  void _addPlayer(String name, {@required bool focus}) {
    setState(() {
      final playerData = _PlayerData(name);
      playerData.controller.text = (name);
      playerData.controller.addListener(() {
        // Don't call setState, because TextField updates itself.
        playerData.name = playerData.controller.text;
        _notifyPlayersUpdate();
      });
      if (focus) {
        playerData.focusNode.requestFocus();
      }
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
          color: MyTheme.accent,
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
            _addPlayer('', focus: true);
          }),
          child: Text('Add player'),
        )));
    _items.clear();
    _items.addAll(_addDividers(_playerItems));
  }

  @override
  void initState() {
    // TODO: Delete before prod release.
    _addPlayer('Vasya', focus: false);
    _addPlayer('Petya', focus: false);
    _addPlayer('Masha', focus: false);
    _addPlayer('Dasha', focus: false);
    super.initState();
    _makeItems();
  }

  @override
  void setState(fn) {
    super.setState(fn);
    _makeItems();
    _notifyPlayersUpdate();
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
    return Padding(
      padding: EdgeInsets.only(top: 6),
      child: ReorderableListView(
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
      ),
    );
  }
}

class GameConfigView extends StatefulWidget {
  @override
  createState() => _GameConfigViewState();
}

class _GameConfigViewState extends State<GameConfigView>
    with SingleTickerProviderStateMixin {
  // TODO: Change tab order: Options, Teaming, Players (?)
  // TODO: Consider: make FAB advance to the next screen unless on the
  // last screen alreay. (Are there best practices?)
  final tabs = <Tab>[
    Tab(
      text: 'Teaming',
      // TODO: Add arrows (or several group of people)
      icon: Icon(Icons.people),
    ),
    Tab(
      text: 'Players',
      // TODO: Replace squares with person icons.
      icon: Icon(OMIcons.ballot),
    ),
    Tab(
      text: 'Options',
      icon: Icon(Icons.settings),
    ),
  ];

  final List<String> _players;
  final PlayersView _playersView;
  TabController _tabController;

  _GameConfigViewState._(this._players)
      : _playersView = PlayersView((List<String> newPlayers) {
          _players.clear();
          _players.addAll(newPlayers);
        });
  _GameConfigViewState() : this._([]);

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() {
      FocusScope.of(context).unfocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startGame() {
    var settings = GameSettings.dev();
    // TODO: Programmatically guarantee that this is synced with the view.
    // TODO: Don't crash on invalid input (odd number of player)
    //   OR make every inpit valid.
    int playerIdx = 0;
    settings.teamPlayers = [];
    for (final player in _players) {
      if (playerIdx % 2 == 0) {
        settings.teamPlayers.add([]);
      }
      settings.teamPlayers.last.add(player);
      playerIdx++;
    }
    // TODO: Remove "back" button.
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => GameView(settings)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: TabBar(
            controller: _tabController,
            tabs: tabs,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TeamingConfigView(),
          _playersView,
          Center(child: Text('settings')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startGame,
        label: Text('Start Game'),
        icon: Icon(Icons.arrow_forward),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
