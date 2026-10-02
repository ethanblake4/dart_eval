import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
bool main() {
  return Echo.value<int>(42) == int &&
      Echo.value(42) == int &&
      Echo.value<String>('s', extra: 't') == String &&
      Alias.value<double>(1) == double &&
      Defaults.value() == 7 && Defaults.value(input: 2, extra: 3) == 5 &&
      Optional.value() == 5 && Optional.value(8) == 8;
}

enum Echo {
  value;
  Type call<T>(T input, {T? extra}) => T;
}
typedef Alias = Echo;

enum Defaults {
  value;
  int call({int input = 4, int extra = 3}) => input + extra;
}

enum Optional {
  value;
  int call([int input = 5]) => input;
}

''';

void main() {
  test('enum constant calls bind generic arguments and defaults', () {
    final program = Compiler().compile({
      'callable_enum': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:callable_enum/main.dart', 'main'),
        true,
      );
    }
  });
}
