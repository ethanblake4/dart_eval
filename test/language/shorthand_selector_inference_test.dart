import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
class C<T> {
  final Type type;
  final Type? sourceType;
  final Type? castType;
  C(this.type, {this.sourceType, this.castType});
  static C<X> foo<X>(X value) => C<X>(X, sourceType: X);
  C<U> cast<U>() => C<U>(U, sourceType: sourceType, castType: U);
  C<T> get self => this;
  C<T> operator [](int index) => this;
}
String main() {
  C<num> direct = .foo(1);
  C<bool> chained = .foo('s').cast();
  C<num> explicit = .foo<int>(1);
  C<num> indexed = .foo(1)[0];
  C<num> property = .foo(1).self;
  C<num> asserted = .foo(2)!;
  C<bool> assertedChain = .foo('b')!.cast();
  return '${direct.sourceType}/${direct.type}\n'
      '${chained.sourceType}/${chained.castType}/${chained.type}\n'
      '${explicit.sourceType}/${explicit.type}\n'
      '${indexed.sourceType}/${indexed.type}\n'
      '${property.sourceType}/${property.type}\n'
      '${asserted.sourceType}/${asserted.type}\n'
      '${assertedChain.sourceType}/${assertedChain.castType}';
}
''';

void main() {
  test('shorthand receiver inference uses its own expression context', () {
    final program = Compiler().compile({
      'shorthand': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:shorthand/main.dart', 'main'),
        'num/num\nString/bool/bool\nint/int\nint/int\nint/int\nnum/num\n'
        'String/bool',
      );
    }
  });
  test('parenthesized receiver does not inherit a shorthand namespace', () {
    expect(
      () => Compiler().compile({
        'shorthand': {
          'main.dart': '''
class C<T> {
  static C<X> foo<X>(X value) => C<X>();
  C<U> cast<U>() => C<U>();
}
void main() { C<bool> value = (.foo('s')).cast(); }
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
