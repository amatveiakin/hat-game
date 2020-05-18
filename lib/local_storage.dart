import 'package:flutter/material.dart';
import 'package:hatgame/db/db_columns.dart';
import 'package:hatgame/util/invalid_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unicode/unicode.dart' as unicode;

// =============================================================================
// Local config interface

abstract class LocalStorage {
  static LocalStorage instance;

  static Future<void> init() async {
    try {
      instance = await LocalStorageFromSharedPreferences.getInstance();
      debugPrint('Local storage loaded successfully.');
    } catch (e) {
      // TODO: Firebase log.
      debugPrint("Couldn't initialize local storage!");
      debugPrint('The error was: $e');
    } finally {
      if (instance == null) {
        instance = LocalStorageInMemory();
      }
    }
  }

  T get<T>(DBColumn<T> column);
  Future<void> set<T>(DBColumn<T> column, T data);
}

// =============================================================================
// Columns

class LocalColPlayerName extends DBColumn<String> with DBColSerializeString {
  String get name => 'player_name';
}

// =============================================================================
// Helpers

InvalidOperation checkPlayerName(String name) {
  if (name.isEmpty) {
    return InvalidOperation('Player name is empty');
  }
  if (name.length > 50) {
    return InvalidOperation('Player name too long');
  }
  for (final c in name.codeUnits) {
    if (unicode.isControl(c) || unicode.isFormat(c)) {
      return InvalidOperation('Player name contans invalid character: '
          '${String.fromCharCode(c)} (code $c)');
    }
  }
  return null;
}

// =============================================================================
// Local config implementations

class LocalStorageFromSharedPreferences extends LocalStorage {
  // SharedPreferences cache value themselves, no need to do it on top.
  final SharedPreferences prefs;

  static Future<LocalStorageFromSharedPreferences> getInstance() async {
    return LocalStorageFromSharedPreferences._(
        await SharedPreferences.getInstance());
  }

  LocalStorageFromSharedPreferences._(this.prefs);

  T get<T>(DBColumn<T> column) {
    return column.deserialize(prefs.getString(column.name));
  }

  Future<void> set<T>(DBColumn<T> column, T data) async {
    await prefs.setString(column.name, column.serialize(data));
  }
}

class LocalStorageInMemory extends LocalStorage {
  final _data = Map<String, String>();

  T get<T>(DBColumn<T> column) {
    return column.deserialize(_data[column.name]);
  }

  Future<void> set<T>(DBColumn<T> column, T data) async {
    _data[column.name] = column.serialize(data);
  }
}
