import 'dart:math';

import 'package:hatgame/assertion.dart';
import 'package:hatgame/game_config.dart';
import 'package:hatgame/theme.dart';
import 'package:flutter/material.dart';

class IntermediatePlayersConfig {
  // One of the two is set depending on teaming config.
  List<List<String>> teamPlayers;
  List<String> players;

  IntermediatePlayersConfig.nulls();
  IntermediatePlayersConfig.defaults() : players = [];
  // TODO: Delete before prod release.
  IntermediatePlayersConfig.dev()
      : players = ['Vasya', 'Petya', 'Masha', 'Dasha'];
}

bool _manualTeams(TeamingConfig teamingConfig) {
  return teamingConfig.teamPlay && !teamingConfig.randomizeTeams;
}

bool _manualOrder(TeamingConfig teamingConfig) {
  return !teamingConfig.randomizeTeams;
}

void _updateIntermediatePlayersConfig(
    IntermediatePlayersConfig playersConfig, bool manualTeams) {
  if (playersConfig.players != null) {
    if (manualTeams) {
      playersConfig.teamPlayers = [playersConfig.players];
      playersConfig.players = null;
    }
  } else if (playersConfig.teamPlayers != null) {
    if (!manualTeams) {
      playersConfig.players =
          playersConfig.teamPlayers.expand((t) => t).toList();
      playersConfig.teamPlayers = null;
    }
  } else {
    Assert.fail('IntermediatePlayersConfig not initialized');
  }
}

class PlayersConfigView extends StatefulWidget {
  final bool manualTeams;
  final bool manualOrder;
  final IntermediatePlayersConfig initialPlayersConfig;
  final void Function(IntermediatePlayersConfig) onPlayersUpdated;

  PlayersConfigView(
      {@required teamingConfig,
      @required this.initialPlayersConfig,
      @required this.onPlayersUpdated})
      : this.manualTeams = _manualTeams(teamingConfig),
        this.manualOrder = _manualOrder(teamingConfig);

  @override
  createState() => _PlayersConfigViewState();
}

class _PlayerData {
  final bool isTeamDivider; // if true, other fields are meaningless
  String name;
  final Key key;
  final TextEditingController controller;
  final FocusNode focusNode;

  _PlayerData(this.name)
      : this.isTeamDivider = false,
        this.key = GlobalKey(),
        this.controller = TextEditingController(),
        this.focusNode = FocusNode();
  _PlayerData.teamDivider()
      : this.isTeamDivider = true,
        this.key = null,
        this.controller = null,
        this.focusNode = null;

  void dispose() {
    // TODO: Fix "The method 'findRenderObject' was called on null" and enable.
    // controller?.dispose();
    // focusNode?.dispose();
  }
}

// TODO: Consider making this widget stateless.
class _PlayersConfigViewState extends State<PlayersConfigView> {
  final _playerItems = <_PlayerData>[];
  final _playersToDispose = <_PlayerData>[];
  bool _freezeUpdates = true;

  get manualTeams => widget.manualTeams;
  get manualOrder => widget.manualOrder;

  void _generateInitialPlayerItems() {
    final IntermediatePlayersConfig config = widget.initialPlayersConfig;
    Assert.ne(config.teamPlayers == null, config.players == null);
    // Conversion might be required is teaming config changed.
    if (manualTeams) {
      final teamPlayers =
          (config.teamPlayers != null) ? config.teamPlayers : [config.players];
      if (teamPlayers.isNotEmpty) {
        for (final team in teamPlayers) {
          if (_playerItems.isNotEmpty) {
            _addDivider();
          }
          for (final p in team) {
            _addPlayer(p, focus: false);
          }
        }
      }
    } else {
      final players = (config.players != null)
          ? config.players
          : config.teamPlayers.expand((t) => t).toList();
      for (final p in players) {
        _addPlayer(p, focus: false);
      }
    }
  }

  void _notifyPlayersUpdate() {
    if (_freezeUpdates) {
      return;
    }
    final config = IntermediatePlayersConfig.nulls();
    if (manualTeams) {
      config.teamPlayers = [[]];
      for (final p in _playerItems) {
        if (p.isTeamDivider) {
          config.teamPlayers.add([]);
        } else {
          config.teamPlayers.last.add(p.name);
        }
      }
    } else {
      config.players = _playerItems.map((p) {
        Assert.holds(!p.isTeamDivider);
        return p.name;
      }).toList();
    }
    widget.onPlayersUpdated(config);
  }

