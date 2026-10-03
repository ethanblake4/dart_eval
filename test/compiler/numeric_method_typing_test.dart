import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('remainder and clamp preserve their numeric static result types', () {
    expect(
      eval('''
        num n = 7;
        int main() {
          int integer = 7.remainder(3);
          double fractional = n.remainder(2.5);
          int clampedInt = integer.clamp(0, 3);
          double clampedDouble = fractional.clamp(0.0, 1.0);
          return clampedInt + clampedDouble.toInt();
        }
      '''),
      2,
    );
  });

  test('numeric method arguments use the result context', () {
    expect(
      eval('''
        T contextType<T>(Object value) => value as T;
        int main() {
          int remainder = 7.remainder(contextType(3));
          int clamped = remainder.clamp(contextType(0), contextType(2));
          return clamped;
        }
      '''),
      1,
    );
  });

  test('primitive toString preserves formatting and values across calls', () {
    final program = Compiler().compile({
      'numeric_to_string': {
        'main.dart': r'''
String format(int integer, double fraction, bool flag) {
  final integerAlias = integer;
  final fractionAlias = fraction;
  final flagAlias = flag;
  final integerText = integer.toString();
  final fractionText = fraction.toString();
  final flagText = flag.toString();
  return '$integerText|$fractionText|$flagText|' +
      '${integerAlias.toString()}|${fractionAlias.toString()}|${flagAlias.toString()}';
}
''',
      },
    });
    final cases = [
      (integer: -0x8000000000000000, fraction: -0.0, flag: false),
      (integer: 0x7fffffffffffffff, fraction: double.nan, flag: true),
      (integer: 42, fraction: double.infinity, flag: false),
      (integer: -42, fraction: double.negativeInfinity, flag: true),
      (integer: 0, fraction: 0.125, flag: false),
      (integer: 1, fraction: 1e-7, flag: true),
      (integer: -1, fraction: 1e20, flag: false),
    ];

    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      for (final (:integer, :fraction, :flag) in cases) {
        expect(
          runtime.executeLib(
            'package:numeric_to_string/main.dart',
            'format',
            arguments: {'integer': integer, 'fraction': fraction, 'flag': flag},
          ),
          '$integer|$fraction|$flag|$integer|$fraction|$flag',
        );
      }
    }
  });
}
