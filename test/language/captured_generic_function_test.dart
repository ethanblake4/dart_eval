import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('captured local functions retain their own generic bounds', () {
    final program = Compiler().compile({
      'captured_generics': {
        'main.dart': '''
          int main() {
            T number<T extends num>(T value) => value;
            B text<A extends String, B extends A>(A first, B second) => second;
            final callNumber = () => number<int>(2);
            final callText = () => text<String, String>('first', 'last');
            return callNumber() + callText().length;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:captured_generics/main.dart', 'main'),
        6,
      );
    }
  });
}