  void _addPlayer(String name, {@required bool focus}) {
    setState(() {
      final playerData = _PlayerData(name);
      playerData.controller.text = name;
      playerData.controller.addListener(() {
        // Don't call setState, because TextField updates itself.
        playerData.name = playerData.controller.text;
        _notifyPlayersUpdate();
      });
      if (focus) {
        playerData.focusNode.requestFocus();
      }
      _playerItems.add(playerData);
    });
    _notifyPlayersUpdate();
  }

  void _addDivider() {
    _playerItems.add(_PlayerData.teamDivider());
  }

  void _deletePlayer(_PlayerData player) {
    setState(() {
      _playersToDispose.add(player);
      _playerItems.remove(player);
    });
    _notifyPlayersUpdate();
  }

  List<Widget> _makeTiles() {
    final listItemPadding = EdgeInsets.fromLTRB(10, 1, 10, 1);
    final listItemPaddingSmallRight = EdgeInsets.fromLTRB(listItemPadding.left,
        listItemPadding.top, listItemPadding.right / 2, listItemPadding.bottom);
    var tiles = <Widget>[];
    for (int i = 0; i < _playerItems.length; ++i) {
      final player = _playerItems[i];
      if (player.isTeamDivider) {
        tiles.add(
          Divider(
            key: UniqueKey(),
            color: MyTheme.accent,
            thickness: 3.0,
            height: 20.0,
          ),
        );
      } else {
        tiles.add(
          ListTile(
            key: UniqueKey(),
            contentPadding: listItemPaddingSmallRight,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  // TODO: Fix: `Multiple widgets used the same GlobalKey.'
                  child: TextField(
                    decoration:
                        InputDecoration(filled: true, border: InputBorder.none),
                    key: player.key,
                    focusNode: player.focusNode,
                    controller: player.controller,
                  ),
                ),
                // TODO: replace with up/down buttons
                if (manualOrder)
                  SizedBox(width: 12),
                // TODO: Make sure we don't have two drag handles on iOS.
                if (manualOrder)
                  Icon(Icons.drag_handle),
                SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.clear),
                  onPressed: () => _deletePlayer(player),
                ),
              ],
            ),
          ),
        );
      }
    }
    tiles.add(ListTile(
        key: UniqueKey(),
        contentPadding: listItemPadding,
        title: Row(children: [
          Expanded(
            flex: 3,
            child: OutlineButton(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              onPressed: () => setState(() {
                _addPlayer('', focus: true);
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add),
                  SizedBox(width: 8),
                  Text('Add player'),
                ],
              ),
            ),
          ),
          if (manualTeams) SizedBox(width: 12),
          if (manualTeams)
            Expanded(
              flex: 2,
              child: OutlineButton(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                onPressed: () => setState(() {
                  _addDivider();
                  _addPlayer('', focus: true);
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add),
                    SizedBox(width: 8),
                    Text('Add team'),
                  ],
                ),
              ),
            ),
        ])));
    return tiles;
  }

  @override
  void initState() {
    super.initState();
    _generateInitialPlayerItems();
    _freezeUpdates = false;
  }

  @override
  void didUpdateWidget(PlayersConfigView oldWidget) {
    for (final player in _playersToDispose) {
      player.dispose();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    for (final player in _playersToDispose + _playerItems) {
      player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onReorder = (int oldIndex, int newIndex) {
      setState(() {
        if (oldIndex >= _playerItems.length) {
          // Cannot drag the `add' button.
          // TODO: Make it impossible to start dragging the button.
          return;
        }
        if (newIndex >= _playerItems.length) {
          // Cannot drag an item below the `add' button.
          newIndex = _playerItems.length;
        }
        if (newIndex > oldIndex) {
          newIndex--;
        }
        final p = _playerItems.removeAt(oldIndex);
        _playerItems.insert(newIndex, p);
        _notifyPlayersUpdate();
      });
    };
    return Padding(
      padding: EdgeInsets.only(top: 6),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _makeTiles(),
      ),
    );
  }
}
