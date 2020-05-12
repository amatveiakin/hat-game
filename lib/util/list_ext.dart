extension ListUtil<T> on List<T> {
  List<T> shuffled() {
    final result = List<T>.from(this);
    result.shuffle();
    return result;
  }
}

extension IterableUtil<E> on Iterable<E> {
  Iterable<S> mapWithIndex<S>(S f(int index, E value)) {
    return Iterable<S>.generate(length, (index) => f(index, elementAt(index)));
  }

  void forEachWithIndex(void f(int index, E value)) {
    int index = 0;
    return forEach((element) => f(index++, element));
  }

  String joinNonEmpty([String separator = '']) {
    return where((e) => e != null && e.toString().isNotEmpty).join(separator);
  }
}
