import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
bool main() {
  Comparable<num> integer = 1;
  Comparable<num> decimal = 1.5;
  Comparable<String> text = 'a';
  return integer is Comparable<num> &&
      decimal is Comparable<num> &&
      text is Comparable<String> &&
      integer is! Comparable<String> &&
      text is! Comparable<num>;
}
''';

void main() {
  test('numeric primitives implement Comparable<num>', () {
    final program = Compiler().compile({
      'primitive_comparable': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:primitive_comparable/main.dart', 'main'),
        true,
      );
    }
  });
}
