import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
extension type I(int value) {}

num add(num left, I right) => left + right.value;

int main() {
  if (add(1, I(2)) != 3) throw StateError('representation field');
  return 3;
}
''';

void main() {
  test('representation field keeps its type through a numeric operator', () {
    final program = Compiler().compile({
      'extension_operator': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:extension_operator/main.dart', 'main'),
        3,
      );
    }
  });
}
