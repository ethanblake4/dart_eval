import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
const double numerator = 19.5;
const double denominator = 3.3;
const int quotient = numerator ~/ denominator;

bool main() {
  num number = numerator;
  return quotient == 5 &&
      numerator ~/ denominator == 5 &&
      -numerator ~/ denominator == -5 &&
      numerator ~/ 3 == 6 &&
      number ~/ denominator == 5;
}
''';

void main() {
  test('double truncating division works in globals and expressions', () {
    final program = Compiler().compile({
      'double_truncating_divide': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:double_truncating_divide/main.dart',
          'main',
        ),
        true,
      );
    }
  });
}
