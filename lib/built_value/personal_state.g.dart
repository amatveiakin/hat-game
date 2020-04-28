// GENERATED CODE - DO NOT MODIFY BY HAND

part of player_info;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WordFeedback _$good = const WordFeedback._('good');
const WordFeedback _$bad = const WordFeedback._('bad');
const WordFeedback _$tooEasy = const WordFeedback._('tooEasy');
const WordFeedback _$tooHard = const WordFeedback._('tooHard');

WordFeedback _$valueOfWordFeedback(String name) {
  switch (name) {
    case 'good':
      return _$good;
    case 'bad':
      return _$bad;
    case 'tooEasy':
      return _$tooEasy;
    case 'tooHard':
      return _$tooHard;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<WordFeedback> _$valuesWordFeedback =
    new BuiltSet<WordFeedback>(const <WordFeedback>[
  _$good,
  _$bad,
  _$tooEasy,
  _$tooHard,
]);

Serializer<WordFeedback> _$wordFeedbackSerializer =
    new _$WordFeedbackSerializer();
Serializer<PersonalState> _$personalStateSerializer =
    new _$PersonalStateSerializer();

class _$WordFeedbackSerializer implements PrimitiveSerializer<WordFeedback> {
  @override
  final Iterable<Type> types = const <Type>[WordFeedback];
  @override
  final String wireName = 'WordFeedback';

  @override
  Object serialize(Serializers serializers, WordFeedback object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  WordFeedback deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      WordFeedback.valueOf(serialized as String);
}

class _$PersonalStateSerializer implements StructuredSerializer<PersonalState> {
  @override
  final Iterable<Type> types = const [PersonalState, _$PersonalState];
  @override
  final String wireName = 'PersonalState';

  @override
  Iterable<Object> serialize(Serializers serializers, PersonalState object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(int)),
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'wordFeedback',
      serializers.serialize(object.wordFeedback,
          specifiedType: const FullType(BuiltMap,
              const [const FullType(int), const FullType(WordFeedback)])),
      'wordFlags',
      serializers.serialize(object.wordFlags,
          specifiedType: const FullType(BuiltSet, const [const FullType(int)])),
    ];

    return result;
  }

  @override
  PersonalState deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PersonalStateBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'name':
          result.name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'wordFeedback':
          result.wordFeedback.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltMap,
                  const [const FullType(int), const FullType(WordFeedback)])));
          break;
        case 'wordFlags':
          result.wordFlags.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltSet, const [const FullType(int)]))
              as BuiltSet<Object>);
          break;
      }
    }

    return result.build();
  }
}

class _$PersonalState extends PersonalState {
  @override
  final int id;
  @override
  final String name;
  @override
  final BuiltMap<int, WordFeedback> wordFeedback;
  @override
  final BuiltSet<int> wordFlags;

  factory _$PersonalState([void Function(PersonalStateBuilder) updates]) =>
      (new PersonalStateBuilder()..update(updates)).build();

  _$PersonalState._({this.id, this.name, this.wordFeedback, this.wordFlags})
      : super._() {
    if (id == null) {
      throw new BuiltValueNullFieldError('PersonalState', 'id');
    }
    if (name == null) {
      throw new BuiltValueNullFieldError('PersonalState', 'name');
    }
    if (wordFeedback == null) {
      throw new BuiltValueNullFieldError('PersonalState', 'wordFeedback');
    }
    if (wordFlags == null) {
      throw new BuiltValueNullFieldError('PersonalState', 'wordFlags');
    }
  }

  @override
  PersonalState rebuild(void Function(PersonalStateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PersonalStateBuilder toBuilder() => new PersonalStateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PersonalState &&
        id == other.id &&
        name == other.name &&
        wordFeedback == other.wordFeedback &&
        wordFlags == other.wordFlags;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, id.hashCode), name.hashCode), wordFeedback.hashCode),
        wordFlags.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PersonalState')
          ..add('id', id)
          ..add('name', name)
          ..add('wordFeedback', wordFeedback)
          ..add('wordFlags', wordFlags))
        .toString();
  }
}

class PersonalStateBuilder
    implements Builder<PersonalState, PersonalStateBuilder> {
  _$PersonalState _$v;

  int _id;
  int get id => _$this._id;
  set id(int id) => _$this._id = id;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  MapBuilder<int, WordFeedback> _wordFeedback;
  MapBuilder<int, WordFeedback> get wordFeedback =>
      _$this._wordFeedback ??= new MapBuilder<int, WordFeedback>();
  set wordFeedback(MapBuilder<int, WordFeedback> wordFeedback) =>
      _$this._wordFeedback = wordFeedback;

  SetBuilder<int> _wordFlags;
  SetBuilder<int> get wordFlags => _$this._wordFlags ??= new SetBuilder<int>();
  set wordFlags(SetBuilder<int> wordFlags) => _$this._wordFlags = wordFlags;

  PersonalStateBuilder();

  PersonalStateBuilder get _$this {
    if (_$v != null) {
      _id = _$v.id;
      _name = _$v.name;
      _wordFeedback = _$v.wordFeedback?.toBuilder();
      _wordFlags = _$v.wordFlags?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PersonalState other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PersonalState;
  }

  @override
  void update(void Function(PersonalStateBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PersonalState build() {
    _$PersonalState _$result;
    try {
      _$result = _$v ??
          new _$PersonalState._(
              id: id,
              name: name,
              wordFeedback: wordFeedback.build(),
              wordFlags: wordFlags.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'wordFeedback';
        wordFeedback.build();
        _$failedField = 'wordFlags';
        wordFlags.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'PersonalState', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
