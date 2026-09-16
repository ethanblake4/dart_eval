import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'index assignment calls only the setter and evaluates operands once',
    () {
      final program = Compiler().compile({
        'index': {
          'main.dart': '''
        int effects = 0;
        class Values {
          int stored = 0;
          int operator[](int index) { effects += 100; return stored; }
          void operator[]=(int index, int value) { stored = index + value; }
        }
        int index() { effects += 1; return 2; }
        int value() { effects += 10; return 3; }
        num main() {
          dynamic values = Values();
          final result = values[index()] = value();
          return effects + values.stored + result;
        }
      ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:index/main.dart', 'main'), 19);
      }
    },
  );
}
