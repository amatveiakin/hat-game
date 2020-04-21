import 'package:flutter/material.dart';

enum AssertInRelease {
  ignore,
  log,
  fail,
}

class Assert {
  // TODO: Change to log when stable.
  static const defaultReleaseBehavior = AssertInRelease.fail;

  static void holds(bool condition,
      {String message, AssertInRelease inRelease = defaultReleaseBehavior}) {
    assert(condition, message);
    if (!condition) {
      final decoratedMessage = _combineMessages('Assertion failed', message);
      switch (inRelease) {
        case AssertInRelease.ignore:
          break;
        case AssertInRelease.log:
          // TODO: Log to Firebase.
          debugPrint(decoratedMessage + '\n\n' + StackTrace.current.toString());
          break;
        case AssertInRelease.fail:
          throw AssertionError(decoratedMessage);
      }
    }
  }

  static eq<T>(T a, T b,
      {String message, AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a == b,
        message:
            _combineMessages(message, a.toString() + ' == ' + b.toString()),
        inRelease: inRelease);
  }

  static bool _nullOrEmpty(String s) {
    return s == null || s.isEmpty;
  }

  static _combineMessages(String main, String context) {
    return _nullOrEmpty(context)
        ? main
        : (_nullOrEmpty(main) ? context : main + ': ' + context);
  }
}
