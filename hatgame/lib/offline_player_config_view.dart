import 'package:built_collection/built_collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/widget/divider.dart';

// TODO: Allow to delete teams.

class OfflinePlayersConfigView extends StatefulWidget {
  final bool manualTeams;
  final PlayersConfig? initialPlayersConfig;
  final GameConfigController configController;

  OfflinePlayersConfigView(
      {super.key,
      required TeamingConfig teamingConfig,
      required this.initialPlayersConfig,
      required this.configController})
      : manualTeams = teamingConfig.teamingStyle == TeamingStyle.manualTeams;

  @override
  createState() => _OfflinePlayersConfigViewState();
}

sealed class _ListItem {}

class _PlayerData extends _ListItem {
  String name;
  final Key key;
  final TextEditingController controller;
  final FocusNode focusNode;

  _PlayerData(this.name)
      : key = GlobalKey(),
        controller = TextEditingController(),
        focusNode = FocusNode();

  void dispose() {
    // TODO: Fix "The method 'findRenderObject' was called on null" and enable.
    // controller?.dispose();
    // focusNode?.dispose();
  }
}

class _TeamDivider extends _ListItem {}

// TODO: Consider making this widget stateless.
class _OfflinePlayersConfigViewState extends State<OfflinePlayersConfigView> {
  final _listItems = <_ListItem>[];
  final _playersToDispose = <_PlayerData>[];
  final _autoscrollStopwatch = Stopwatch();
  final _scrollController = ScrollController();
  bool _freezeUpdates = true;

  bool get manualTeams => widget.manualTeams;
  GameConfigController get configController => widget.configController;

  void _generateInitialPlayerItems() {
    final PlayersConfig config = widget.initialPlayersConfig!;
    config.checkInvariant();
    // Conversion might be required is teaming config changed.
    if (manualTeams) {
      final teams = config.teams ??
          BuiltList<BuiltList<int>>([BuiltList<int>(config.names.keys)]);
      for (final team in teams) {
        if (_listItems.isNotEmpty) {
          _addDivider();
        }
        for (final p in team) {
          _addPlayer(config.names[p]!, focus: false);
        }
      }
    } else {
      for (final p in config.names.values) {
        _addPlayer(p, focus: false);
      }
    }
  }

  void _notifyPlayersUpdate() {
    if (_freezeUpdates) {
      return;
    }

    final Map<int, String?> names = {};
    final List<List<int>> teams = [[]];
    int playerID = 0;
    for (final p in _listItems) {
      switch (p) {
        case _PlayerData():
          names[playerID] = p.name;
          teams.last.add(playerID);
          playerID++;
          break;
        case _TeamDivider():
          teams.add([]);
          break;
      }
    }

    if (manualTeams) {
      configController.updatePlayers((_) => PlayersConfig(
            (b) => b
              ..names.replace(names)
              ..teams.replace(teams.map((t) => BuiltList<int>(t))),
          ));
    } else {
      Assert.eq(teams.length, 1);
      configController.updatePlayers((_) => PlayersConfig(
            (b) => b..names.replace(names),
          ));
    }
  }

  void _addPlayer(String name, {required bool focus}) {
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
        void Function()? scrollCallback;
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
          Future.delayed(const Duration(milliseconds: 50), scrollCallback);
        };
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollCallback!());
        playerData.focusNode.requestFocus();
      }
      _listItems.add(playerData);
    });
    _notifyPlayersUpdate();
  }

  void _cancelAutoScroll() {
    _autoscrollStopwatch.stop();
  }

  void _addDivider() {
    _listItems.add(_TeamDivider());
  }

  void _deletePlayer(_PlayerData player) {
    setState(() {
      _playersToDispose.add(player);
      _listItems.remove(player);
    });
    _notifyPlayersUpdate();
  }

  List<Widget> _makeTiles() {
    const listItemPadding = EdgeInsets.fromLTRB(10, 1, 10, 1);
    final listItemPaddingSmallRight = EdgeInsets.fromLTRB(listItemPadding.left,
        listItemPadding.top, listItemPadding.right / 2, listItemPadding.bottom);
    var tiles = <Widget>[];
    for (int i = 0; i < _listItems.length; ++i) {
      final player = _listItems[i];
      final tile = switch (player) {
        _PlayerData() => ListTile(
            key: UniqueKey(),
            contentPadding: listItemPaddingSmallRight,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  // TODO: Fix: `Multiple widgets used the same GlobalKey.'
                  child: TextField(
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withAlpha(0x14),
                        border: InputBorder.none),
                    key: player.key,
                    focusNode: player.focusNode,
                    controller: player.controller,
                  ),
                ),
                if (manualTeams) const SizedBox(width: 12),
                // TODO: Make sure we don't have two drag handles on iOS.
                if (manualTeams) const Icon(Icons.drag_handle),
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.clear),
                  onPressed: () => _deletePlayer(player),
                ),
              ],
            ),
          ),
        _TeamDivider() => StyledDivider(
            key: UniqueKey(),
          ),
      };
      tiles.add(tile);
    }
    final buttonStyle = ButtonStyle(
        padding:
            WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 10.0)),
        side: WidgetStateProperty.all(
          BorderSide(
            color: Theme.of(context).primaryColor.withAlpha(0xb0),
          ),
        ));
    tiles.add(ListTile(
        key: UniqueKey(),
        contentPadding: listItemPadding,
        title: Row(children: [
          Expanded(
            flex: 3,
            child: OutlinedButton(
              style: buttonStyle,
              onPressed: () => setState(() {
                _addPlayer('', focus: true);
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add),
                  const SizedBox(width: 8),
                  Text(context.tr('add_player')),
                ],
              ),
            ),
          ),
          if (manualTeams) const SizedBox(width: 12),
          if (manualTeams)
            Expanded(
              flex: 2,
              child: OutlinedButton(
                style: buttonStyle,
                onPressed: () => setState(() {
                  _addDivider();
                  _addPlayer('', focus: true);
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_add),
                    const SizedBox(width: 8),
                    Text(context.tr('add_team')),
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
  void didUpdateWidget(OfflinePlayersConfigView oldWidget) {
    for (final player in _playersToDispose) {
      player.dispose();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    for (final player in _playersToDispose) {
      player.dispose();
    }
    for (final player in _listItems) {
      switch (player) {
        case _PlayerData():
          player.dispose();
          break;
        case _TeamDivider():
          break;
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    onReorder(int oldIndex, int newIndex) {
      setState(() {
        if (oldIndex >= _listItems.length) {
          // Cannot drag the `add' button.
          // TODO: Make it impossible to start dragging the button.
          return;
        }
        if (newIndex >= _listItems.length) {
          // Cannot drag an item below the `add' button.
          newIndex = _listItems.length;
        }
        if (newIndex > oldIndex) {
          newIndex--;
        }
        final p = _listItems.removeAt(oldIndex);
        _listItems.insert(newIndex, p);
        _notifyPlayersUpdate();
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Cancel autoscroll if the user begins to interact with the widget.
      // It seems that onTapDown is sufficient, but adding more to be sure.
      onTapDown: (_) => _cancelAutoScroll(),
      onVerticalDragDown: (_) => _cancelAutoScroll(),
      onHorizontalDragDown: (_) => _cancelAutoScroll(),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
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
