import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('constructor inference keeps wildcard default type argument slots', () {
    final runtime = Compiler().compileWriteAndLoad({
      'wildcard_constructor_inference': {
        'main.dart': '''
          class C<_, T> {
            C(this.value);
            final T value;
          }
          class Bounded<_ extends num, T> {
            Bounded(this.value);
            final T value;
          }
          typedef _ = num;
          class Outer<T, _, U extends _> {}

          Type typeOf<T>() => T;
          bool hasInferredType<T>(T value) =>
              typeOf<T>() == typeOf<C<dynamic, String>>();
          bool hasBoundedType<T>(T value) =>
              typeOf<T>() == typeOf<Bounded<num, String>>();

          bool main() =>
              hasInferredType(C('x')) &&
              hasInferredType(new C('x')) &&
              hasBoundedType(new Bounded('x')) &&
              typeOf<Outer<dynamic, dynamic, num>>() == Outer;
        ''',
      },
    });

    expect(
      runtime.executeLib(
        'package:wildcard_constructor_inference/main.dart',
        'main',
      ),
      isTrue,
    );
  });
}
