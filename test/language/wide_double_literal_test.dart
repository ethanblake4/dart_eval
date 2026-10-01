import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test(
    'wide literals retain exact double values through contexts and codec',
    () {
      final program = Compiler().compile({
        'wide_double': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:wide_double/main.dart', 'main'),
          true,
        );
        expect(
          runtime.executeLib('package:wide_double/main.dart', 'defaultWide'),
          9223372036854775808.0,
        );
        expect(
          identical(
            runtime.executeLib('package:wide_double/main.dart', 'defaultZero'),
            -0.0,
          ),
          true,
        );
      }
    },
  );

  test('double contexts reject precision loss and overflow', () {
    for (final literal in [
      '9007199254740993',
      '9223372036854775807',
      '9223372036854775809',
      '0xFFFFFFFFFFFFFFFF',
      '0x8000000000000001',
      '-9007199254740993',
      '-0x8000000000000001',
      (BigInt.one << 1024).toString(),
    ]) {
      expect(
        () => Compiler().compile({
          'wide_double': {'main.dart': 'double main() => $literal;'},
        }),
        throwsA(isA<CompileError>()),
        reason: literal,
      );
    }
  });

  test('wide decimal tokens remain invalid in integer contexts', () {
    expect(
      () => Compiler().compile({
        'wide_double': {'main.dart': 'int main() => 9223372036854775808;'},
      }),
      throwsA(isA<CompileError>()),
    );
  });
}

const _source = r'''
import 'dart:async';

const double decimal = 18446744073709551616;
const double hexadecimal = 0x10000000000000000;
double widen(double value) => value;
FutureOr<double> wideUnion() => 9223372036854775808;
double defaultWide([double value = 9223372036854775808]) => value;
double defaultZero([double value = -0]) => value;
class Defaults {
  final double value;
  const Defaults([this.value = 0x8000000000000000]);
  double method([double value = 18446744073709551616]) => value;
}

bool main() {
  double positive = 9223372036854775808;
  double negative = -9223372036854775808;
  double highBit = 0x8000000000000000;
  double belowBoundary = 0xFFFFFFFFFFFFF800;
  double? nullable = 9_223_372_036_854_775_808;
  final list = <double>[18446744073709551616, -0x10000000000000000];
  final map = <String, double>{'wide': 0x1_0000_0000_0000_0000};
  final integers = <int>[0xFFFFFFFFFFFFFFFF, 0x8000000000000000];
  final defaults = Defaults();
  final closure = ([double value = -9223372036854775808]) => value;
  final constructor = Defaults.new;
  final method = defaults.method;
  return positive == 9223372036854775808.0 &&
      negative == -9223372036854775808.0 &&
      highBit == positive &&
      belowBoundary == 18446744073709549568.0 &&
      nullable == positive &&
      decimal == 18446744073709551616.0 &&
      hexadecimal == decimal &&
      list[0] == decimal && list[1] == -decimal &&
      map['wide'] == decimal &&
      widen(0x8000000000000000) == positive &&
      wideUnion() == positive &&
      defaultWide() == positive && identical(defaultZero(), -0.0) &&
      defaults.value == positive && constructor().value == positive &&
      method() == decimal && closure() == negative &&
      integers[0] == -1 && (integers[1] + 0x7FFFFFFFFFFFFFFF) == -1;
}
''';
