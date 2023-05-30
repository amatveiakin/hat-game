import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hatgame/util/list_ext.dart';

enum AssertInRelease {
  ignore,
  log,
  fail,
}

typedef MessageProducer = String Function();
typedef VoidCallback = void Function();

class Assert {
  // TODO: Change to log when stable.
  static const defaultReleaseBehavior = AssertInRelease.fail;

  static withContext(
      {required MessageProducer context, required VoidCallback body}) {
    _AssertContext.push(context);
    try {
      body();
    } finally {
      _AssertContext.pop();
    }
  }

  static void holds(bool condition,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    final String combinedMessage = _combine([
      message,
      lazyMessage?.call(),
      ..._AssertContext.get().map((c) => c()),
    ]);
    assert(condition, combinedMessage);
    if (!condition) {
      final decoratedMessage = _combine(['Assertion failed', combinedMessage]);
      final String stackTrace = StackTrace.current.toString();
      firebaseLog() => FirebaseAnalytics.instance.logEvent(
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

  static Never fail(String message) {
    holds(false, message: message, inRelease: AssertInRelease.fail);
    throw AssertionError("Should've thrown earlier!");
  }

  static void failDebug(String message, {required AssertInRelease inRelease}) {
    holds(false, message: message, inRelease: inRelease);
  }

  static void eq<T>(T a, T b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a == b,
        message: _combine(['$a == $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void ne<T>(T a, T b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a != b,
        message: _combine(['$a != $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void lt<T extends Comparable>(T a, T b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) < 0,
        message: _combine(['$a < $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void le<T extends Comparable>(T a, T b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) <= 0,
        message: _combine(['$a <= $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void gt<T extends Comparable>(T a, T b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) > 0,
        message: _combine(['$a > $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void ge<T extends Comparable>(T a, T b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a.compareTo(b) >= 0,
        message: _combine(['$a >= $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void isIn<T>(T a, Iterable<T> b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(b.contains(a),
        message: _combine(['$a in $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static void subset<T>(Iterable<T> a, Set<T> b,
      {String? message,
      MessageProducer? lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(b.containsAll(a),
        message: _combine(['$a in $b', message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static _combine(List<String?> messages) {
    return messages.joinNonEmpty(': ');
  }
}

class _AssertContext {
  static final List<MessageProducer> _stack = [];

  static void push(MessageProducer context) => _stack.add(context);
  static void pop() => _stack.removeLast();
  static List<MessageProducer> get() => _stack;
}
