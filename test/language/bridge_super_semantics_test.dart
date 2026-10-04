import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test(
    'bridge constructor references invoke and canonicalize through codec',
    () {
      _expectBoth(r'''
bool main() {
  BigInt Function(num) make = BigInt.from;
  final same = BigInt.from;
  return identical(make, same) && make(19).toString() == '19';
}
''');
    },
  );

  test(
    'super equality evaluates once and skips null before covariant checks',
    () {
      _expectBoth(r'''
int evaluations = 0;
int calls = 0;
dynamic evaluate(dynamic value) { evaluations++; return value; }
class Parent {
  bool operator ==(covariant num other) { calls++; return other == 7; }
}
class Child extends Parent {
  bool operator ==(Object other) => false;
  bool same(dynamic value) => super == evaluate(value);
  bool different(dynamic value) => super != evaluate(value);
}
bool main() {
  final child = Child();
  if (child.same(null) || !child.different(null) || calls != 0) return false;
  if (!child.same(7) || child.different(7) || calls != 2) return false;
  try { child.same('bad'); return false; } on TypeError {}
  return evaluations == 5 && calls == 2;
}
''');
    },
  );

  test(
    'super tearoff retains inherited interface covariance and owner types',
    () {
      _expectBoth(r'''
abstract class Consumer<T> { T consume(T value); }
class Parent<T> { T consume(T value) => value; }
class Middle extends Parent<int> implements Consumer<int> {}
class Child extends Middle {
  int consume(int value) => -1;
  bool check() {
    final function = super.consume;
    return function is int Function(Object?) && function(11) == 11;
  }
}
bool main() => Child().check();
''');
    },
  );

  test('super equality rejects unrelated nullable argument types', () {
    expect(
      () => Compiler().compile({
        'bridge_super': {
          'main.dart': r'''
class Parent { bool operator ==(covariant num other) => false; }
class Child extends Parent { bool same(String? value) => super == value; }
bool main() => Child().same(null);
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });

  test('generated generic and iterable arguments preserve language values', () {
    _expectBoth(r'''
class Token {}
bool main() {
  final token = Token();
  final entry = MapEntry<Token, int>(token, 5);
  final uri = Uri(pathSegments: ['a b', 'c']);
  return identical(entry.key, token) && entry.value == 5 &&
      uri.toString() == 'a%20b/c' && Uri().toString() == '';
}
''');
  });
}

void _expectBoth(String source) {
  final program = Compiler().compile({
    'bridge_super': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:bridge_super/main.dart', 'main'), true);
  }
}
