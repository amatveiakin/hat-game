import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/util/list_ext.dart';
import 'package:meta/meta.dart';

enum AssertInRelease {
  ignore,
  log,
  fail,
}

typedef MessageProducer = String Function();

class Assert {
  // TODO: Change to log when stable.
  static const defaultReleaseBehavior = AssertInRelease.fail;

  static void holds(bool condition,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    final String combinedMessage = _combine([message, lazyMessage?.call()]);
    assert(condition, combinedMessage);
    if (!condition) {
      final decoratedMessage = _combine(['Assertion failed', combinedMessage]);
      final String stackTrace = StackTrace.current.toString();
      final firebaseLog = () => FirebaseAnalytics().logEvent(
            name: 'assertion_failure',
            parameters: {
              'message': decoratedMessage,
              'stack_trace': stackTrace,
            },
          );
      switch (inRelease) {
        case AssertInRelease.ignore:
          break;
        case AssertInRelease.log:
          debugPrint(decoratedMessage + '\n' + stackTrace);
          firebaseLog();
          break;
        case AssertInRelease.fail:
          firebaseLog();
          throw AssertionError(decoratedMessage);
      }
    }
  }

  // TODO: Replace `@alwaysThrows` with `Never` return type when it's ready.
  @alwaysThrows
  static void fail(String message,
      {AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(false, message: message, inRelease: inRelease);
  }

  static void eq<T>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a == b,
        message: _combine([a.toString() + ' == ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void ne<T>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a != b,
        message: _combine([a.toString() + ' != ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void lt<T extends Comparable>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) < 0,
        message: _combine([a.toString() + ' < ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void le<T extends Comparable>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) <= 0,
        message: _combine([a.toString() + ' <= ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void gt<T extends Comparable>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) > 0,
        message: _combine([a.toString() + ' > ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void ge<T extends Comparable>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) >= 0,
        message: _combine([a.toString() + ' >= ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void isIn<T>(T a, Set<T> b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(b.contains(a),
        message: _combine([a.toString() + ' in ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static _combine(List<String> messages) {
    return messages.joinNonEmpty(': ');
  }
}
