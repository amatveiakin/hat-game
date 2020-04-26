
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/util/assertion.dart';

class PartyViewData {
  final PlayerState performer;
  final List<PlayerState> recipients;

  PartyViewData(this.performer, this.recipients);
}

// All information about the game, read-only.
// Use GameController to influence the game.
class GameData {
  final GameConfig config;
  final GameState state;

  GameData(this.config, this.state);

  List<List<int>> teams() => state.teams?.map((t) => t.toList())?.toList();

  int numWordsInHat() => state.wordsInHat.length;

  String currentWordText() {
    Assert.eq(state.turnPhase, TurnPhase.explain);
    return state.words[state.currentWord].text;
  }

  List<Word> wordsInThisTurnData() {
    return state.wordsInThisTurn.map((wordId) => state.words[wordId]).toList();
  }

  PartyViewData currentPartyViewData() {
    return PartyViewData(state.players[state.currentParty.performer],
        state.currentParty.recipients.map((id) => state.players[id]).toList());
  }
}
