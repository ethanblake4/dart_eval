import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('custom operators supply substituted operand contexts', () {
    final program = Compiler().compile({
      'operator_context': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:operator_context/main.dart', 'main'),
        true,
      );
    }
  });

  test('custom double operators reject inexact integer literals', () {
    expect(
      () => Compiler().compile({
        'operator_context': {
          'main.dart': '''
            class Oper {
              double operator +(double value) => value;
            }
            double main() => Oper() + 9007199254740993;
          ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}

const _source = r'''
class Oper<T> {
  T operator +(T value) => value;
  T operator >>(T value) => value;
  T operator [](T value) => value;
}
class Wide extends Oper<double> {
  double superValue() => super + 0x10000000000000000;
}
class Marker {}
extension DoubleOperators on Marker {
  double operator *(double value) => value;
}
class Values<T> {
  bool operator +(List<T> values) => values is List<T>;
}
extension ValueOperators<T> on Values<T> {
  bool operator /(List<T> values) => values is List<T>;
}

int calls = 0;
Wide make() { calls++; return Wide(); }

bool main() {
  final value = make() + 9223372036854775808;
  final shift = Wide() >> -0x8000000000000000;
  final index = Wide()[0x8000000000000000];
  final throughSuper = Wide().superValue();
  final extended = Marker() * 18446744073709551616;
  final zero = Wide() + -0;
  return calls == 1 &&
      value == 9223372036854775808.0 &&
      shift == -9223372036854775808.0 && index == value &&
      throughSuper == 18446744073709551616.0 && extended == throughSuper &&
      identical(zero, -0.0) &&
      (Values<int>() + []) && (Values<int>() / []);
}
''';
