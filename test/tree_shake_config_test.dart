import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';

class TreeShakeConfigPlugin extends EvalPlugin {
  final bool enableTreeShaking;

  TreeShakeConfigPlugin({this.enableTreeShaking = true});

  @override
  String get identifier => 'tree_shake_config';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    // Não faz nada na compilação
  }

  @override
  void configureForRuntime(Runtime runtime) {
    // Não faz nada no runtime
  }

  @override
  void configureCompiler(Compiler compiler) {
    compiler.setTreeShaking(enableTreeShaking);
  }
}

void main() {
  group('Tree shaking configuration', () {
    test('Tree shaking habilitado - classe não usada deve gerar erro', () {
      final compiler = Compiler();
      compiler.addPlugin(TreeShakeConfigPlugin(enableTreeShaking: true));

      expect(
          () => compiler.compile({
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
              }),
          returnsNormally); // Deve funcionar pois ClassC não é usada
    });

    test('Tree shaking desabilitado - classe não usada deve gerar erro', () {
      final compiler = Compiler();
      compiler.addPlugin(TreeShakeConfigPlugin(enableTreeShaking: false));

      expect(
          () => compiler.compile({
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
                invalidVariable.makeError(); // Deve ser compilado e gerar erro
                return 10;
              }
            }
          '''
                }
              }),
          throwsA(
              isA<CompileError>())); // Deve gerar erro pois ClassC é compilada
    });

    test('Método setTreeShaking direto no compilador', () {
      final compiler = Compiler();

      // Teste com tree shaking habilitado
      compiler.setTreeShaking(true);
      expect(
          () => compiler.compile({
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
              }),
          returnsNormally);

      // Teste com tree shaking desabilitado
      compiler.setTreeShaking(false);
      expect(
          () => compiler.compile({
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
                invalidVariable.makeError(); // Deve ser compilado e gerar erro
                return 10;
              }
            }
          '''
                }
              }),
          throwsA(isA<CompileError>()));
    });
  });
}
