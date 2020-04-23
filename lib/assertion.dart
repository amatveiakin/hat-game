import 'package:flutter/material.dart';
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

  @alwaysThrows
  static fail(String message,
      {MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(false,
        message: message, lazyMessage: lazyMessage, inRelease: inRelease);
  }

  static eq<T>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a == b,
        message: _combine([a.toString() + ' == ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static ne<T>(T a, T b,
      {String message,
      MessageProducer lazyMessage,
      AssertInRelease inRelease = defaultReleaseBehavior}) {
    holds(a != b,
        message: _combine([a.toString() + ' != ' + b.toString(), message]),
        lazyMessage: lazyMessage,
        inRelease: inRelease);
  }

  static _combine(List<String> messages) {
    return messages.where((s) => s != null && s.isNotEmpty).join(': ');
  }
}
