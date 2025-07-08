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
    test('Tree shaking habilitado - enum em campo deve funcionar', () {
      final compiler = Compiler();
      compiler.addPlugin(TreeShakeConfigPlugin(enableTreeShaking: true));

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/model.dart';
            void main() {
              final item = AbcItem('1', 'Test', 100.0);
              print(item.name);
            }
          ''',
          'model.dart': '''
            enum AbcCategory { A, B, C }
            
            class AbcItem {
              final String id;
              final String name;
              final double value;
              AbcCategory? category; // Este enum deve ser mantido
              
              AbcItem(this.id, this.name, this.value, [this.category]);
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });

    test('Tree shaking desabilitado - todas as classes mantidas', () {
      final compiler = Compiler();
      compiler.addPlugin(TreeShakeConfigPlugin(enableTreeShaking: false));

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/model.dart';
            void main() {
              final item = AbcItem('1', 'Test', 100.0);
              print(item.name);
            }
          ''',
          'model.dart': '''
            enum AbcCategory { A, B, C }
            
            class AbcItem {
              final String id;
              final String name;
              final double value;
              AbcCategory? category;
              
              AbcItem(this.id, this.name, this.value, [this.category]);
            }
            
            class UnusedClass {
              // Esta classe não é usada mas deve ser mantida
              void unusedMethod() {}
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });

    test('Método setTreeShaking direto no compilador', () {
      final compiler = Compiler();

      // Teste com tree shaking desabilitado
      compiler.setTreeShaking(false);
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/model.dart';
            void main() {
              final item = AbcItem('1', 'Test', 100.0);
              print(item.name);
            }
          ''',
          'model.dart': '''
            enum AbcCategory { A, B, C }
            
            class AbcItem {
              final String id;
              final String name;
              final double value;
              AbcCategory? category;
              
              AbcItem(this.id, this.name, this.value, [this.category]);
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });
  });
}
