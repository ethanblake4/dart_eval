import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('bridged method tear-offs retain their substituted signatures', () {
    final program = Compiler().compile({
      'tearoff': {
        'main.dart': '''
          void clearWith(void Function() clear) => clear();
          bool addWith(bool Function(int) add) => add(3);

          int main() {
            final values = <int>{1, 2};
            if (!addWith(values.add)) return -1;
            clearWith(values.clear);
            if (values.isNotEmpty) return -2;
            final constant = const <int>{1};
            try {
              clearWith(constant.clear);
            } on UnsupportedError {
              return constant.first;
            }
            return -3;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:tearoff/main.dart', 'main'), 1);
    }
  });
}
