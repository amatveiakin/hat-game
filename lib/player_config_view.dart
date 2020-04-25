import 'package:built_collection/built_collection.dart';
import 'package:hatgame/assertion.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/theme.dart';
import 'package:flutter/material.dart';

// TODO: Allow to delete teams.

bool _manualTeams(TeamingConfig teamingConfig) {
  return teamingConfig.teamPlay && !teamingConfig.randomizeTeams;
}

class PlayersConfigView extends StatefulWidget {
  final bool manualTeams;
  final PlayersConfig initialPlayersConfig;
  final GameConfigController configController;

  PlayersConfigView(
      {@required teamingConfig,
      @required this.initialPlayersConfig,
      @required this.configController})
      : this.manualTeams = _manualTeams(teamingConfig);

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
  final _autoscrollStopwatch = Stopwatch();
  final _scrollController = ScrollController();
  bool _freezeUpdates = true;

  bool get manualTeams => widget.manualTeams;
  GameConfigController get configController => widget.configController;

  void _generateInitialPlayerItems() {
    final PlayersConfig config = widget.initialPlayersConfig;
    Assert.ne(config.namesByTeam == null, config.names == null);
    // Conversion might be required is teaming config changed.
    if (manualTeams) {
      final teamPlayers =
          (config.namesByTeam != null) ? config.namesByTeam : [config.names];
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
      final players = (config.names != null)
          ? config.names
          : config.namesByTeam.expand((t) => t).toList();
      for (final p in players) {
        _addPlayer(p, focus: false);
      }
    }
  }

  void _notifyPlayersUpdate() {
    if (_freezeUpdates) {
      return;
    }
    if (manualTeams) {
      List<List<String>> namesByTeam = [[]];
      for (final p in _playerItems) {
        if (p.isTeamDivider) {
          namesByTeam.add([]);
        } else {
          namesByTeam.last.add(p.name);
        }
      }
      configController.updatePlayers(PlayersConfig(
        (b) => b
          ..namesByTeam.replace(namesByTeam.map((t) => BuiltList<String>(t))),
      ));
    } else {
      configController.updatePlayers(PlayersConfig(
        (b) => b
          ..names.replace(_playerItems.map((p) {
            Assert.holds(!p.isTeamDivider);
            return p.name;
          })),
      ));
    }
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
        // TODO: Why does it scroll far below the end of the list on my phone
        // (not on emulator)?
        _autoscrollStopwatch.reset();
        _autoscrollStopwatch.start();
        void Function() scrollCallback;
        scrollCallback = () {
          if (!_autoscrollStopwatch.isRunning ||
              _autoscrollStopwatch.elapsedMilliseconds > 1000) {
            _autoscrollStopwatch.stop();
            return;
          }
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut);
          // Check again, because it doesn't always work immediately,
          // especially when virtual keyboard is opened.
          // TODO: Find a better way to do this.
          Future.delayed(Duration(milliseconds: 50), scrollCallback);
        };
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollCallback());
        playerData.focusNode.requestFocus();
      }
      _playerItems.add(playerData);
    });
    _notifyPlayersUpdate();
  }

  void _cancelAutoScroll() {
    _autoscrollStopwatch.stop();
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
                if (manualTeams)
                  SizedBox(width: 12),
                // TODO: Make sure we don't have two drag handles on iOS.
                if (manualTeams)
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Cancel autoscroll if the user begins to interact with the widget.
      // It seems that onTapDown is sufficient, but adding more to be sure.
      onTapDown: (_) => _cancelAutoScroll(),
      onVerticalDragDown: (_) => _cancelAutoScroll(),
      onHorizontalDragDown: (_) => _cancelAutoScroll(),
      child: Padding(
        padding: EdgeInsets.only(top: 6),
        child: manualTeams
            ? ReorderableListView(
                onReorder: onReorder,
                scrollController: _scrollController,
                children: _makeTiles(),
              )
            : ListView(
                controller: _scrollController,
                children: _makeTiles(),
              ),
      ),
    );
  }
}
