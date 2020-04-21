import 'dart:math';

import 'package:hatgame/theme.dart';
import 'package:flutter/material.dart';

class PlayersConfigView extends StatefulWidget {
  final void Function(List<String>) playersUpdatedCallback;

  PlayersConfigView(this.playersUpdatedCallback);

  @override
  createState() => _PlayersConfigViewState();
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

class _PlayersConfigViewState extends State<PlayersConfigView> {
  final _players = <_PlayerData>[];
  final _playersToDispose = <_PlayerData>[];
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
    setState(() {
      _playersToDispose.add(player);
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
  void didUpdateWidget(PlayersConfigView oldWidget) {
    for (final player in _playersToDispose) {
      player.dispose();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void setState(fn) {
    super.setState(fn);
    _makeItems();
    _notifyPlayersUpdate();
  }

  @override
  void dispose() {
    for (final player in _playersToDispose + _players) {
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
