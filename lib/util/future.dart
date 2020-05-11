class FutureUtil {
  // Like Future.doWhile, but yield after every evaluation of the condition.
  static Future doWhileDelayed(bool Function() condition) {
    return Future.doWhile(
        () => Future.delayed(Duration.zero, () => condition()));
  }
}
