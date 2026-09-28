import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

const _entry = 'package:runaway/main.dart';

Iterable<Runtime> _runtimes(String source) {
  final program = Compiler().compile({
    'runaway': {'main.dart': source},
  });
  return [Runtime.ofProgram(program), Runtime(program.write().buffer)];
}

void main() {
  test('loop headers discard promotions invalidated by the back edge', () {
    for (final runtime in _runtimes('''
      int main() {
        var guard = 0;
        var values = [
          for (String? x = 'value'; x != null && guard++ < 4; x = null) x,
        ];
        int? number = 2;
        while (number != null && guard++ < 8) { number = null; }
        return values.length * 10 + guard;
      }
    ''')) {
      expect(runtime.executeLib(_entry, 'main'), 12);
    }
  });

  test('null list elements do not trigger a recursive branch', () {
    for (final runtime in _runtimes('''
      int calls = 0;
      final values = List<dynamic>.filled(1, null);
      int main() {
        if (++calls > 3) return -1;
        if (values[0] != null) return main();
        dynamic value = values[0];
        return value == null ? calls : -2;
      }
    ''')) {
      expect(runtime.executeLib(_entry, 'main'), 1);
    }
  });

  test('one-time loop initializers preserve compatible promotions', () {
    for (final runtime in _runtimes('''
      int main() {
        Object value = 2;
        if (value is int) {
          for (value = 4;;) { if (!value.isEven) return -1; break; }
          for (final item in [value = 6]) {
            if (!value.isEven) return -2;
          }
          return value;
        }
        return -3;
      }
    ''')) {
      expect(runtime.executeLib(_entry, 'main'), 6);
    }
  });

  test('shadowed loop locals preserve the outer binding promotion', () {
    for (final runtime in _runtimes('''
      int main() {
        Object value = 1;
        if (value is int) {
          for (var i = 0; i < 1; i++) { var value = 0; value++; }
          for (var value = 0; value < 1; value++) {}
          return value + 1;
        }
        return -1;
      }
    ''')) {
      expect(runtime.executeLib(_entry, 'main'), 2);
    }
  });

  test('super operators bypass overrides, including compound indexing', () {
    for (final runtime in _runtimes('''
      class Base {
        int value = 20;
        int operator +(int other) => value + other;
        int operator [](int index) => value;
        void operator []=(int index, int next) { value = next; }
      }
      class Child extends Base {
        int operator +(int other) => super + other * 2;
        int operator [](int index) => super[index] * 2;
        void operator []=(int index, int next) { super[index++] += next; }
      }
      int main() {
        final child = Child();
        child[0] = 1;
        return child[0] + (child + 2);
      }
    ''')) {
      expect(runtime.executeLib(_entry, 'main'), 67);
    }
  });

  test('pattern bindings do not hide subsequent writes to outer locals', () {
    for (final runtime in _runtimes('''
      int main() {
        Object value = 1;
        var count = 0;
        if (value is int) {
          for (var i = 0; i < 2; i++) {
            if (value is int) count++;
            if (0 case final value) {}
            switch (0) { case final value: break; }
            value = 'changed';
          }
        }
        return count;
      }
    ''')) {
      expect(runtime.executeLib(_entry, 'main'), 1);
    }
  });

  test(
    'recursive stack overflow is catchable and the runtime can run again',
    () {
      for (final runtime in _runtimes('''
      int recurse() => recurse() + 1;
      int main() {
        try { return recurse(); } catch (error) { return 42; }
      }
    ''')) {
        runtime.maxCallDepth = 128;
        expect(runtime.executeLib(_entry, 'main'), 42);
        expect(runtime.executeLib(_entry, 'main'), 42);
      }
    },
  );

  test('large cascades and literals preserve every element', () {
    const count = 2000;
    final cascade = List.generate(count, (i) => '..add($i)').join();
    final literal = List.generate(count, (i) => '$i').join(',');
    for (final runtime in _runtimes('''
      int main() {
        final values = <int>[] $cascade;
        const expected = [$literal];
        for (var i = 0; i < expected.length; i++) {
          if (values[i] != expected[i]) return -1;
        }
        return values.length;
      }
    ''')) {
      expect(runtime.executeLib(_entry, 'main'), count);
    }
  });

  test('then adopts a Future returned by an evaluated callback', () async {
    for (final runtime in _runtimes('''
      Future<String> main() async {
        final value = await Future<String>.value('value').then((value) {
          return Future<String>.value(value);
        });
        return value;
      }
    ''')) {
      final value = await runtime.executeLib(_entry, 'main');
      expect((value as $Value).$value, 'value');
    }
  });
}
