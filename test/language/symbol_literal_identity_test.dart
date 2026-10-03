import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const source = r'''
bool same(Object a, Object b) => identical(a, b);
int main() {
  if (!same(#a, const Symbol('a')) || !same(#a, #a)) return -1;
  if (!same(#a.b, const Symbol('a.b'))) return -2;
  if (!same(#==, const Symbol('=='))) return -3;
  if (!same(#[]=, const Symbol('[]='))) return -4;
  if (!same(#>>>, const Symbol('>>>'))) return -5;
  const implicit = Symbol('a');
  if (!same(implicit, #a)) return -6;
  final runtimeSymbol = Symbol('a');
  if (runtimeSymbol != #a || runtimeSymbol.hashCode != (#a).hashCode) return -7;
  if (#a == #b) return -8;
  if (#_a == const Symbol('_a') || const Symbol('_a') == #_a) return -11;
  if (#_a.foo == const Symbol('_a.foo') ||
      const Symbol('_a.foo') == #_a.foo) return -12;
  if (!same(#_a, #_a) || !same(#_a.foo, #_a.foo)) return -13;
  if (!same(#foo._a, const Symbol('foo._a'))) return -14;
  const lookup = <Symbol, int>{#a: 1, #b: 2};
  if (lookup[const Symbol('b')] != 2) return -9;
  switch (const Symbol('a')) {
    case #a: return 0;
    default: return -10;
  }
}
''';

void main() {
  test('public Symbol literals share canonical const constructor identity', () {
    final program = Compiler().compile({
      'symbol_literal_identity': {'main.dart': source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:symbol_literal_identity/main.dart', 'main'),
        0,
      );
    }
  });
}
