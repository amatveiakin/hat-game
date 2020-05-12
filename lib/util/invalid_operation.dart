import 'package:hatgame/util/list_ext.dart';

class InvalidOperation implements Exception {
  final String message;
  final String comment;
  final bool isInternalError;

  InvalidOperation(
    this.message, {
    this.comment,
    this.isInternalError = false,
  });

  @override
  String toString() {
    return ['InvalidOperation (internal = $isInternalError): $message', comment]
        .joinNonEmpty('; ');
  }
}
