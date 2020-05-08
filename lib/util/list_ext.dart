extension ListUtil<T> on List<T> {
  List<T> shuffled() {
    final result = List<T>.from(this);
    result.shuffle();
    return result;
  }
}

extension IterableUtil<T> on Iterable<T> {
  Iterable<S> mapWithIndex<S>(S f(int index, T value)) {
    return Iterable<S>.generate(length, (index) => f(index, elementAt(index)));
  }
}
