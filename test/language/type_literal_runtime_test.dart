import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';
import '../sdk_language/sdk_language.dart';

void main() {
  test('type object getters preserve Type facts', () {
    final program = Compiler().compile({
      'type_literals': {
        'main.dart': '''
          class C {
            static int get value => 7;
          }
          typedef Alias = C;
          bool generic<T>() => T.runtimeType == Type &&
              T.runtimeType.runtimeType == Type && T.hashCode == T.hashCode;
          bool main() => (dynamic).runtimeType == Type &&
              C.runtimeType == Type && Alias.runtimeType == Type &&
              (List<int>).runtimeType == Type &&
              C.runtimeType.runtimeType == Type && C.hashCode == C.hashCode &&
              C.value == 7 && generic<C>();
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:type_literals/main.dart', 'main'),
        true,
      );
    }
  });
  for (final name in [
    'first_class_types_literals_runtime_1_test.dart',
    'first_class_types_literals_runtime_2_test.dart',
    'first_class_types_literals_runtime_test.dart',
  ]) {
    test('pinned $name runs fresh and serialized', () async {
      final suite = await SdkSuite.load();
      final fixture = suite.classify('type_object/$name');
      final sources = suite.collectSources(fixture);
      final compiler = Compiler();
      setSdkEntrypoints(compiler, fixture, sources);
      final program = compiler.compileSources(sources);
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        await executeSdkMain(runtime, fixture, sources);
      }
    });
  }
}
