import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('unbound closures discard runtime defaults for context-free calls', () {
    final program = Compiler().compile({
      'defaults': {
        'main.dart': 'dynamic main() => <T extends num>() => T;',
      },
    });
    final typed = program.typedProgram;
    final index = typed.closures.indexWhere(
      (descriptor) => descriptor.typeParameterBounds.isNotEmpty,
    );
    final closure = TypedClosure.create(typed, index, [], null, null, []);
    final runtime = Runtime.ofProgram(program);
    expect(closure.typeArgumentsForCall([], runtime), hasLength(1));
    expect(closure.entryTypeArguments, hasLength(1));
    expect(closure.typeArgumentsForCall([], null), isEmpty);
    expect(closure.entryTypeArguments, isEmpty);
    expect(closure.typeArgumentsForCall([], runtime), hasLength(1));
  });
}
