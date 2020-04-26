// GENERATED CODE - DO NOT MODIFY BY HAND

part of game_config;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const IndividualPlayStyle _$chain = const IndividualPlayStyle._('chain');
const IndividualPlayStyle _$fluidPairs =
    const IndividualPlayStyle._('fluidPairs');
const IndividualPlayStyle _$broadcast =
    const IndividualPlayStyle._('broadcast');

IndividualPlayStyle _$valueOfIndividualPlayStyle(String name) {
  switch (name) {
    case 'chain':
      return _$chain;
    case 'fluidPairs':
      return _$fluidPairs;
    case 'broadcast':
      return _$broadcast;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<IndividualPlayStyle> _$valuesIndividualPlayStyle =
    new BuiltSet<IndividualPlayStyle>(const <IndividualPlayStyle>[
  _$chain,
  _$fluidPairs,
  _$broadcast,
]);

const DesiredTeamSize _$teamsOf2 = const DesiredTeamSize._('teamsOf2');
const DesiredTeamSize _$teamsOf3 = const DesiredTeamSize._('teamsOf3');
const DesiredTeamSize _$teamsOf4 = const DesiredTeamSize._('teamsOf4');
const DesiredTeamSize _$twoTeams = const DesiredTeamSize._('twoTeams');

DesiredTeamSize _$valueOfDesiredTeamSize(String name) {
  switch (name) {
    case 'teamsOf2':
      return _$teamsOf2;
    case 'teamsOf3':
      return _$teamsOf3;
    case 'teamsOf4':
      return _$teamsOf4;
    case 'twoTeams':
      return _$twoTeams;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<DesiredTeamSize> _$valuesDesiredTeamSize =
    new BuiltSet<DesiredTeamSize>(const <DesiredTeamSize>[
  _$teamsOf2,
  _$teamsOf3,
  _$teamsOf4,
  _$twoTeams,
]);

const UnequalTeamSize _$forbid = const UnequalTeamSize._('forbid');
const UnequalTeamSize _$expandTeams = const UnequalTeamSize._('expandTeams');
const UnequalTeamSize _$dropPlayers = const UnequalTeamSize._('dropPlayers');

UnequalTeamSize _$valueOfUnequalTeamSize(String name) {
  switch (name) {
    case 'forbid':
      return _$forbid;
    case 'expandTeams':
      return _$expandTeams;
    case 'dropPlayers':
      return _$dropPlayers;
    default:
      throw new ArgumentError(name);
  }
}

final BuiltSet<UnequalTeamSize> _$valuesUnequalTeamSize =
    new BuiltSet<UnequalTeamSize>(const <UnequalTeamSize>[
  _$forbid,
  _$expandTeams,
  _$dropPlayers,
]);

Serializer<RulesConfig> _$rulesConfigSerializer = new _$RulesConfigSerializer();
Serializer<IndividualPlayStyle> _$individualPlayStyleSerializer =
    new _$IndividualPlayStyleSerializer();
Serializer<DesiredTeamSize> _$desiredTeamSizeSerializer =
    new _$DesiredTeamSizeSerializer();
Serializer<UnequalTeamSize> _$unequalTeamSizeSerializer =
    new _$UnequalTeamSizeSerializer();
Serializer<TeamingConfig> _$teamingConfigSerializer =
    new _$TeamingConfigSerializer();
Serializer<PlayersConfig> _$playersConfigSerializer =
    new _$PlayersConfigSerializer();
Serializer<GameConfig> _$gameConfigSerializer = new _$GameConfigSerializer();

class _$RulesConfigSerializer implements StructuredSerializer<RulesConfig> {
  @override
  final Iterable<Type> types = const [RulesConfig, _$RulesConfig];
  @override
  final String wireName = 'RulesConfig';

  @override
  Iterable<Object> serialize(Serializers serializers, RulesConfig object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'turnSeconds',
      serializers.serialize(object.turnSeconds,
          specifiedType: const FullType(int)),
      'bonusSeconds',
      serializers.serialize(object.bonusSeconds,
          specifiedType: const FullType(int)),
      'wordsPerPlayer',
      serializers.serialize(object.wordsPerPlayer,
          specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  RulesConfig deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new RulesConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'turnSeconds':
          result.turnSeconds = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'bonusSeconds':
          result.bonusSeconds = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
        case 'wordsPerPlayer':
          result.wordsPerPlayer = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int;
          break;
      }
    }

    return result.build();
  }
}

class _$IndividualPlayStyleSerializer
    implements PrimitiveSerializer<IndividualPlayStyle> {
  @override
  final Iterable<Type> types = const <Type>[IndividualPlayStyle];
  @override
  final String wireName = 'IndividualPlayStyle';

  @override
  Object serialize(Serializers serializers, IndividualPlayStyle object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  IndividualPlayStyle deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      IndividualPlayStyle.valueOf(serialized as String);
}

class _$DesiredTeamSizeSerializer
    implements PrimitiveSerializer<DesiredTeamSize> {
  @override
  final Iterable<Type> types = const <Type>[DesiredTeamSize];
  @override
  final String wireName = 'DesiredTeamSize';

  @override
  Object serialize(Serializers serializers, DesiredTeamSize object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  DesiredTeamSize deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      DesiredTeamSize.valueOf(serialized as String);
}

class _$UnequalTeamSizeSerializer
    implements PrimitiveSerializer<UnequalTeamSize> {
  @override
  final Iterable<Type> types = const <Type>[UnequalTeamSize];
  @override
  final String wireName = 'UnequalTeamSize';

  @override
  Object serialize(Serializers serializers, UnequalTeamSize object,
          {FullType specifiedType = FullType.unspecified}) =>
      object.name;

  @override
  UnequalTeamSize deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      UnequalTeamSize.valueOf(serialized as String);
}

class _$TeamingConfigSerializer implements StructuredSerializer<TeamingConfig> {
  @override
  final Iterable<Type> types = const [TeamingConfig, _$TeamingConfig];
  @override
  final String wireName = 'TeamingConfig';

  @override
  Iterable<Object> serialize(Serializers serializers, TeamingConfig object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'teamPlay',
      serializers.serialize(object.teamPlay,
          specifiedType: const FullType(bool)),
      'randomizeTeams',
      serializers.serialize(object.randomizeTeams,
          specifiedType: const FullType(bool)),
      'individualPlayStyle',
      serializers.serialize(object.individualPlayStyle,
          specifiedType: const FullType(IndividualPlayStyle)),
      'desiredTeamSize',
      serializers.serialize(object.desiredTeamSize,
          specifiedType: const FullType(DesiredTeamSize)),
      'unequalTeamSize',
      serializers.serialize(object.unequalTeamSize,
          specifiedType: const FullType(UnequalTeamSize)),
      'guessingInLargeTeam',
      serializers.serialize(object.guessingInLargeTeam,
          specifiedType: const FullType(IndividualPlayStyle)),
    ];

    return result;
  }

  @override
  TeamingConfig deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new TeamingConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'teamPlay':
          result.teamPlay = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'randomizeTeams':
          result.randomizeTeams = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool;
          break;
        case 'individualPlayStyle':
          result.individualPlayStyle = serializers.deserialize(value,
                  specifiedType: const FullType(IndividualPlayStyle))
              as IndividualPlayStyle;
          break;
        case 'desiredTeamSize':
          result.desiredTeamSize = serializers.deserialize(value,
                  specifiedType: const FullType(DesiredTeamSize))
              as DesiredTeamSize;
          break;
        case 'unequalTeamSize':
          result.unequalTeamSize = serializers.deserialize(value,
                  specifiedType: const FullType(UnequalTeamSize))
              as UnequalTeamSize;
          break;
        case 'guessingInLargeTeam':
          result.guessingInLargeTeam = serializers.deserialize(value,
                  specifiedType: const FullType(IndividualPlayStyle))
              as IndividualPlayStyle;
          break;
      }
    }

    return result.build();
  }
}

class _$PlayersConfigSerializer implements StructuredSerializer<PlayersConfig> {
  @override
  final Iterable<Type> types = const [PlayersConfig, _$PlayersConfig];
  @override
  final String wireName = 'PlayersConfig';

  @override
  Iterable<Object> serialize(Serializers serializers, PlayersConfig object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[];
    if (object.names != null) {
      result
        ..add('names')
        ..add(serializers.serialize(object.names,
            specifiedType:
                const FullType(BuiltList, const [const FullType(String)])));
    }
    if (object.namesByTeam != null) {
      result
        ..add('namesByTeam')
        ..add(serializers.serialize(object.namesByTeam,
            specifiedType: const FullType(BuiltList, const [
              const FullType(BuiltList, const [const FullType(String)])
            ])));
    }
    return result;
  }

  @override
  PlayersConfig deserialize(
      Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new PlayersConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'names':
          result.names.replace(serializers.deserialize(value,
                  specifiedType:
                      const FullType(BuiltList, const [const FullType(String)]))
              as BuiltList<Object>);
          break;
        case 'namesByTeam':
          result.namesByTeam.replace(serializers.deserialize(value,
              specifiedType: const FullType(BuiltList, const [
                const FullType(BuiltList, const [const FullType(String)])
              ])) as BuiltList<Object>);
          break;
      }
    }

    return result.build();
  }
}

