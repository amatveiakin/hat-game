library rematch_source;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:hatgame/built_value/team_compositions.dart';

part 'rematch_source.g.dart';

abstract class RematchSource
    implements Built<RematchSource, RematchSourceBuilder> {
  String get gameID;
  TeamCompositions get teamCompositions;

  RematchSource._();
  factory RematchSource([void Function(RematchSourceBuilder) updates]) =
      _$RematchSource;
  static Serializer<RematchSource> get serializer => _$rematchSourceSerializer;
}
