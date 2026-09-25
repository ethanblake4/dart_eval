import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

// Characterization tests for the argument-binding bugs documented in
// docs/compiler-model-refactor.md ("Confirmed bugs"), asserting the
// Dart-correct outcomes after the phase-7 semantic changes.

const _library = 'package:binding/main.dart';

Runtime _runtime(String source) {
  final program = Compiler().compile({
    'binding': {'main.dart': source},
  });
  return Runtime.ofProgram(program);
}

void main() {
  test(
    'overridden default comes from the dispatch, not the static declaration',
    () {
      // Dart: uses x = 2 (B.m) — virtual calls leave defaults to the runtime
      // and devirtualized calls bind the implementation's formals.
      expect(
        _runtime(r'''
        class A { int m([int x = 1]) => x; }
        class B extends A { @override int m([int x = 2]) => x; }
        int main() { A a = B(); return a.m(); }
      ''').executeLib(_library, 'main'),
        2,
      );
    },
  );

  test('dynamic receiver binds defaults from the runtime declaration', () {
    // Same call through a dynamic receiver: the runtime binds correctly today.
    expect(
      _runtime(r'''
        class A { int m([int x = 1]) => x; }
        class B extends A { @override int m([int x = 2]) => x; }
        int main() { dynamic a = B(); return a.m(); }
      ''').executeLib(_library, 'main'),
      2,
    );
  });

  test('named arguments evaluate in source order', () {
    // Dart: logs 'pba' — arguments evaluate in source order.
    expect(
      _runtime(r'''
        var log = <String>[];
        String t(String s) { log.add(s); return s; }
        void f(String p, {String? a, String? b}) {}
        String main() {
          f(t('p'), b: t('b'), a: t('a'));
          return log.join('');
        }
      ''').executeLib(_library, 'main'),
      'pba',
    );
  });

  test('named argument before a positional argument binds', () {
    // Dart: `f(b: 'b', 'p', a: 'a')` is valid — named arguments may
    // precede positional ones and bind by name.
    expect(
      _runtime(r'''
        var log = <String>[];
        String t(String s) { log.add(s); return s; }
        void f(String p, {String? a, String? b}) { log.add('$p$a$b'); }
        String main() {
          f(b: t('b'), t('p'), a: t('a'));
          return log.join('');
        }
      ''').executeLib(_library, 'main'),
      'bpapab',
    );
  });

  test(
    'dynamic named-before-positional calls keep source order and layout',
    () {
      expect(
        _runtime(r'''
        int log = 0;
        int trace(int value) { log = log * 10 + value; return value; }
        class C {
          int f(int value, {int a = 0, int b = 0}) => value * 100 + a * 10 + b;
        }
        int main() {
          dynamic receiver = C();
          final result = receiver.f(
            b: trace(2), trace(1), a: trace(3),
          ) as int;
          return log * 1000 + result;
        }
      ''').executeLib(_library, 'main'),
        213132,
      );
    },
  );

  test('dynamic dispatch keeps the receiver evaluated before arguments', () {
    expect(
      _runtime(r'''
        class First { int f(int value) => 1; }
        class Second { int f(int value) => 2; }
        dynamic receiver = First();
        int swap() { receiver = Second(); return 0; }
        int main() => receiver.f(swap()) as int;
      ''').executeLib(_library, 'main'),
      1,
    );
  });

  test('member-value calls keep the same argument layout', () {
    expect(
      _runtime(r'''
        int log = 0;
        int trace(int value) { log = log * 10 + value; return value; }
        class C {
          int Function(int, {int a, int b}) f =
              (int value, {int a = 0, int b = 0}) =>
                  value * 100 + a * 10 + b;
        }
        int main() {
          final result = C().f(b: trace(2), trace(1), a: trace(3));
          return log * 1000 + result;
        }
      ''').executeLib(_library, 'main'),
      213132,
    );
  });

  test('source arguments retain their values across later assignments', () {
    expect(
      _runtime(r'''
        int f(int a, int b) => a * 10 + b;
        int main() { int x = 1; return f(x, x = 2); }
      ''').executeLib(_library, 'main'),
      12,
    );
    expect(
      _runtime(r'''
        String f(String a, String b) => a + b;
        String main() { String x = 'a'; return f(x, x = 'b'); }
      ''').executeLib(_library, 'main'),
      'ab',
    );
  });

  test(
    'named source arguments retain their values across later assignments',
    () {
      expect(
        _runtime(r'''
        int f({required int a, required int b}) => a * 10 + b;
        int main() { int x = 1; return f(a: x, b: x = 2); }
      ''').executeLib(_library, 'main'),
        12,
      );
    },
  );

  test('closure and dynamic arguments retain their values', () {
    expect(
      _runtime(r'''
        int Function(int, int) f = (a, b) => a * 10 + b;
        int main() { int x = 1; return f(x, x = 2); }
      ''').executeLib(_library, 'main'),
      12,
    );
    expect(
      _runtime(r'''
        dynamic f = (String a, String b) => a + b;
        String main() { String x = 'a'; return f(x, x = 'b') as String; }
      ''').executeLib(_library, 'main'),
      'ab',
    );
    expect(
      _runtime(r'''
        class C { int f(int a, int b) => a * 10 + b; }
        int main() {
          dynamic receiver = C();
          int x = 1;
          return receiver.f(x, x = 2) as int;
        }
      ''').executeLib(_library, 'main'),
      12,
    );
  });
}
