import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
bool bounded<X extends Null, Y extends Never>() {
  int Function(X) x = (value) => value == 'x' ? 1 : 0;
  int Function(Y) y = (value) => value == 'y' ? 2 : 0;
  return (x as dynamic)('x') == 1 && (y as dynamic)('y') == 2;
}

bool main() {
  int Function(Null) bottom = (value) => value == 'value' ? 3 : 0;
  int Function(Never) never = (value) => value == 42 ? 4 : 0;
  int Function({required Null value}) named =
      ({required value}) => value == true ? 5 : 0;
  int Function(Null) explicitNull = (Null value) => 6;
  int Function(Never) explicitNever = (Never value) => 7;
  int Function(String) ordinary = (value) => value.length;
  return bottom is int Function(Object?) &&
      never is int Function(Object?) &&
      named is int Function({required Object? value}) &&
      (bottom as dynamic)('value') == 3 &&
      (never as dynamic)(42) == 4 &&
      (named as dynamic)(value: true) == 5 &&
      explicitNull is! int Function(String) &&
      explicitNever is! int Function(Null) &&
      ordinary is! int Function(Object?) &&
      ordinary('dart') == 4 &&
      bounded<Null, Never>() && bounded<Never, Never>();
}
''';

void main() {
  test('unannotated bottom closure contexts infer Object?', () {
    final program = Compiler().compile({
      'closure_bottom': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:closure_bottom/main.dart', 'main'),
        true,
      );
    }
  });
}
