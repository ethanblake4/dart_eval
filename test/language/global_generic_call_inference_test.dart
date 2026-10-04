import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('global generic calls substitute explicit and inferred arguments', () {
    final program = Compiler().compile({
      'global_generic': {
        'helper.dart': r'''
class Box<T> {
  Box(this.value);
  final T value;
  Box<T> end() => this;
}
Box<R> resolve<R>(Box<R> value) => value;
R join<R>(R first, R second) => first;
Box<R> named<R>({required Box<R> value}) => value;
extension TextLength on String {
  int get width => length;
}
extension IntegerBox on Box<int> {
  int get doubled => value * 2;
}
''',
        'main.dart': r'''
import 'helper.dart';
final explicit = resolve<String>(Box<String>('ok')).end();
final inferred = resolve(Box<int>(3)).end();
final widened = join(1, 2.5);
final namedValue = named(value: Box<int>(4));
bool verify() => explicit is Box<String> && explicit.value.width == 2 &&
    inferred is Box<int> && inferred.doubled == 6 && widened is num &&
    namedValue.doubled == 8;
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:global_generic/main.dart', 'verify'),
        true,
      );
    }
  });
}
