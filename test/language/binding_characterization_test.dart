import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
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
  test('overridden default comes from the dispatch, not the static declaration', () {
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
  });

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
}
