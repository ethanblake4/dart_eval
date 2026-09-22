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
    // Numbers compare by `identical`, not `==`: `0.0` and `-0.0` (and
    // `1` and `1.0`) are equal under `==` but must remain distinct
    // constants.
    for (final index in candidates) {
      if (_constantEquals(pool[index], p)) {
        return index;
      }
    }
    pool.add(p);
    candidates.add(pool.length - 1);
    return pool.length - 1;
  }

  /// `identical`-consistent equality for pooled constants: `num` leaves
  /// compare bitwise (`identical`), collections recurse elementwise, and
  /// everything else compares by `==`.
  static bool _constantEquals(Object? a, Object? b) {
    if (a is num && b is num) return identical(a, b);
    if (a is List && b is List && a.length == b.length) {
      for (var i = 0; i < a.length; i++) {
        if (!_constantEquals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map && a.length == b.length) {
      for (final entry in a.entries) {
        if (!b.containsKey(entry.key) ||
            !_constantEquals(entry.value, b[entry.key])) {
          return false;
        }
      }
      return true;
    }
    if (a is Set && b is Set && a.length == b.length) {
      return a.containsAll(b);
    }
    return a == b;
  }
}
