typedef MockShuffler<E> = List<E> Function(List<E>);

extension ListUtil<E> on List<E> {
  List<E> sorted([int Function(E a, E b)? compare]) {
    return List<E>.from(this)..sort(compare);
  }

  List<E> shuffled({MockShuffler<E>? mockShuffler}) {
    return mockShuffler == null
        ? (List<E>.from(this)..shuffle())
        : mockShuffler(this);
  }
}

extension OptionalListUtil<E> on List<E>? {
  // Sample usage:
  //   for (final value in collection.orEmpty()) { ... }
  // This is similar to
  //   for (final value in collection ?? []) { ... }
  // but with `orEmpty` the type of `value` is `E` rather than `dynamic`.
  List<E> orEmpty() {
    return this ?? [];
  }
}

extension IterableUtil<E> on Iterable<E> {
  Iterable<S> mapWithIndex<S>(S Function(int index, E value) f) {
    return Iterable<S>.generate(length, (index) => f(index, elementAt(index)));
  }

  void forEachWithIndex(void Function(int index, E value) f) {
    int index = 0;
    return forEach((element) => f(index++, element));
  }

  String joinNonEmpty([String? separator = '']) {
    return where((e) => e != null && e.toString().isNotEmpty).join(separator!);
  }
}
