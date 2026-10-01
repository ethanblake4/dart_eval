import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const source = r'''
Set<T> create<T>() => new Set<T>();
bool integerSet(Object value) => value is Set<int> && value is! Set<double>;
bool stringSet(Object value) => value is Set<String> && value is! Set<int>;
class Maker<T> {
  Function deferred() => () => new Set<T>();
}
class Key {
  Key(this.id);
  final int id;
  bool operator ==(Object other) => other is Key && other.id == id;
  int get hashCode => id % 2;
}
int main() {
  final bare = Set();
  bare.add(1);
  bare.add('two');
  if (bare.length != 2) return -1;
  Set<int> contextual = Set();
  contextual.add(3);
  if (!integerSet(contextual)) return -2;
  final explicit = new Set<String>();
  explicit.add('text');
  if (!stringSet(explicit)) return -3;
  dynamic generated = Maker<int>().deferred()();
  if (generated is! Set<int> || generated is Set<double>) return -4;
  Set<num> widened = create<int>();
  widened.add(4);
  var rejected = false;
  try { widened.add(1.5); } on TypeError { rejected = true; }
  if (!rejected || widened.length != 1 || widened.first != 4) return -5;
  final first = Key(1);
  final third = Key(3);
  final second = Key(2);
  final keys = new Set<Key>();
  if (!keys.add(first) || !keys.add(third) || !keys.add(second)) return -6;
  if (keys.add(Key(1)) || keys.length != 3) return -7;
  if (!identical(keys.lookup(Key(1)), first) || !keys.contains(Key(3))) return -8;
  if (keys.map((Key key) => key.id).join(',') != '1,3,2') return -9;
  if (!keys.remove(Key(3))) return -10;
  keys.add(Key(3));
  if (keys.map((Key key) => key.id).join(',') != '1,2,3') return -11;
  return 0;
}
''';

void main() {
  test(
    'unnamed Set factories retain types and guest linked hash semantics',
    () {
      final program = Compiler().compile({
        'set_factory': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:set_factory/main.dart', 'main'), 0);
      }
    },
  );
}
