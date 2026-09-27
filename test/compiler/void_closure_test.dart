import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('inferred void expression closures do not return a value', () {
    final program = Compiler().compile({
      'void_closure': {
        'main.dart': '''
          int main() {
            final values = <int>[1];
            final append = () => values.add(2);
            append();
            return values.length;
          }
        ''',
      },
    });

    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:void_closure/main.dart', 'main'),
      2,
    );
  });
}
