// =============================================================================
// Rules

class RulesConfig {
  int turnSeconds = 15;
  int bonusSeconds = 5;

  RulesConfig.dev() : turnSeconds = 5, bonusSeconds = 2;
}

// =============================================================================
// Teaming

enum IndividualPlayStyle {
  chain,
  fluidPairs,
  broadcast,  // TODO: Expose "each to all" (non-competitive) mode publicly (?)
}

enum DesiredTeamSize {
  teamsOf2,
  teamsOf3,
  teamsOf4,
  twoTeams,
}

enum UnequalTeamSize {
  forbid,
  expandTeams,
  dropPlayers,
}

class TeamingConfig {
  bool teamPlay = true;
  bool randomizeTeams = true;
  IndividualPlayStyle individualPlayStyle = IndividualPlayStyle.fluidPairs;
  DesiredTeamSize desiredTeamSize = DesiredTeamSize.teamsOf2;
  UnequalTeamSize unequalTeamSize = UnequalTeamSize.forbid;
  IndividualPlayStyle guessingInLargeTeam = IndividualPlayStyle.fluidPairs;
}

// =============================================================================
// Players

class PlayersConfig {
  // Exactly one of `names` and `namesByTeam` must be set.
  List<String> names;
  List<List<String>> namesByTeam;
}

// =============================================================================
// All together

class GameConfig {
  RulesConfig rules;
  var teaming = TeamingConfig();
  var players = PlayersConfig();
}
