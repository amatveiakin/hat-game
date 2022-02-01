library team_compositions;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'team_compositions.g.dart';

abstract class TeamCompositions
    implements Built<TeamCompositions, TeamCompositionsBuilder> {
  // Exactly one of `individualOrder` and `teams` must be set.
  BuiltList<int>? get individualOrder;
  // == PlayersConfig.teams, but teams and players within a team are shuffled.
  BuiltList<BuiltList<int>>? get teams;

  TeamCompositions._();
  factory TeamCompositions([void Function(TeamCompositionsBuilder) updates]) =
      _$TeamCompositions;
  static Serializer<TeamCompositions> get serializer =>
      _$teamCompositionsSerializer;
}
