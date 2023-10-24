import 'package:collection/collection.dart';

class ConstantPool<T> {
  ConstantPool();

  final List<T> pool = [];
  final Map<int, int> _map = {};

  int addOrGet(T p) {
    var hash = const DeepCollectionEquality().hash(p) + p.runtimeType.hashCode;
    if (p is List) {
      hash ^= p.length;
    }
    final existing = _map[hash];
    if (existing != null) return existing;
    pool.add(p);
    return _map[hash] = pool.length - 1;
  }
}
