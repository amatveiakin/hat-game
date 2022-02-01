import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

extension BuiltValueListBuilderExtension<V extends Built<V, B>,
    B extends Builder<V, B>> on ListBuilder<Built<V, B>> {
  void rebuildAt(int index, void Function(B) updates) =>
      this[index] = this[index].rebuild(updates);
}

extension BuiltValueMapBuilderExtension<K, V extends Built<V, B>,
    B extends Builder<V, B>> on MapBuilder<K, Built<V, B>> {
  void rebuildAt(K key, void Function(B) updates) =>
      this[key] = this[key]!.rebuild(updates);
}
