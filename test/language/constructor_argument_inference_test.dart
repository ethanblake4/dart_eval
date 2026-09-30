import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _declarations = r'''
class Base<T> {}
class D<T extends num> extends Base<T> {
  final T value;
  D(this.value);
  D.named(this.value);
  factory D.factory(T value) => D<T>(value);
}
class Box<T> {
  final T value;
  Box(this.value);
  Box.named(this.value);
  factory Box.factory(T value) => Box<T>(value);
}
class Defaults<A extends B, B extends num> {
  Defaults();
  bool get matches => A == num && B == num;
}
class Forward<T> extends Box<List<T>> {
  Forward(super.value);
  Forward.named(super.value);
}
''';

void _check(String body) {
  final program = Compiler().compile({
    'constructor_inference': {
      'main.dart': '$_declarations bool main() { $body }',
    },
  });
  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('serialized', Runtime(program.write().buffer)),
  ]) {
    expect(
      runtime.executeLib('package:constructor_inference/main.dart', 'main'),
      true,
      reason: mode,
    );
  }
}

void main() {
  test(
    'bounded constructors infer from values before falling back to bounds',
    () {
      _check(r'''
      final first = D(0);
      final second = new D(1);
      final named = D.named(2);
      final factory = D.factory(3);
      return first is D<int> && second is D<int> &&
          named is D<int> && factory is D<int>;
    ''');
    },
  );

  test(
    'Object contexts leave constructor argument inference unconstrained',
    () {
      _check(r'''
      Object first = D(0);
      Object second = new D(1);
      Object named = D.named(2);
      Object factory = D.factory(3);
      return first is D<int> && second is D<int> &&
          named is D<int> && factory is D<int>;
    ''');
    },
  );

  test('constructor contexts apply before collection arguments compile', () {
    _check(r'''
      Base<num> scalar = D(0);
      Base<Object> broad = D(0);
      Base<dynamic> any = D(0);
      Box<List<num>> first = Box([1]);
      Box<List<num>> second = new Box([2]);
      Box<List<num>> named = Box.named([3]);
      Box<List<num>> factory = Box.factory([4]);
      return scalar is D<num> && scalar is! D<int> &&
          broad is D<num> && broad is! D<int> &&
          any is D<num> && any is! D<int> &&
          first.value is List<num> && first.value is! List<int> &&
          second.value is List<num> && second.value is! List<int> &&
          named.value is List<num> && named.value is! List<int> &&
          factory.value is List<num> && factory.value is! List<int>;
    ''');
  });

  test('unconstrained constructor parameters finalize dependent bounds', () {
    _check('return Defaults().matches && new Defaults().matches;');
  });
  test(
    'super formals retain the subclass parameter through transformed types',
    () {
      _check(r'''
      final first = Forward([1]);
      final second = new Forward([2]);
      final named = Forward.named([3]);
      return first is Forward<int> && first.value.first == 1 &&
          second is Forward<int> && second.value.first == 2 &&
          named is Forward<int> && named.value.first == 3;
    ''');
    },
  );
}
