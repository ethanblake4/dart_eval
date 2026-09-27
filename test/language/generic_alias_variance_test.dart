import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectTrue(String source) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test('raw recursive function bounds use alias variance', () {
    _expectTrue('''
      typedef Cov<X extends void Function(X)> = X Function();
      typedef Con<X extends void Function(X)> = void Function(X);
      typedef Inv<X extends void Function(X)> = X Function(X);
      Type typeOf<T>() => T;

      bool main() =>
          typeOf<Cov>() == typeOf<Cov<void Function(Never)>>() &&
          typeOf<Con>() == typeOf<Con<void Function(dynamic)>>() &&
          typeOf<Inv>() == typeOf<Inv<void Function(dynamic)>>();
    ''');
  });

  test('raw recursive nominal bounds use alias variance', () {
    _expectTrue('''
      class A<T> {}
      typedef Cov<X extends A<X>> = X Function();
      typedef Con<X extends A<X>> = void Function(X);
      typedef Inv<X extends A<X>> = X Function(X);
      Type typeOf<T>() => T;

      bool main() =>
          typeOf<Cov>() == typeOf<Cov<A<dynamic>>>() &&
          typeOf<Con>() == typeOf<Con<A<Never>>>() &&
          typeOf<Inv>() == typeOf<Inv<A<dynamic>>>();
    ''');
  });

  test('substituting an outer parameter updates generic function bounds', () {
    final program = Compiler().compile({
      'generic_bound_substitution': {
        'main.dart': '''
          typedef F<X> = void Function<Y extends X>();
          F<X> toF<X>(X source) => throw 0;

          void check(int source) {
            var fs = toF(source);
            F<int> target = fs;
          }

          bool main() {
            check;
            return true;
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
          'package:generic_bound_substitution/main.dart',
          'main',
        ),
        true,
      );
    }
  });
}
