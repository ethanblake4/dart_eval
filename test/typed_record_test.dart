import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'records retain object and null fields across calls and serialization',
    () {
      final program = Compiler().compile({
        'records': {
          'main.dart': r'''
          (int, String?, {List<int> values}) make(int value) {
            return (value, null, values: [value, value + 1]);
          }
          int main() {
            final first = make(3);
            final second = make(8);
            if (first.$2 != null) return -1;
            return first.$1 + second.values[1];
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:records/main.dart', 'main'), 12);
      }
    },
  );
}
