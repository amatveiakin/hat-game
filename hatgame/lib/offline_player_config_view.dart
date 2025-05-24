import 'package:built_collection/built_collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/game_config_controller.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/widget_state_property.dart';
import 'package:hatgame/widget/divider.dart';

class OfflinePlayersConfigView extends StatefulWidget {
  final bool manualTeams;
  final PlayersConfig initialPlayersConfig;
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
  final _scrollController = ScrollController();
  late bool _wasManualTeams;
  bool _freezeUpdates = false;

  bool get manualTeams => widget.manualTeams;
  GameConfigController get configController => widget.configController;

  // Assumption: already in `setState`.
  void _updatePlayerItemsFromConfig() {
    _freezeUpdates = true;
    final PlayersConfig config = widget.initialPlayersConfig;
    config.checkInvariant();
    _listItems.clear();
    if (manualTeams) {
      final teams = config.teams!;
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
    _wasManualTeams = manualTeams;
    _deleteEmptyTeams();
    _freezeUpdates = false;
  }

  void _notifyPlayersUpdate() {
    if (_freezeUpdates) {
      return;
    }

    final Map<int, String?> names = {};
    final List<List<int>> teams = [[]];
    int playerID = 0;
    for (final item in _listItems) {
      switch (item) {
        case _PlayerData(:final name):
          names[playerID] = name;
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
            (b) => b
              ..names.replace(names)
              ..teams = null,
          ));
    }
  }

  // Assumption: already in `setState`.
  void _addPlayer(String name, {required bool focus}) {
    final playerData = _PlayerData(name);
    playerData.controller.text = name;
    playerData.controller.addListener(() {
      // Don't call setState, because TextField updates itself.
      playerData.name = playerData.controller.text;
      _notifyPlayersUpdate();
    });
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        // Request focus after a short delay to ensure scroll completes
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && playerData.focusNode.canRequestFocus) {
            playerData.focusNode.requestFocus();
          }
        });
      });
    }
    _listItems.add(playerData);
    _notifyPlayersUpdate();
  }

  void _addDivider() {
    _listItems.add(_TeamDivider());
  }

  // Assumption: already in `setState`.
  void _deletePlayer(_PlayerData player) {
    _playersToDispose.add(player);
    _listItems.remove(player);
    _deleteEmptyTeams();
    _notifyPlayersUpdate();
  }

  // Assumption: already in `setState`.
  void _deleteEmptyTeams() {
    var newTeam = true;
    _listItems.removeWhere((item) {
      final isDivider = item is _TeamDivider;
      final remove = newTeam && isDivider;
      newTeam = isDivider;
      return remove;
    });
    if (_listItems.isNotEmpty && _listItems.last is _TeamDivider) {
      _listItems.removeLast();
    }
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
                  onPressed: () => setState(() {
                    _deletePlayer(player);
                  }),
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
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: greyOutDisabled(
                states, Theme.of(context).primaryColor.withAlpha(0xb0)),
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
              onPressed: manualTeams && _listItems.isEmpty
                  ? null
                  : () => setState(() {
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
                  _deleteEmptyTeams();
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
    _updatePlayerItemsFromConfig();
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
    for (final item in _listItems) {
      switch (item) {
        case _PlayerData():
          item.dispose();
          break;
        case _TeamDivider():
          break;
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Always keep it in sync with the player config (not just when
    // `manualTeams` changes), like `updateFromConfig` does for the rules and
    // teaming configs.
    if (manualTeams != _wasManualTeams) {
      setState(() {
        _updatePlayerItemsFromConfig();
      });
    }

    void onReorder(int oldIndex, int newIndex) {
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
        _deleteEmptyTeams();
      });
      _notifyPlayersUpdate();
    }

    return Padding(
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
    );
  }
}
