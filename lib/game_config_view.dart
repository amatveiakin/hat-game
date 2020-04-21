import 'package:flutter/material.dart';
import 'package:hatgame/game_settings.dart';
import 'package:hatgame/game_view.dart';
import 'package:hatgame/player_config_view.dart';
import 'package:hatgame/teaming_config_view.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

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
  final int teamingTabIndex = 0;
  final int playersTabIndex = 1;
  final int optionsTabIndex = 2;

  final List<String> _players;
  final PlayersConfigView _playersView;
  TabController _tabController;

  _GameConfigViewState._(this._players)
      : _playersView = PlayersConfigView((List<String> newPlayers) {
          _players.clear();
          _players.addAll(newPlayers);
        });
  _GameConfigViewState() : this._([]);

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: tabs.length);
    _tabController.addListener(() {
      // Hide virtual keyboard
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

    // TODO: Use TeamingStrategy to check teaming validity.
    if (_players.length < 2 || _players.length % 2 == 1) {
      showDialog(
        context: context,
        // TODO: Add context or replace with a SnackBar.
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Invalid number of players: ${_players.length}'),
            actions: <Widget>[
              FlatButton(
                child: Text('I see'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      _tabController.animateTo(playersTabIndex);
      return;
    }

    int playerIdx = 0;
    settings.teamPlayers = [];
    for (final player in _players) {
      if (playerIdx % 2 == 0) {
        settings.teamPlayers.add([]);
      }
      settings.teamPlayers.last.add(player);
      playerIdx++;
    }
    // Hide virtual keyboard
    FocusScope.of(context).unfocus();
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
