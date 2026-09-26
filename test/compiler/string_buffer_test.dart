import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'StringBuffer writes native strings alongside boxed and null values',
    () {
      final program = Compiler().compile({
        'buffer': {
          'main.dart': '''
        String main(String text) {
          final buffer = StringBuffer();
          buffer.write(text + '!');
          buffer.write(text.substring(1));
          Object boxed = 'boxed';
          buffer.write(boxed);
          buffer.write(null);
          buffer.write(42);
          return buffer.toString();
        }
      ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib(
            'package:buffer/main.dart',
            'main',
            arguments: {'text': 'abc'},
          ),
          'abc!bcboxednull42',
        );
      }
      // The Object assignment and the bridged one-argument substring call need
      // wrappers. Native StringBuffer writes do not.
      expect(
        program.typedProgram.instructions.where(
          (entry) => entry.$2.name == 'rBoxString',
        ),
        hasLength(2),
      );
    },
  );
}
