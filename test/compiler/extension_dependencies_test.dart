import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  for (final name in ['Decode', '']) {
    test(
      'imported ${name.isEmpty ? "unnamed" : "named"} extension dependencies survive tree shaking',
      () {
        final program = Compiler().compile({
          'sources': {
            'main.dart': '''
            import 'decode.dart';
            String main() => 'hello'.decode().text;
          ''',
            'decode.dart':
                '''
            import 'base.dart';
            extension $name on String {
              Result decode([Options? options]) => build(this);
              Unused unused() => Unused();
            }
            extension ResultBuilder on String {
              Result makeResult() => Result(this);
            }
            class Options {}
            class Result extends Base {
              Result(String text) : super(text);
            }
            Result build(String text) => text.makeResult();
            class Unused {
              Unused() { throw ConcurrentModificationError(); }
            }
          ''',
            'base.dart': '''
            class Base {
              final String text;
              Base(this.text);
            }
          ''',
          },
        });
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          expect(
            runtime.executeLib('package:sources/main.dart', 'main'),
            'hello',
          );
        }
      },
    );
  }
}
