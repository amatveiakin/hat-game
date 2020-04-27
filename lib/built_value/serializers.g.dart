// GENERATED CODE - DO NOT MODIFY BY HAND

part of serializers;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (new Serializers().toBuilder()
      ..add(DesiredTeamSize.serializer)
      ..add(GameConfig.serializer)
      ..add(GameState.serializer)
      ..add(IndividualPlayStyle.serializer)
      ..add(Party.serializer)
      ..add(PlayerState.serializer)
      ..add(PlayersConfig.serializer)
      ..add(RulesConfig.serializer)
      ..add(TeamingConfig.serializer)
      ..add(TurnPhase.serializer)
      ..add(UnequalTeamSize.serializer)
      ..add(Word.serializer)
      ..add(WordFeedback.serializer)
      ..add(WordStatus.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlayerState)]),
          () => new ListBuilder<PlayerState>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => new ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [
            const FullType(BuiltList, const [const FullType(int)])
          ]),
          () => new ListBuilder<BuiltList<int>>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Word)]),
          () => new ListBuilder<Word>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => new ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => new ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => new ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => new ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => new ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(int), const FullType(String)]),
          () => new MapBuilder<int, String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [
            const FullType(BuiltList, const [const FullType(int)])
          ]),
          () => new ListBuilder<BuiltList<int>>()))
    .build();

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
