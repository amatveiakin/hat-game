// Same as `min` from math package, but doesn't require that `T extends num`.
T anyMin<T extends Comparable<T>>(T a, T b) {
  return a.compareTo(b) < 0 ? a : b;
}

// Same as `max` from math package, but doesn't require that `T extends num`.
T anyMax<T extends Comparable<T>>(T a, T b) {
  return a.compareTo(b) > 0 ? a : b;
}
