import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';

void main() {
  group('Debug tree-shaking', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Simple tree-shaking test', () {
      // Classe B é usada, classe C não é usada
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/b1.dart';
            int main() {
              final b = ClassB();
              return b.number();
            }
          ''',
          'b1.dart': '''
            class ClassB {
              ClassB();
              int number() { return 4; }
            }
            class ClassC {
              ClassC();
              int number() { 
                // Esta classe não deveria ser compilada
                return 10;
              }
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 4);
    });

    test('Tree-shaking with invalid variable', () {
      // Classe B é usada, classe C não é usada (tem variável inválida)
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/b1.dart';
            int main() {
              final b = ClassB();
              return b.number();
            }
          ''',
          'b1.dart': '''
            class ClassB {
              ClassB();
              int number() { return 4; }
            }
            class ClassC {
              ClassC();
              int number() { 
                invalidVariable.makeError(); // Não deveria ser compilado
                return 10;
              }
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 4);
    });
  });
}
