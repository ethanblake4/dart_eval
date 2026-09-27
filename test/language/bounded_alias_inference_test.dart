import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _declarations = r'''
  class C<X extends Iterable<num>> {
    C(this.expected);
    final Type expected;
    bool get matches => X == expected;

    factory C.factory(Type expected) => D<X>(expected);
    factory C.redirect(Type expected) = D<X>;
  }

  class D<X extends Iterable<num>> extends C<X> {
    D(super.expected);
  }

  typedef T<X extends int> = C<List<X>>;
  Type typeOf<X>() => X;
''';

void check(String constructor) {
  final program = Compiler().compile({
    'bounded_alias': {
      'main.dart':
          '''
        $_declarations
        int main() {
          final expected = typeOf<List<int>>();
          C<Iterable<num>> contextual = T$constructor(expected);
          return contextual.matches ? 1 : 0;
        }
      ''',
    },
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:bounded_alias/main.dart', 'main'), 1);
  }
}

void main() {
  test('unused alias parameters still constrain inferred arguments', () {
    final program = Compiler().compile({
      'unused_alias': {
        'main.dart': '''
          class C<A> { bool get matches => A == int; }
          typedef T<X extends Y, Y extends int> = C<X>;
          bool main() {
            C<num> value = T();
            return value.matches;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:unused_alias/main.dart', 'main'),
        true,
      );
    }
  });

  test('recursive alias bounds produce finite default type arguments', () {
    final program = Compiler().compile({
      'recursive_alias': {
        'main.dart': '''
          class C<A, B> {}
          typedef Self<X extends Comparable<X>, Y> = C<X, Y>;
          typedef Mutual<X extends Iterable<Y>, Y extends Iterable<X>> = C<X, Y>;
          typedef Contra<X extends void Function(X)> = C<X, dynamic>;
          Type typeOf<T>() => T;
          bool main() => Self == typeOf<C<Comparable<dynamic>, dynamic>>() &&
              Mutual == typeOf<C<Iterable<dynamic>, Iterable<dynamic>>>() &&
              Contra == typeOf<C<void Function(Never), dynamic>>();
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:recursive_alias/main.dart', 'main'),
        true,
      );
    }
  });

  test('dependent alias bounds constrain earlier parameters', () {
    final program = Compiler().compile({
      'dependent_alias': {
        'main.dart': '''
          class C<A, B> {
            bool get matches => A == int && B == int;
          }
          typedef T<X extends Y, Y extends int> = C<X, Y>;
          bool main() {
            C<num, num> value = T();
            return value.matches;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:dependent_alias/main.dart', 'main'),
        true,
      );
    }
  });

  test('bounded alias instance creation retains its type argument', () {
    check('');
  });

  test('bounded alias factory invocation retains its type argument', () {
    check('.factory');
  });

  test('bounded alias redirecting factory retains its type argument', () {
    check('.redirect');
  });
}
