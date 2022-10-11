import 'package:collection/collection.dart';

class ConstantPool<T> {
  ConstantPool();

  final List<T> pool = [];
  final Map<int, int> _map = {};

  int addOrGet(T p) {
    final hash = const DeepCollectionEquality().hash(p) + p.runtimeType.hashCode;
    final existing = _map[hash];
    if (existing != null) return existing;
    pool.add(p);
    return _map[hash] = pool.length - 1;
  }
}
