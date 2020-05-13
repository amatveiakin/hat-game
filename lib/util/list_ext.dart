typedef MockShuffler<E> = List<E> Function(List<E>);

extension ListUtil<E> on List<E> {
  List<E> sorted([int compare(E a, E b)]) {
    return List<E>.from(this)..sort(compare);
  }

  List<E> shuffled({MockShuffler<E> mockShuffler}) {
    return mockShuffler == null
        ? (List<E>.from(this)..shuffle())
        : mockShuffler(this);
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
