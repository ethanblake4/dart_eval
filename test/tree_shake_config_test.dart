import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

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

class SpecificLibraryTreeShakePlugin extends EvalPlugin {
  final List<String> excludedLibraries;

  SpecificLibraryTreeShakePlugin({this.excludedLibraries = const []});

  @override
  String get identifier => 'specific_library_tree_shake';

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
    // Plugin exclui apenas suas bibliotecas específicas do tree shaking
    compiler.excludeLibrariesFromTreeShaking(excludedLibraries);
  }
}

class AutoExcludePlugin extends EvalPlugin {
  @override
  String get identifier => 'auto_exclude_plugin';

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
    // Plugin se auto-exclui do tree shaking
    compiler.excludePluginFromTreeShaking(identifier);
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

    test('Plugin exclui biblioteca específica do tree shaking', () {
      final compiler = Compiler();

      // Plugin que exclui apenas a biblioteca model.dart do tree shaking
      compiler.addPlugin(SpecificLibraryTreeShakePlugin(
          excludedLibraries: ['package:example/model.dart']));

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/model.dart';
            import 'package:example/utils.dart';
            void main() {
              final item = AbcItem('1', 'Test', 100.0);
              print(item.name);
              // Não usa nada de utils.dart intencionalmente
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
            
            class UnusedModelClass {
              // Esta classe não é usada mas deve ser mantida porque
              // a biblioteca está excluída do tree shaking
              void unusedMethod() {}
            }
          ''',
          'utils.dart': '''
            class UnusedUtilClass {
              // Esta classe não é usada e DEVE ser removida por tree shaking
              // porque utils.dart não está excluída
              void unusedUtilMethod() {}
            }
            
            void unusedFunction() {
              // Esta função também deve ser removida
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });

    test('Múltiplos plugins podem excluir diferentes bibliotecas', () {
      final compiler = Compiler();

      // Plugin 1 exclui model.dart
      compiler.addPlugin(SpecificLibraryTreeShakePlugin(
          excludedLibraries: ['package:example/model.dart']));

      // Plugin 2 exclui service.dart
      compiler.addPlugin(SpecificLibraryTreeShakePlugin(
          excludedLibraries: ['package:example/service.dart']));

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
            class AbcItem {
              final String id;
              final String name;
              final double value;
              
              AbcItem(this.id, this.name, this.value);
            }
            
            class UnusedModelClass {
              // Mantida porque model.dart está excluída
              void unusedMethod() {}
            }
          ''',
          'service.dart': '''
            class UnusedServiceClass {
              // Mantida porque service.dart está excluída
              void unusedServiceMethod() {}
            }
          ''',
          'utils.dart': '''
            class UnusedUtilClass {
              // Removida porque utils.dart NÃO está excluída
              void unusedUtilMethod() {}
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });

    test('Controle granular - tree shaking habilitado mas com exclusões', () {
      final compiler = Compiler();

      // Tree shaking globalmente habilitado
      expect(compiler.enableTreeShaking, isTrue);

      // Mas excluir bibliotecas específicas
      compiler.excludeLibraryFromTreeShaking('package:example/preserve.dart');
      compiler.excludeLibrariesFromTreeShaking([
        'package:example/also_preserve.dart',
        'package:other/preserve_this_too.dart'
      ]);

      // Verificar que as exclusões foram registradas
      expect(compiler.treeShakeExcludedLibraries,
          contains('package:example/preserve.dart'));
      expect(compiler.treeShakeExcludedLibraries,
          contains('package:example/also_preserve.dart'));
      expect(compiler.treeShakeExcludedLibraries,
          contains('package:other/preserve_this_too.dart'));

      // Limpar exclusões
      compiler.clearTreeShakingExclusions();
      expect(compiler.treeShakeExcludedLibraries, isEmpty);

      // Adicionar e remover individual
      compiler.excludeLibraryFromTreeShaking('package:example/temp.dart');
      expect(compiler.treeShakeExcludedLibraries,
          contains('package:example/temp.dart'));

      compiler.includeLibraryInTreeShaking('package:example/temp.dart');
      expect(compiler.treeShakeExcludedLibraries,
          isNot(contains('package:example/temp.dart')));
    });

    test('Plugin se exclui completamente do tree shaking', () {
      final compiler = Compiler();

      // Plugin que se exclui por completo
      compiler.addPlugin(
          SpecificLibraryTreeShakePlugin()); // Simula um plugin normal

      // Simular que o plugin se auto-exclui
      compiler.excludePluginFromTreeShaking('specific_library_tree_shake');

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
            class AbcItem {
              final String id;
              final String name;
              final double value;
              
              AbcItem(this.id, this.name, this.value);
            }
            
            class UnusedModelClass {
              // Esta classe deve ser mantida porque o plugin foi excluído
              void unusedMethod() {}
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });

    test('Controle de plugins - adicionar, remover, limpar', () {
      final compiler = Compiler();

      // Tree shaking habilitado, nenhum plugin excluído inicialmente
      expect(compiler.enableTreeShaking, isTrue);
      expect(compiler.treeShakeExcludedPlugins, isEmpty);

      // Excluir um plugin
      compiler.excludePluginFromTreeShaking('plugin1');
      expect(compiler.treeShakeExcludedPlugins, contains('plugin1'));

      // Excluir múltiplos plugins
      compiler.excludePluginsFromTreeShaking(['plugin2', 'plugin3']);
      expect(compiler.treeShakeExcludedPlugins, contains('plugin1'));
      expect(compiler.treeShakeExcludedPlugins, contains('plugin2'));
      expect(compiler.treeShakeExcludedPlugins, contains('plugin3'));

      // Remover um plugin da exclusão
      compiler.includePluginInTreeShaking('plugin2');
      expect(compiler.treeShakeExcludedPlugins, contains('plugin1'));
      expect(compiler.treeShakeExcludedPlugins, isNot(contains('plugin2')));
      expect(compiler.treeShakeExcludedPlugins, contains('plugin3'));

      // Verificar que temos 2 plugins excluídos agora
      expect(compiler.treeShakeExcludedPlugins.length, equals(2));
    });

    test('Plugin auto-exclusão durante configuração', () {
      final compiler = Compiler();

      // Plugin que se auto-exclui no configureCompiler
      final autoExcludePlugin = AutoExcludePlugin();
      compiler.addPlugin(autoExcludePlugin);

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            void main() {
              print('Test auto-exclude plugin');
            }
          '''
        }
      });

      // Verificar que o plugin se auto-excluiu APÓS a compilação
      // (a configuração ocorre durante compile())
      expect(
          compiler.treeShakeExcludedPlugins, contains('auto_exclude_plugin'));

      final runtime = Runtime.ofProgram(program);
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          returnsNormally);
    });
  });
}
