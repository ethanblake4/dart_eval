import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  const mapping = '''
    class Mapping {
      const Mapping.named();
      int get value => 42;
    }
  ''';
  final cases = {
    'named constructor in a global initializer': {
      'defaults.dart':
          '''
        final defaultMapping = const Mapping.named();
        $mapping
      ''',
    },
    'import-prefixed named constructor in a global initializer': {
      'defaults.dart': '''
        import 'mapping.dart' as p;
        final defaultMapping = const p.Mapping.named();
      ''',
      'mapping.dart': mapping,
    },
    'generic named constructor in a global initializer': {
      'defaults.dart': '''
        final defaultMapping = const Mapping<int>.named(42);
        class Mapping<T> {
          final T value;
          const Mapping.named(this.value);
        }
      ''',
    },
  };

  for (final entry in cases.entries) {
    test(entry.key, () {
      final program = Compiler().compile({
        'sources': {
          ...entry.value,
          'main.dart': '''
            import 'defaults.dart';
            int main() => defaultMapping.value;
          ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:sources/main.dart', 'main'), 42);
      }
    });
  }
}
