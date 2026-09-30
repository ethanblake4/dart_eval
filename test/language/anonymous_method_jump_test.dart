import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
int main() {
  var value = 0;
  outer: for (var i = 0; i < 4; i++) {
    try {
      null.{
        if (i == 1) continue outer;
        if (i == 3) break outer;
        value += 10;
        return;
      };
      value += 1;
    } finally {
      value += 100;
    }
  }
  label: null.{
    value += 1;
    break label;
  };
  value += 2;
  do {
    null.{
      value += 3;
      break;
    };
    value = 999;
  } while (false);
  return value;
}
''';

void main() {
  test('anonymous jumps preserve enclosing labels and finally handlers', () {
    final program = Compiler().compile({
      'anonymous_jump': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:anonymous_jump/main.dart', 'main'),
        428,
      );
    }
  });
}
