import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

sealed class LocalStr {
  LocalStr();

  factory LocalStr.raw(String text) {
    return _RawStr(text);
  }
  factory LocalStr.tr(String key,
      {List<String>? args, Map<String, String>? namedArgs, String? gender}) {
    return _TrStr(key, args, namedArgs, gender);
  }

  String value(BuildContext context);
}

class _RawStr extends LocalStr {
  final String text;

  _RawStr(this.text);

  @override
  String value(BuildContext context) {
    return text;
  }
}

class _TrStr extends LocalStr {
  final String key;
  final List<String>? args;
  final Map<String, String>? namedArgs;
  final String? gender;

  _TrStr(this.key, this.args, this.namedArgs, this.gender);

  @override
  String value(BuildContext context) {
    return context.tr(key, args: args, namedArgs: namedArgs, gender: gender);
  }
}
