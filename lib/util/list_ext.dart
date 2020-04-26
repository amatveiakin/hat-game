extension MyList<T> on List<T> {
  List<T> shuffled() {
    final result = List<T>.from(this);
    result.shuffle();
    return result;
  }
}
