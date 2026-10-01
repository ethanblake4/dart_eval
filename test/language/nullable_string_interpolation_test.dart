import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
String render(String? value) => 'value=$value';
class ChangingText {
  int reads = 0;
  String? get value {
    reads++;
    return reads == 1 ? 'first' : null;
  }
}
String property(ChangingText text) {
  if (text.value != null) return '<${text.value}>';
  return 'none';
}
bool verify() {
  final text = ChangingText();
  return render(null) == 'value=null' && render('hello') == 'value=hello' &&
      property(text) == '<null>' && text.reads == 2;
}
void main() {
  if (!verify()) throw StateError('nullable string interpolation');
}
''';

void main() {
  test('nullable string interpolation converts each observed value', () {
    final program = Compiler().compile({
      'nullable_string': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:nullable_string/main.dart', 'verify'),
        true,
      );
    }
  });
  test('string concatenation rejects a nullable operand', () {
    expect(
      () => Compiler().compile({
        'nullable_string_invalid': {
          'main.dart':
              "String invalid(String? value) => 'prefix' + value; void main() {}",
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
