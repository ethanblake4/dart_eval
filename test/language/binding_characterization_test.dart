import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

// Characterization tests for the three confirmed argument-binding bugs
// documented in docs/compiler-model-refactor.md ("Confirmed bugs").
// They assert TODAY'S outcomes on purpose so phases 0-6 flag any drift;
// phase 7 flips them to the Dart-correct expectations.

const _library = 'package:binding/main.dart';

Runtime _runtime(String source) {
  final program = Compiler().compile({
    'binding': {'main.dart': source},
  });
  return Runtime.ofProgram(program);
}

void main() {
  test('overridden default comes from the static declaration, not the dispatch', () {
    // Dart: uses x = 2 (B.m). dart_eval today: uses x = 1 (A.m), because
    // defaults are bound from the static declaration's formals.
    // Phase 7 item 1 (VirtualCall calleeBinds) fixes this.
    expect(
      _runtime(r'''
        class A { int m([int x = 1]) => x; }
        class B extends A { @override int m([int x = 2]) => x; }
        int main() { A a = B(); return a.m(); }
      ''').executeLib(_library, 'main'),
      1,
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

  test('named arguments evaluate in declaration order, not source order', () {
    // Dart: logs 'pba' (source order). dart_eval today: logs 'pab'
    // (declaration order). Phase 7 item 2 (NamedOrder.source) fixes this.
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
      'pab',
    );
  });

  test('named argument before a positional argument is a CompileError today', () {
    // Dart: valid. dart_eval today: CompileError "Not enough positional
    // arguments". Phase 7 item 2 (allowNamedBeforePositional) fixes this.
    expect(
      () => _runtime(r'''
        void f(String p, {String? a, String? b}) {}
        void main() { f(b: 'b', 'p', a: 'a'); }
      '''),
      throwsA(isA<CompileError>()),
    );
  });
}
