// =============================================================================
// Rules

class RulesConfig {
  int explanationSeconds = 15;

  RulesConfig.dev() : explanationSeconds = 5;
}

// =============================================================================
// Teaming

enum IndividualPlayStyle {
  chain,
  fluidPairs,
  // TODO: Add "each to all" (non-competitive) mode?
}

enum DesiredTeamSize {
  teamsOf2,
  teamsOf3,
  teamsOf4,
  twoTeams,
}

enum UnequalTeamSize {
  expandTeams,
  dropPlayers,
}

enum GuessingInLargeTeam {
  oneGuesser,
  everybodyGuesser,
}

class TeamingConfig {
  bool teamPlay = true;
  bool randomizeTeams = true;
  IndividualPlayStyle individualPlayStyle = IndividualPlayStyle.fluidPairs;
  DesiredTeamSize desiredTeamSize = DesiredTeamSize.teamsOf2;
  UnequalTeamSize unequalTeamSize = UnequalTeamSize.expandTeams;
  GuessingInLargeTeam guessingInLargeTeam = GuessingInLargeTeam.oneGuesser;
}

// =============================================================================
// Players

class PlayersConfig {
  List<List<String>> teamPlayers;
}

// =============================================================================
// All together

class GameConfig {
  RulesConfig rules;
  var teaming = TeamingConfig();
  var players = PlayersConfig();

  // TODO: delete
  GameConfig();
  GameConfig.dev() : rules = RulesConfig.dev();
}
