import 'package:collection/collection.dart';

class ConstantPool<T> {
  ConstantPool();

  final List<T> pool = [];
  final Map<int, List<int>> _map = {};

  int addOrGet(T p) {
    var hash = const DeepCollectionEquality().hash(p) + p.runtimeType.hashCode;
    if (p is List) {
      hash ^= p.length;
    }
    final candidates = _map.putIfAbsent(hash, () => []);
    // Equal-hash entries are verified by value — a collision between
    // distinct constants must not alias them to the same pool index.
    for (final index in candidates) {
      if (const DeepCollectionEquality().equals(pool[index], p)) {
        return index;
      }
    }
    pool.add(p);
    candidates.add(pool.length - 1);
    return pool.length - 1;
  }
}
