import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
int offset(int line, [int? column]) {
  column ??= 0;
  final result = line + column;
  if (result < 0) throw StateError('negative');
  return result;
}
int drift(int remote, int? now) {
  now ??= 10;
  return remote - now;
}
int? nullable(int? value, int? replacement) {
  value ??= replacement;
  return value;
}
bool verify() => offset(3) == 3 && offset(3, 4) == 7 &&
    drift(13, null) == 3 && nullable(null, null) == null;
void main() {
  if (!verify()) throw StateError('coalescing promotion');
}
''';

void main() {
  test('coalescing assignment joins nonnull local promotions', () {
    final program = Compiler().compile({
      'coalescing_promotion': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:coalescing_promotion/main.dart', 'verify'),
        true,
      );
    }
  });
  for (final body in [
    'int invalid(int? value, int? replacement) { '
        'value ??= replacement; return value; }',
    'int invalid(int? value) { void clear() { value = null; } '
        'value ??= 1; clear(); return value; }',
    'int invalid(int? value, int? replacement) { '
        'value ??= replacement; return value + 1; }',
    'int invalid(int? value) { void clear() { value = null; } '
        'value ??= 1; clear(); return value + 1; }',
  ]) {
    test(
      'coalescing assignment retains nullable or captured writes: $body',
      () {
        expect(
          () => Compiler().compile({
            'coalescing_promotion_invalid': {
              'main.dart': '$body void main() {}',
            },
          }),
          throwsA(isA<CompileError>()),
        );
      },
    );
  }
}
