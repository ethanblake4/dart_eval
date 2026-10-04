import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';

void main() {
  for (final unaryFirst in [false, true]) {
    test('unary and binary minus satisfy interfaces in either order '
        '(unary first: $unaryFirst)', () {
      final unary = 'int operator -() => -value;';
      final binary = 'int operator -(Object other) => value - (other as int);';
      final methods = unaryFirst ? '$unary $binary' : '$binary $unary';
      final program = Compiler().compile({
        'operators': {
          'main.dart':
              '''
            abstract class Operators {
              int operator -();
              int operator -(Object other);
            }
            class Both implements Operators {
              int value = 8;
              $methods
            }
            class Base {
              int value = 8;
              $methods
            }
            class Inherited extends Base implements Operators {}
            mixin RequiredOperators {
              int operator -();
              int operator -(Object other);
            }
            class Mixed extends Base with RequiredOperators {}
            mixin ConcreteOperators {
              int get value => 8;
              $methods
            }
            class Overridden extends Base with ConcreteOperators {}
            bool main() {
              for (final receiver in [Both(), Inherited(), Mixed(), Overridden()]) {
                dynamic operand = receiver;
                if (-operand != -8 || operand - 3 != 5) return false;
              }
              Operators typed = Both();
              return -typed == -8 && typed - 3 == 5;
            }
          ''',
        },
      });
      for (final (kind, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('serialized', Runtime(program.write().buffer)),
      ]) {
        expect(
          runtime.executeLib('package:operators/main.dart', 'main'),
          true,
          reason: kind,
        );
      }
    });
  }

  for (final implementation in [
    'String operator -() => "wrong"; int operator -(Object other) => 1;',
    'int operator -() => 1; int operator -(String other) => 1;',
  ]) {
    test('minus interface rejects incompatible signature: $implementation', () {
      expect(
        () => Compiler().compile({
          'operators': {
            'main.dart':
                '''
              abstract class Operators {
                int operator -();
                int operator -(Object other);
              }
              class Invalid implements Operators {
                $implementation
              }
              int main() => 0;
            ''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
