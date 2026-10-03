import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _declaration = r'''
class Envelope<T, U> {
  final T value;
  final U label;
  Envelope(this.value, this.label);
  static Envelope<X, Y> pack<X, Y>(X value, Y label) =>
      Envelope<X, Y>(value, label);
}
''';

void main() {
  test(
    'generic shorthand tearoffs retain context and explicit type arguments',
    () {
      final program = Compiler().compile({
        'shorthand_tearoff': {
          'main.dart': '''$_declaration
bool main() {
  Envelope<int, String> value = .pack<int, String>.call(7, 'seven');
  return value is Envelope<int, String> &&
      value.value == 7 && value.label == 'seven';
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:shorthand_tearoff/main.dart', 'main'),
          true,
        );
      }
    },
  );

  test(
    'generic shorthand tearoffs reject an incorrect type argument count',
    () {
      expect(
        () => Compiler().compile({
          'shorthand_tearoff': {
            'main.dart': '''$_declaration
void main() {
  Envelope value = .pack<int>.call(7, 'seven');
}
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    },
  );

  test('generic shorthand tearoffs still require a context type', () {
    expect(
      () => Compiler().compile({
        'shorthand_tearoff': {
          'main.dart': '''$_declaration
void main() {
  var value = .pack<int, String>.call(7, 'seven');
}
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
