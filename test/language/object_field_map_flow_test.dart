import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'stable object fields and guarded map entries retain separate proofs',
    () {
      final program = Compiler().compile({
        'flow': {
          'main.dart': r'''
typedef Exactly<T> = T Function(T);
extension Check<T> on T {
  T check<R extends Exactly<T>>() => this;
}
class Leaf {
  final int? _n;
  int? _moving;
  Leaf(this._n) : _moving = _n;
}
class Holder {
  final Leaf _leaf;
  Leaf _movingLeaf;
  Holder(this._leaf) : _movingLeaf = _leaf;
}
bool inspect(Holder holder, String? key, num? value) {
  if (holder case Holder(_leaf: Leaf(_n: _?))) {
    holder._leaf._n.check<Exactly<int>>();
    final map = {?key: ?value};
    map.check<Exactly<Map<String, num>>>();
    key.check<Exactly<String?>>();
    value.check<Exactly<num?>>();
    if (map.length != (key != null && value != null ? 1 : 0)) return false;
  }
  holder._leaf._n.check<Exactly<int?>>();
  if (holder._leaf._n != null) {
    if (holder case Holder(_leaf: Leaf(_n: var bound))) {
      bound.check<Exactly<int>>();
      if (bound != 4) return false;
    }
  }
  if (holder case Holder(_movingLeaf: Leaf(_n: _?))) {
    holder._movingLeaf._n.check<Exactly<int?>>();
  }
  if (holder case Holder(_leaf: Leaf(_moving: _?))) {
    holder._leaf._moving.check<Exactly<int?>>();
  }
  if (holder case Holder(_leaf: Leaf(_n: _?)) || Holder(_leaf: Leaf(_n: _?))) {
    holder._leaf._n.check<Exactly<int>>();
  }
  if (holder case Holder(_leaf: Leaf(_n: _?)) || Holder()) {
    holder._leaf._n.check<Exactly<int?>>();
  }
  if (holder case Holder(_leaf: Leaf(_n: _?))
      when (holder = Holder(Leaf(null)))._leaf._n == null) {
    holder._leaf._n.check<Exactly<int?>>();
  }
  return true;
}
bool main() => inspect(Holder(Leaf(4)), 'key', 2) &&
    inspect(Holder(Leaf(4)), null, 2) &&
    inspect(Holder(Leaf(4)), 'key', null) &&
    inspect(Holder(Leaf(null)), null, null);
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:flow/main.dart', 'main'), true);
      }
    },
  );
}
