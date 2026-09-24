import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('prefixed setter supplies the context type for a shorthand value', () {
    final program = Compiler().compile({
      'denotation': {
        'values.dart': '''
          enum Choice { first, second }
          Choice _value = Choice.first;
          int get value => _value.index;
          set value(Choice next) { _value = next; }
        ''',
        'main.dart': '''
          import 'values.dart' as values;
          int main() {
            values.value = .second;
            return values.value;
          }
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:denotation/main.dart', 'main'),
      1,
    );
  });
}
