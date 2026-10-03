import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

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
}
