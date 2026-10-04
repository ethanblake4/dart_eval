import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('a raw generic extension result selects the next generic extension', () {
    final program = Compiler().compile({
      'sources': {
        'main.dart': '''
          import 'parser.dart';
          bool main() => (Parser<int>() & Parser<int>()).flatten().trim() is Parser<String>;
          bool getter() => Parser<int>().flatten().isString;
          bool tearoff() {
            var method = Parser<int>().flatten().trim;
            return method() is Parser<String>;
          }
          void dynamicResult() { Parser<int>().erase().trim(); }
        ''',
        'parser.dart': '''
          class Parser<T> {}
          extension Sequence on Parser {
            Parser<List<dynamic>> operator &(Parser other) => Parser<List<dynamic>>();
          }
          extension Flatten on Parser {
            Parser<String> flatten() => Parser<String>();
            dynamic erase() => this;
          }
          extension Trim<R> on Parser<R> {
            Parser<R> trim() => this;
            bool get isString => R == String;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      for (final function in ['main', 'getter', 'tearoff']) {
        expect(runtime.executeLib('package:sources/main.dart', function), true);
      }
      expect(
        () => runtime.executeLib('package:sources/main.dart', 'dynamicResult'),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains("has no 'trim'"),
          ),
        ),
      );
    }
  });
}
