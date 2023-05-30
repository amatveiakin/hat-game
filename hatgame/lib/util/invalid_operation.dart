import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/list_ext.dart';

class InvalidOperation implements Exception {
  final String message;
  final String? comment;
  final bool isInternalError;
  final _tags = <Type, dynamic>{};

  InvalidOperation(
    this.message, {
    this.comment,
    this.isInternalError = false,
  });

  void addTag<T>(T value) {
    Assert.holds(!_tags.containsKey(T));
    _tags[T] = value;
  }

  T? tag<T>() => _tags[T];

  @override
  String toString() {
    return [
      'InvalidOperation (internal = $isInternalError): $message',
      comment,
      _tags.isEmpty ? null : 'tags ${_tags.toString()}',
    ].joinNonEmpty('; ');
  }
}
