import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
// @dart=3.6
const minimum = -1 * 2097152 * 2097152 * 2097152;
const decimal = -9223372036854775808;
const separated = -0__9__2__2__3__3__7__2__0__3__6__8__5__4__7__7__5__8__0__8;
const hex = -0x8000000000000000;
int defaultMinimum([int value = -9223372036854775808]) => value;
class Holder {
  final int value;
  const Holder([this.value = -9223372036854775808]);
}
bool verify() {
  final value = -9223372036854775808;
  final wrappedHex = -(0x8000000000000001);
  double coerced = -9223372036854775808;
  return value == minimum && decimal == minimum && separated == minimum &&
      hex == minimum && 0x8000000000000000 == minimum &&
      value.toString() == '-9223372036854775808' &&
      value - 1 == 9223372036854775807 &&
      wrappedHex == 9223372036854775807 &&
      defaultMinimum() == minimum && const Holder().value == minimum &&
      coerced == -9223372036854775808.0;
}
void main() {
  if (!verify()) throw StateError('signed int literal boundary');
}
''';

void main() {
  test('direct signed int minimum literal and defaults', () {
    final program = Compiler().compile({
      'int_min': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:int_min/main.dart', 'verify'), true);
      expect(
        runtime.executeLib('package:int_min/main.dart', 'defaultMinimum'),
        -9223372036854775808,
      );
    }
  });
  for (final literal in [
    '9223372036854775808',
    '-9223372036854775809',
    '-(9223372036854775808)',
    '-0x8000000000000001',
    '18446744073709551616',
    '0x10000000000000000',
  ]) {
    test('reject out-of-range int literal $literal', () {
      expect(
        () => Compiler().compile({
          'invalid_int': {'main.dart': 'int main() => $literal;'},
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
