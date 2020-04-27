class InvalidOperation implements Exception {
  final String message;
  final String comment;
  final bool isInternalError;

  InvalidOperation(
    this.message, {
    this.comment,
    this.isInternalError = false,
  });
}
