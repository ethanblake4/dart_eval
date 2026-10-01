import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:unary_callback/main.dart';
const _source = r'''
class Base {
  int accept(num value) => 0;
}
class Child extends Base {
  int accept(covariant int value) => value + 1;
}
class Box<T> {
  T keep(T value) => value;
}
class Counter {
  int value = 5;
  int add(int delta) => value += delta;
}
Function captured() {
  var value = 3;
  return (int delta) => value += delta;
}
Function bound() => Counter().add;
Function covariantBound() {
  Base view = Child();
  return view.accept;
}
Function genericBound() {
  Box<num> view = Box<int>();
  return view.keep;
}
Function genericClosure() => <T extends num>(T value) => value;
Function defaults() => ([int value = 7]) => value + 1;
Function named() => (int value, {int offset = 2}) => value + offset;
Function floating() => (double value) => value + 0.5;
Function boolean() => (bool value) => !value;
Function text() => (String value) => '$value!';
Function nullable() => (Object? value) => value;
''';

void main() {
  for (final serialized in [false, true]) {
    test('host unary callbacks preserve context, encoded=$serialized', () {
      final program = Compiler().compile({
        'unary_callback': {'main.dart': _source},
      });
      final runtime = serialized
          ? Runtime(program.write().buffer)
          : Runtime.ofProgram(program);
      EvalCallable callback(String name) =>
          runtime.executeLib(_library, name) as EvalCallable;
      $Value? unary(EvalCallable fn, Object? value) =>
          fn.call(runtime, null, value, null, 1);
      final captured = callback('captured');
      expect((unary(captured, $int(4)) as $int).$value, 7);
      expect((unary(captured, $int(2)) as $int).$value, 9);
      final bound = callback('bound');
      expect((unary(bound, $int(3)) as $int).$value, 8);
      expect((unary(bound, $int(4)) as $int).$value, 12);
      for (final name in ['covariantBound', 'genericBound']) {
        final fn = callback(name);
        expect(
          (unary(fn, $int(2)) as $int).$value,
          name == 'covariantBound' ? 3 : 2,
        );
        expect(() => unary(fn, $double(2.5)), throwsA(isA<TypeError>()));
      }
      final generic = callback('genericClosure');
      expect((unary(generic, $int(4)) as $int).$value, 4);
      expect(() => unary(generic, $String('bad')), throwsA(isA<TypeError>()));
      expect(
        (unary(callback('floating'), $double(1.5)) as $double).$value,
        2.0,
      );
      expect((unary(callback('boolean'), $bool(true)) as $bool).$value, false);
      expect((unary(callback('text'), $String('ok')) as $String).$value, 'ok!');
      final nullable = callback('nullable');
      expect(unary(nullable, null), isNull);
      final object = $String('identity');
      expect(unary(nullable, object), same(object));
      final defaults = callback('defaults');
      expect((unary(defaults, $int(3)) as $int).$value, 4);
      expect((defaults.call(runtime, null, null, null, 0) as $int).$value, 8);
      expect((unary(callback('named'), $int(3)) as $int).$value, 5);
      expect(() => unary(captured, $String('bad')), throwsA(isA<TypeError>()));
    });
  }
}
