import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:closures/main.dart';

Runtime _runtime(String source, bool encoded) {
  final program = Compiler().compile({
    'closures': {'main.dart': source},
  });
  return encoded ? Runtime(program.write().buffer) : Runtime.ofProgram(program);
}

Object? _value($Value? value) => value?.$value;

void main() {
  for (final encoded in [false, true]) {
    void check(String name, String source, Object? expected) {
      test('$name, encoded=$encoded', () {
        expect(
          _runtime(source, encoded).executeLib(_library, 'main'),
          expected,
        );
      });
    }

    check('escaped siblings share mutation', r''' 
      List<Function> factory() {
        var n = 0;
        return [() { n = n + 1; return n; }, () => n];
      }
      int main() {
        var pair = factory();
        var first = pair[0]();
        return first * 100 + pair[0]() * 10 + pair[1]();
      }
    ''', 122);
    check('outer mutation after creation updates the closure', r'''
      int main() {
        var n = 3;
        var read = () => n;
        n = 9;
        return read();
      }
    ''', 9);
    check('nested closures forward captures', r'''
      Function factory(int n) => () => () { n = n + 1; return n; };
      int main() {
        var outer = factory(8);
        var first = outer();
        var second = outer();
        return first() * 10 + second();
      }
    ''', 100);
    check('shadowed names keep independent bindings', r'''
      int main() {
        var n = 3;
        var outer = () => n;
        var result = 0;
        {
          var n = 7;
          var inner = () => n;
          result = inner();
        }
        return outer() * 10 + result;
      }
    ''', 37);
    check('conditional closure creation preserves later outer uses', r'''
      int choose(bool enabled) {
        var n = 4;
        if (enabled) {
          var read = () => n;
          n = read() + 2;
        }
        return n + 1;
      }
      int main() => choose(true) * 10 + choose(false);
    ''', 75);
    check('separate factories own separate environments', r'''
      Function counter(int n) => () { n = n + 1; return n; };
      int main() {
        var a = counter(0);
        var b = counter(10);
        return a() * 100 + b() * 10 + a();
      }
    ''', 212);
    check('classic for captures per iteration bindings', r'''
      int main() {
        var values = <Function>[];
        for (var i = 0; i < 3; i++) { values.add(() => i); }
        return values[0]() * 100 + values[1]() * 10 + values[2]();
      }
    ''', 12);
    check('foreach captures per iteration bindings', r'''
      int main() {
        var values = <Function>[];
        for (var i in [1, 2, 3]) { values.add(() => i); }
        return values[0]() * 100 + values[1]() * 10 + values[2]();
      }
    ''', 123);
    check('local recursive functions retain captured state', r'''
      int main() {
        var calls = 0;
        int factorial(int n) {
          calls = calls + 1;
          if (n <= 1) return 1;
          return n * factorial(n - 1);
        }
        return factorial(5) + calls;
      }
    ''', 125);
    check('direct closure calls preserve live caller registers', r'''
      int main() {
        var a = 7;
        var b = 11;
        var add = (int x, int y, int z, int w) => x + y + z + w;
        var total = add(b, a, b, a);
        return total + a + b;
      }
    ''', 54);
    check('native iterable map calls captured closures', r'''
      int main() {
        var offset = 5;
        return [1, 2, 3].map((int n) => n + offset).toList()[2];
      }
    ''', 8);

    check(
      'source closure calls apply defaults and reorder named arguments',
      r'''
      int main() {
        var positional = ([int x = 4]) => x;
        var named = ({required int x, int y = 2}) => x * 10 + y;
        return positional() + named(y: 7, x: 3) + named(x: 5);
      }
    ''',
      93,
    );

    check(
      'function tear-off equality follows function and receiver identity',
      r'''
      int first() => 1;
      int second() => 1;

      class Counter {
        int first() => 1;
        int second() => 1;
      }

      bool main() {
        final receiver = Counter();
        final otherReceiver = Counter();
        final firstTearOff = first;
        final sameFirstTearOff = first;
        final bound = receiver.first;
        final sameBound = receiver.first;
        final closure = () => 1;
        final sameClosure = closure;
        final otherClosure = () => 1;
        return firstTearOff == sameFirstTearOff &&
            firstTearOff != second &&
            bound == sameBound &&
            bound.hashCode == sameBound.hashCode &&
            bound != otherReceiver.first &&
            bound != receiver.second &&
            closure == sameClosure &&
            closure != otherClosure;
      }
    ''',
      true,
    );

    test('escaping closure captures only free variables, encoded=$encoded', () {
      final runtime = _runtime(r'''
        Function main(int used, int unused) => () => used;
      ''', encoded);
      final closure =
          runtime.executeLib(
                _library,
                'main',
                arguments: {'used': 7, 'unused': 99},
              )
              as TypedClosure;
      expect(closure.descriptor.captureCount, 1);
      expect(_value(closure.invoke(0, null, null)), 7);
    });
    test(
      'host zero-argument entry preserves captures and bound receivers, encoded=$encoded',
      () {
        final runtime = _runtime(r'''
          class Counter {
            int value;
            Counter(this.value);
            int next() { value = value + 1; return value; }
          }

          List<Function> main() {
            var captured = 3;
            final counter = Counter(8);
            return [
              () { captured = captured + 1; return captured; },
              counter.next,
            ];
          }
        ''', encoded);
        final callbacks = runtime.executeLib(_library, 'main') as List;
        final captured = callbacks[0] as TypedClosure;
        final bound = callbacks[1] as EvalCallable;
        expect(_value(captured.invoke(0, null, null)), 4);
        expect(_value(captured.call(runtime, null, null, null, 0)), 5);
        expect(_value(bound.call(runtime, null, null, null, 0)), 9);
        expect(_value(bound.call(runtime, null, null, null, 0)), 10);
      },
    );
    test('host zero-argument entry permits reentry, encoded=$encoded', () {
      final runtime = _runtime(r'''
        Function main(Function reenter) {
          var depth = 0;
          return () {
            depth = depth + 1;
            if (depth == 1) reenter();
            final result = depth;
            depth = depth - 1;
            return result;
          };
        }
      ''', encoded);
      late TypedClosure callback;
      callback =
          runtime.executeLib(
                _library,
                'main',
                arguments: {'reenter': () => callback.invoke(0, null, null)},
              )
              as TypedClosure;
      expect(_value(callback.invoke(0, null, null)), 1);
      expect(_value(callback.invoke(0, null, null)), 1);
    });
    test(
      'host zero-argument entry preserves errors and async results, encoded=$encoded',
      () async {
        final runtime = _runtime(r'''
          List<Function> main() => [
            () { throw 'guest error'; },
            () async => 11,
          ];
        ''', encoded);
        final callbacks = runtime.executeLib(_library, 'main') as List;
        final throwing = callbacks[0] as TypedClosure;
        final asynchronous = callbacks[1] as TypedClosure;
        expect(() => throwing.invoke(0, null, null), throwsA(isA<Exception>()));
        final future =
            asynchronous.invoke(0, null, null)!.$value as Future<Object?>;
        expect(_value(await future as $Value?), 11);
      },
    );
    test(
      'optional closure arguments preserve omitted versus explicit null, encoded=$encoded',
      () {
        final runtime = _runtime(r'''
        Function main() => ([String? text = 'default']) => text;
      ''', encoded);
        final closure = runtime.executeLib(_library, 'main') as TypedClosure;
        expect(_value(closure.invoke(0, null, null)), 'default');
        expect(_value(closure.invoke(1, null, null)), isNull);
        expect(_value(closure.invoke(1, const $null(), null)), isNull);
        expect(_value(closure.invoke(1, $String('given'), null)), 'given');
      },
    );
    test(
      'named defaults and required arguments bind by name, encoded=$encoded',
      () {
        final runtime = _runtime(r'''
        Function main() => ({required int x, int y = 4, String? text = 'default'}) => text == null ? x : x + y;
      ''', encoded);
        final closure = runtime.executeLib(_library, 'main') as TypedClosure;
        expect(_value(closure.invoke(0, $int(3), null, namedNames: ['x'])), 7);
        expect(
          _value(closure.invoke(0, $int(8), $int(3), namedNames: ['y', 'x'])),
          11,
        );
        expect(
          _value(closure.invoke(0, $int(3), null, namedNames: ['x', 'text'])),
          3,
        );
        expect(
          () => closure.invoke(0, null, null),
          throwsA(isA<NoSuchMethodError>()),
        );
        expect(
          () => closure.invoke(0, $int(3), $int(1), namedNames: ['x', 'extra']),
          throwsA(isA<NoSuchMethodError>()),
        );
      },
    );
  }
}
