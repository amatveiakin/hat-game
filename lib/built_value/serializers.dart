library serializers;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:hatgame/built_value/game_config.dart';
import 'package:hatgame/built_value/game_state.dart';
import 'package:hatgame/built_value/personal_state.dart';

part 'serializers.g.dart';

@SerializersFor([
  GameConfig,
  GameState,
  PersonalState,
])
final Serializers serializers = _$serializers;
