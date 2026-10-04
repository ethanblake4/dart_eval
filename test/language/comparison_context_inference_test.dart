import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('comparison operands infer numeric calls in boolean contexts', () {
    final program = Compiler().compile({
      'comparison_context': {
        'main.dart': r'''
import 'dart:math' as math;
T choose<T extends num>(T a, T b) => a;
bool compare() => choose(1, 2) < math.max(2, 3) &&
    choose(2, 1) <= choose(2, 3) && choose(3, 1) > choose(2, 1) &&
    choose(3, 1) >= choose(3, 2);
int verify() {
  var count = 0;
  for (var i = 0; i < math.max([1, 2].length, [3].length); i++) count++;
  return compare() ? count : -1;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:comparison_context/main.dart', 'verify'),
        2,
      );
    }
  });
}
