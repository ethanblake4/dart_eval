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
      expect(_value(closure.invoke([])), 7);
    });
    test(
      'optional closure arguments preserve omitted versus explicit null, encoded=$encoded',
      () {
        final runtime = _runtime(r'''
        Function main() => ([String? text = 'default']) => text;
      ''', encoded);
        final closure = runtime.executeLib(_library, 'main') as TypedClosure;
        expect(_value(closure.invoke([])), 'default');
        expect(_value(closure.invoke([null])), isNull);
        expect(_value(closure.invoke([const $null()])), isNull);
        expect(_value(closure.invoke([$String('given')])), 'given');
      },
    );
    test(
      'named defaults and required arguments bind by name, encoded=$encoded',
      () {
        final runtime = _runtime(r'''
        Function main() => ({required int x, int y = 4, String? text = 'default'}) => text == null ? x : x + y;
      ''', encoded);
        final closure = runtime.executeLib(_library, 'main') as TypedClosure;
        expect(_value(closure.invoke([], named: {'x': $int(3)})), 7);
        expect(
          _value(closure.invoke([], named: {'y': $int(8), 'x': $int(3)})),
          11,
        );
        expect(
          _value(closure.invoke([], named: {'x': $int(3), 'text': null})),
          3,
        );
        expect(() => closure.invoke([]), throwsArgumentError);
        expect(
          () => closure.invoke([], named: {'x': $int(3), 'extra': $int(1)}),
          throwsArgumentError,
        );
      },
    );
  }
}