class _$GameConfigSerializer implements StructuredSerializer<GameConfig> {
  @override
  final Iterable<Type> types = const [GameConfig, _$GameConfig];
  @override
  final String wireName = 'GameConfig';

  @override
  Iterable<Object> serialize(Serializers serializers, GameConfig object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'rules',
      serializers.serialize(object.rules,
          specifiedType: const FullType(RulesConfig)),
      'teaming',
      serializers.serialize(object.teaming,
          specifiedType: const FullType(TeamingConfig)),
      'players',
      serializers.serialize(object.players,
          specifiedType: const FullType(PlayersConfig)),
    ];

    return result;
  }

  @override
  GameConfig deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new GameConfigBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'rules':
          result.rules.replace(serializers.deserialize(value,
              specifiedType: const FullType(RulesConfig)) as RulesConfig);
          break;
        case 'teaming':
          result.teaming.replace(serializers.deserialize(value,
              specifiedType: const FullType(TeamingConfig)) as TeamingConfig);
          break;
        case 'players':
          result.players.replace(serializers.deserialize(value,
              specifiedType: const FullType(PlayersConfig)) as PlayersConfig);
          break;
      }
    }

    return result.build();
  }
}

class _$RulesConfig extends RulesConfig {
  @override
  final int turnSeconds;
  @override
  final int bonusSeconds;
  @override
  final int wordsPerPlayer;

