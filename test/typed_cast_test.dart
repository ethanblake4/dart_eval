import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('casts narrow boxed values and retain nullable scalar storage', () {
    final program = Compiler().compile({
      'cast': {
        'main.dart': '''
        int main(dynamic value) {
          final int? number = value as int?;
          if (number == null) return 7;
          return (number as int) + 1;
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
          'package:cast/main.dart',
          'main',
          arguments: {'value': null},
        ),
        7,
      );
      expect(
        runtime.executeLib(
          'package:cast/main.dart',
          'main',
          arguments: {'value': 4},
        ),
        5,
      );
      expect(
        () => runtime.executeLib(
          'package:cast/main.dart',
          'main',
          arguments: {'value': 'bad'},
        ),
        throwsA(anything),
      );
    }
  });
}
