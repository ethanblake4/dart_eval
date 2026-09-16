import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('global assignments convert integer literals to double storage', () {
    final program = Compiler().compile({
      'global_entry': {
        'main.dart':
            'double value = 1; double main() { value = 2; return value; }',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:global_entry/main.dart', 'main'),
      2.0,
    );
  });
  test('raw machine entry prepares globals from an encoded runtime', () {
    final program = Compiler().compile({
      'global_entry': {'main.dart': 'int value = 7; int main() => ++value;'},
    });
    final runtime = Runtime(program.write().buffer);
    expect(TypedMachine.run(program.typedProgram, runtime: runtime), 8);
    expect(runtime.executeLib('package:global_entry/main.dart', 'main'), 9);
  });

  test('global access without an owning runtime fails explicitly', () {
    final program = Compiler().compile({
      'global_entry': {'main.dart': 'int value = 7; int main() => value;'},
    });
    expect(
      () => TypedMachine.run(program.typedProgram),
      throwsA(isA<StateError>()),
    );
  });
}