  factory _$RulesConfig([void Function(RulesConfigBuilder) updates]) =>
      (new RulesConfigBuilder()..update(updates)).build();

  _$RulesConfig._({this.turnSeconds, this.bonusSeconds, this.wordsPerPlayer})
      : super._() {
    if (turnSeconds == null) {
      throw new BuiltValueNullFieldError('RulesConfig', 'turnSeconds');
    }
    if (bonusSeconds == null) {
      throw new BuiltValueNullFieldError('RulesConfig', 'bonusSeconds');
    }
    if (wordsPerPlayer == null) {
      throw new BuiltValueNullFieldError('RulesConfig', 'wordsPerPlayer');
    }
  }

  @override
  RulesConfig rebuild(void Function(RulesConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RulesConfigBuilder toBuilder() => new RulesConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RulesConfig &&
        turnSeconds == other.turnSeconds &&
        bonusSeconds == other.bonusSeconds &&
        wordsPerPlayer == other.wordsPerPlayer;
  }

  @override
  int get hashCode {
    return $jf($jc($jc($jc(0, turnSeconds.hashCode), bonusSeconds.hashCode),
        wordsPerPlayer.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('RulesConfig')
          ..add('turnSeconds', turnSeconds)
          ..add('bonusSeconds', bonusSeconds)
          ..add('wordsPerPlayer', wordsPerPlayer))
        .toString();
  }
}

class RulesConfigBuilder implements Builder<RulesConfig, RulesConfigBuilder> {
  _$RulesConfig _$v;

  int _turnSeconds;
  int get turnSeconds => _$this._turnSeconds;
  set turnSeconds(int turnSeconds) => _$this._turnSeconds = turnSeconds;

  int _bonusSeconds;
  int get bonusSeconds => _$this._bonusSeconds;
  set bonusSeconds(int bonusSeconds) => _$this._bonusSeconds = bonusSeconds;

  int _wordsPerPlayer;
  int get wordsPerPlayer => _$this._wordsPerPlayer;
  set wordsPerPlayer(int wordsPerPlayer) =>
      _$this._wordsPerPlayer = wordsPerPlayer;

  RulesConfigBuilder();

  RulesConfigBuilder get _$this {
    if (_$v != null) {
      _turnSeconds = _$v.turnSeconds;
      _bonusSeconds = _$v.bonusSeconds;
      _wordsPerPlayer = _$v.wordsPerPlayer;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RulesConfig other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$RulesConfig;
  }

  @override
  void update(void Function(RulesConfigBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$RulesConfig build() {
    final _$result = _$v ??
        new _$RulesConfig._(
            turnSeconds: turnSeconds,
            bonusSeconds: bonusSeconds,
            wordsPerPlayer: wordsPerPlayer);
    replace(_$result);
    return _$result;
  }
}

class _$TeamingConfig extends TeamingConfig {
  @override
  final bool teamPlay;
  @override
  final bool randomizeTeams;
  @override
  final IndividualPlayStyle individualPlayStyle;
  @override
  final DesiredTeamSize desiredTeamSize;
  @override
  final UnequalTeamSize unequalTeamSize;
  @override
  final IndividualPlayStyle guessingInLargeTeam;

  factory _$TeamingConfig([void Function(TeamingConfigBuilder) updates]) =>
      (new TeamingConfigBuilder()..update(updates)).build();

  _$TeamingConfig._(
      {this.teamPlay,
      this.randomizeTeams,
      this.individualPlayStyle,
      this.desiredTeamSize,
      this.unequalTeamSize,
      this.guessingInLargeTeam})
      : super._() {
    if (teamPlay == null) {
      throw new BuiltValueNullFieldError('TeamingConfig', 'teamPlay');
    }
    if (randomizeTeams == null) {
      throw new BuiltValueNullFieldError('TeamingConfig', 'randomizeTeams');
    }
    if (individualPlayStyle == null) {
      throw new BuiltValueNullFieldError(
          'TeamingConfig', 'individualPlayStyle');
    }
    if (desiredTeamSize == null) {
      throw new BuiltValueNullFieldError('TeamingConfig', 'desiredTeamSize');
    }
    if (unequalTeamSize == null) {
      throw new BuiltValueNullFieldError('TeamingConfig', 'unequalTeamSize');
    }
    if (guessingInLargeTeam == null) {
      throw new BuiltValueNullFieldError(
          'TeamingConfig', 'guessingInLargeTeam');
    }
  }

  @override
  TeamingConfig rebuild(void Function(TeamingConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TeamingConfigBuilder toBuilder() => new TeamingConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TeamingConfig &&
        teamPlay == other.teamPlay &&
        randomizeTeams == other.randomizeTeams &&
        individualPlayStyle == other.individualPlayStyle &&
        desiredTeamSize == other.desiredTeamSize &&
        unequalTeamSize == other.unequalTeamSize &&
        guessingInLargeTeam == other.guessingInLargeTeam;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc($jc($jc(0, teamPlay.hashCode), randomizeTeams.hashCode),
                    individualPlayStyle.hashCode),
                desiredTeamSize.hashCode),
            unequalTeamSize.hashCode),
        guessingInLargeTeam.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('TeamingConfig')
          ..add('teamPlay', teamPlay)
          ..add('randomizeTeams', randomizeTeams)
          ..add('individualPlayStyle', individualPlayStyle)
          ..add('desiredTeamSize', desiredTeamSize)
          ..add('unequalTeamSize', unequalTeamSize)
          ..add('guessingInLargeTeam', guessingInLargeTeam))
        .toString();
  }
}

class TeamingConfigBuilder
    implements Builder<TeamingConfig, TeamingConfigBuilder> {
  _$TeamingConfig _$v;

  bool _teamPlay;
  bool get teamPlay => _$this._teamPlay;
  set teamPlay(bool teamPlay) => _$this._teamPlay = teamPlay;

  bool _randomizeTeams;
  bool get randomizeTeams => _$this._randomizeTeams;
  set randomizeTeams(bool randomizeTeams) =>
      _$this._randomizeTeams = randomizeTeams;

  IndividualPlayStyle _individualPlayStyle;
  IndividualPlayStyle get individualPlayStyle => _$this._individualPlayStyle;
  set individualPlayStyle(IndividualPlayStyle individualPlayStyle) =>
      _$this._individualPlayStyle = individualPlayStyle;

  DesiredTeamSize _desiredTeamSize;
  DesiredTeamSize get desiredTeamSize => _$this._desiredTeamSize;
  set desiredTeamSize(DesiredTeamSize desiredTeamSize) =>
      _$this._desiredTeamSize = desiredTeamSize;

  UnequalTeamSize _unequalTeamSize;
  UnequalTeamSize get unequalTeamSize => _$this._unequalTeamSize;
  set unequalTeamSize(UnequalTeamSize unequalTeamSize) =>
      _$this._unequalTeamSize = unequalTeamSize;

  IndividualPlayStyle _guessingInLargeTeam;
  IndividualPlayStyle get guessingInLargeTeam => _$this._guessingInLargeTeam;
  set guessingInLargeTeam(IndividualPlayStyle guessingInLargeTeam) =>
      _$this._guessingInLargeTeam = guessingInLargeTeam;

  TeamingConfigBuilder();

  TeamingConfigBuilder get _$this {
    if (_$v != null) {
      _teamPlay = _$v.teamPlay;
      _randomizeTeams = _$v.randomizeTeams;
      _individualPlayStyle = _$v.individualPlayStyle;
      _desiredTeamSize = _$v.desiredTeamSize;
      _unequalTeamSize = _$v.unequalTeamSize;
      _guessingInLargeTeam = _$v.guessingInLargeTeam;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TeamingConfig other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$TeamingConfig;
  }

  @override
  void update(void Function(TeamingConfigBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$TeamingConfig build() {
    final _$result = _$v ??
        new _$TeamingConfig._(
            teamPlay: teamPlay,
            randomizeTeams: randomizeTeams,
            individualPlayStyle: individualPlayStyle,
            desiredTeamSize: desiredTeamSize,
            unequalTeamSize: unequalTeamSize,
            guessingInLargeTeam: guessingInLargeTeam);
    replace(_$result);
    return _$result;
  }
}

class _$PlayersConfig extends PlayersConfig {
  @override
  final BuiltList<String> names;
  @override
  final BuiltList<BuiltList<String>> namesByTeam;

  factory _$PlayersConfig([void Function(PlayersConfigBuilder) updates]) =>
      (new PlayersConfigBuilder()..update(updates)).build();

  _$PlayersConfig._({this.names, this.namesByTeam}) : super._();

  @override
  PlayersConfig rebuild(void Function(PlayersConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlayersConfigBuilder toBuilder() => new PlayersConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlayersConfig &&
        names == other.names &&
        namesByTeam == other.namesByTeam;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, names.hashCode), namesByTeam.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('PlayersConfig')
          ..add('names', names)
          ..add('namesByTeam', namesByTeam))
        .toString();
  }
}

class PlayersConfigBuilder
    implements Builder<PlayersConfig, PlayersConfigBuilder> {
  _$PlayersConfig _$v;

  ListBuilder<String> _names;
  ListBuilder<String> get names => _$this._names ??= new ListBuilder<String>();
  set names(ListBuilder<String> names) => _$this._names = names;

  ListBuilder<BuiltList<String>> _namesByTeam;
  ListBuilder<BuiltList<String>> get namesByTeam =>
      _$this._namesByTeam ??= new ListBuilder<BuiltList<String>>();
  set namesByTeam(ListBuilder<BuiltList<String>> namesByTeam) =>
      _$this._namesByTeam = namesByTeam;

  PlayersConfigBuilder();

  PlayersConfigBuilder get _$this {
    if (_$v != null) {
      _names = _$v.names?.toBuilder();
      _namesByTeam = _$v.namesByTeam?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlayersConfig other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$PlayersConfig;
  }

  @override
  void update(void Function(PlayersConfigBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$PlayersConfig build() {
    _$PlayersConfig _$result;
    try {
      _$result = _$v ??
          new _$PlayersConfig._(
              names: _names?.build(), namesByTeam: _namesByTeam?.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'names';
        _names?.build();
        _$failedField = 'namesByTeam';
        _namesByTeam?.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'PlayersConfig', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$GameConfig extends GameConfig {
  @override
  final RulesConfig rules;
  @override
  final TeamingConfig teaming;
  @override
  final PlayersConfig players;

  factory _$GameConfig([void Function(GameConfigBuilder) updates]) =>
      (new GameConfigBuilder()..update(updates)).build();

  _$GameConfig._({this.rules, this.teaming, this.players}) : super._() {
    if (rules == null) {
      throw new BuiltValueNullFieldError('GameConfig', 'rules');
    }
    if (teaming == null) {
      throw new BuiltValueNullFieldError('GameConfig', 'teaming');
    }
    if (players == null) {
      throw new BuiltValueNullFieldError('GameConfig', 'players');
    }
  }

  @override
  GameConfig rebuild(void Function(GameConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GameConfigBuilder toBuilder() => new GameConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GameConfig &&
        rules == other.rules &&
        teaming == other.teaming &&
        players == other.players;
  }

  @override
  int get hashCode {
    return $jf(
        $jc($jc($jc(0, rules.hashCode), teaming.hashCode), players.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('GameConfig')
          ..add('rules', rules)
          ..add('teaming', teaming)
          ..add('players', players))
        .toString();
  }
}

class GameConfigBuilder implements Builder<GameConfig, GameConfigBuilder> {
  _$GameConfig _$v;

  RulesConfigBuilder _rules;
  RulesConfigBuilder get rules => _$this._rules ??= new RulesConfigBuilder();
  set rules(RulesConfigBuilder rules) => _$this._rules = rules;

  TeamingConfigBuilder _teaming;
  TeamingConfigBuilder get teaming =>
      _$this._teaming ??= new TeamingConfigBuilder();
  set teaming(TeamingConfigBuilder teaming) => _$this._teaming = teaming;

  PlayersConfigBuilder _players;
  PlayersConfigBuilder get players =>
      _$this._players ??= new PlayersConfigBuilder();
  set players(PlayersConfigBuilder players) => _$this._players = players;

  GameConfigBuilder();

  GameConfigBuilder get _$this {
    if (_$v != null) {
      _rules = _$v.rules?.toBuilder();
      _teaming = _$v.teaming?.toBuilder();
      _players = _$v.players?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GameConfig other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$GameConfig;
  }

  @override
  void update(void Function(GameConfigBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$GameConfig build() {
    _$GameConfig _$result;
    try {
      _$result = _$v ??
          new _$GameConfig._(
              rules: rules.build(),
              teaming: teaming.build(),
              players: players.build());
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'rules';
        rules.build();
        _$failedField = 'teaming';
        teaming.build();
        _$failedField = 'players';
        players.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'GameConfig', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
