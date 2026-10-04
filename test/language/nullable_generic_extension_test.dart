import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('nullable extension patterns infer non-null bounded parameters', () {
    final program = Compiler().compile({
      'nullable_extension': {
        'main.dart': r'''
          extension NullableValues<T extends Object> on Iterable<T?> {
            T echo(T value) => value;
          }
          class Item {}
          bool main() {
            final item = Item();
            int number = <int?>[1, null].echo(3);
            Item result = <Item?>[item, null].echo(item);
            int nonNullable = <int>[1].echo(4);
            return number == 3 && identical(item, result) && nonNullable == 4;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:nullable_extension/main.dart', 'main'),
        true,
      );
    }
  });

  test(
    'nullable patterns still reject receiver arguments outside the bound',
    () {
      expect(
        () => Compiler().compile({
          'nullable_extension': {
            'main.dart': r'''
            extension NullableNumbers<T extends num> on Iterable<T?> {
              T echo(T value) => value;
            }
            String main() => <String?>['a', null].echo('b');
          ''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    },
  );
}
