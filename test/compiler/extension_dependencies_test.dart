import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('a local indexed does not select an unrelated extension getter', () {
    final program = Compiler().compile({
      'sources': {
        'main.dart': '''
          import 'unused.dart';
          int main() {
            var indexed = <int>[7, 8];
            return indexed.firstOrNull!;
          }
        ''',
        'unused.dart': '''
          extension UnusedExtension on String {
            Unused get indexed => Unused();
          }
          class Unused {
            Unused() { throw ConcurrentModificationError(); }
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:sources/main.dart', 'main'), 7);
    }
  });

  for (final name in ['Decode', '']) {
    test(
      'imported ${name.isEmpty ? "unnamed" : "named"} extension dependencies survive tree shaking',
      () {
        final program = Compiler().compile({
          'sources': {
            'main.dart': '''
            import 'decode.dart';
            String main() {
              var indexed = 'hello';
              if (indexed.isEmpty) return '';
              return indexed.decode().text;
            }
          ''',
            'decode.dart':
                '''
            import 'base.dart';
            extension $name on String {
              Result decode([Options? options]) => build(this);
              Unused unused() => Unused();
              Unused get indexed => Unused();
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

  test(
    'implicit extension references survive local shadowing and tear-offs',
    () {
      final program = Compiler().compile({
        'sources': {
          'main.dart': '''
          import 'receiver.dart';
          int main() {
            var receiver = Receiver();
            var direct = receiver.amount;
            var staticMethod = Helpers.staticAmount;
            return receiver.run() + direct + staticMethod();
          }
        ''',
          'receiver.dart': '''
          class Receiver {
            int run() {
              {
                var amount = 20;
                if (amount != 20) return -1;
              }
              var method = extra;
              return amount + method();
            }
          }
          extension Helpers on Receiver {
            int get amount => 3;
            int extra() => 4;
            static int staticAmount() => 5;
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:sources/main.dart', 'main'), 15);
      }
    },
  );
}
