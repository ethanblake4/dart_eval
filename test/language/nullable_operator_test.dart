import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''extension NullableIntAddition on int? {
  int operator +(int other) => (this ?? 0) + other;
}
int add(int? value) => value + 1;
num dynamicOperand(int value, dynamic other) => value + other;
int generic<T extends int?>(T value) => value + 2;
void main() {
  if (add(null) != 1 || add(3) != 4 || generic<int?>(null) != 2) {
    throw StateError('nullable extension operator');
  }
  if (dynamicOperand(1, 2) != 3) throw StateError('dynamic operand');
  int? value;
  if (value != null || !(value == null)) throw StateError('null equality');
}
''';

void main() {
  test('nullable operator receivers use applicable nullable extensions', () {
    final program = Compiler().compile({
      'nullable_operator': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:nullable_operator/main.dart', 'main'),
        null,
      );
    }
  });
  for (final body in [
    'int invalid(int? value, int? replacement) { value ??= replacement; return value + 1; }',
    'int invalid(int? value) { void clear() { value = null; } value ??= 1; clear(); return value + 1; }',
    'int invalid<T extends int?>(T value) => value + 1;',
    'num invalid(int left, int? right) => left + right;',
  ]) {
    test('nullable builtin operator receiver is rejected: $body', () {
      expect(
        () => Compiler().compile({
          'nullable_operator': {'main.dart': '$body void main() {}'},
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
