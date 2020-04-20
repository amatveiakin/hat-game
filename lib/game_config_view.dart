import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hatgame/game_settings.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/theme.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

enum SinglePlayStyle {
  FullGraph,
  Circle,
}

class SinglePlayStyleSelector extends StatefulWidget {
  final SinglePlayStyle initialPlayStyle;
  final Function changeCallback;

  SinglePlayStyleSelector(this.initialPlayStyle, this.changeCallback);

  @override
  createState() => _SinglePlayStyleSelectorState(initialPlayStyle);
}

class _SinglePlayStyleSelectorState extends State<SinglePlayStyleSelector> {
  SinglePlayStyle value;

  _SinglePlayStyleSelectorState(this.value);

  void _valueChanged(SinglePlayStyle newValue) {
    setState(() {
      value = newValue;
    });
    widget.changeCallback(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Play Style'),
      ),
      body: ListView(
        children: [
          RadioListTile<SinglePlayStyle>(
            // TODO: Add icon.
            title: Text('Clique'),
            // TODO: Detailed description.
            subtitle: Text('Everybody explains to everybody.'),
            value: SinglePlayStyle.FullGraph,
            groupValue: value,
            onChanged: _valueChanged,
          ),
          RadioListTile<SinglePlayStyle>(
            // TODO: Add icon.
            title: Text('Circle'),
            // TODO: Detailed description (mention start seating).
            subtitle: Text('The hat goes in a circle. '
                'Each player explains to the next person.'),
            value: SinglePlayStyle.Circle,
            groupValue: value,
            onChanged: _valueChanged,
          ),
        ],
      ),
    );
  }
}

class TeamingSettingsView extends StatefulWidget {
  @override
  createState() => _TeamingSettingsViewState();
}

class _TeamingSettingsViewState extends State<TeamingSettingsView> {
  bool teamPlay = true;
  bool randomizeTeams = false;
  SinglePlayStyle singlePlayStyle = SinglePlayStyle.FullGraph;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          title: Text('Team play'),
          value: teamPlay,
          onChanged: (bool checked) => setState(() {
            teamPlay = checked;
          }),
        ),
        SwitchListTile(
          title: Text(teamPlay ? 'Random teams' : 'Random turn order'),
          value: randomizeTeams,
          onChanged: (bool checked) => setState(() {
            randomizeTeams = checked;
          }),
        ),
        if (!teamPlay)
          ListTile(
            title: Text(singlePlayStyle == SinglePlayStyle.FullGraph
                ? 'Play style: Clique'
                : 'Play style: Circle'),
            subtitle: Text(singlePlayStyle == SinglePlayStyle.FullGraph
                ? 'Everybody explains to everybody'
                : 'Each player explains to the next person'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SinglePlayStyleSelector(
                          singlePlayStyle,
                          (SinglePlayStyle newValue) => setState(() {
                                singlePlayStyle = newValue;
                              }))));
            },
          )
      ],
    );
  }
}

class PlayersView extends StatefulWidget {
  final Function playersUpdatedCallback;

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

  void _addPlayer(String name) {
    setState(() {
      final playerData = _PlayerData(name);
      playerData.controller.text = (name);
      playerData.controller.addListener(() {
        // Don't call setState, because TextField updates itself.
        playerData.name = playerData.controller.text;
        _notifyPlayersUpdate();
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
    _items.clear();
    _items.addAll(_addDividers(_playerItems));
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

  _GameConfigViewState._(this._players)
      : _playersView = PlayersView((List<String> newPlayers) {
          _players.clear();
          _players.addAll(newPlayers);
        });
  _GameConfigViewState() : this._([]);

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
        body: Padding(
          padding: EdgeInsets.only(top: 6),
          child: TabBarView(
            children: [
              TeamingSettingsView(),
              _playersView,
              Center(child: Text('settings')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _startGame,
          label: Text('Start Game'),
          icon: Icon(Icons.arrow_forward),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
