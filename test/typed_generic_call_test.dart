import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('inferred generic return type retains the declared callee ABI', () {
    final program = Compiler().compile({
      'generic': {
        'main.dart': '''
        T larger<T extends num>(T a, T b) => a > b ? a : b;
        int main() => larger(2, 5) + 1;
      ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:generic/main.dart', 'main'), 6);
    }
  });
}
