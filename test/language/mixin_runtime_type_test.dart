import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('folded mixin tear-offs retain declared covariance at runtime', () {
    final program = Compiler().compile({
      'mixin_runtime_type': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:mixin_runtime_type/main.dart', 'verify'),
        true,
      );
    }
  });
}

const _source = r'''
Type typeOf<T>() => T;

abstract class A<T> {}
class B {}

mixin M<T> on A<T> {
  T positional(T value) => value;
  T named({required T value}) => value;
  T Function() producer(T Function() value) => value;
  void consumer(void Function(T) value) {}
  U shadow<U>(U value) => value;
  Type parameterType() => T;
}
class Applied extends A<B> with M {}
class Alias = A<B> with M;
class Explicit extends A<B> with M<B> {}
mixin Free<T> {
  T positional(T value) => value;
}
class Unconstrained with Free {}

bool verify() {
  final applied = Applied();
  final alias = Alias();
  final explicit = Explicit();
  B Function(B) positional = applied.positional;
  B Function({required B value}) named = applied.named;
  final value = B();
  if (!identical(positional(value), value) ||
      !identical(named(value: value), value)) return false;
  if (applied.parameterType() != B || alias.parameterType() != B) return false;
  if (applied.positional.runtimeType != typeOf<B Function(Object?)>()) return false;
  if (alias.positional.runtimeType != typeOf<B Function(Object?)>()) return false;
  if (explicit.positional.runtimeType != typeOf<B Function(Object?)>()) return false;
  if (Unconstrained().positional.runtimeType != typeOf<dynamic Function(Object?)>()) {
    return false;
  }
  if (applied.named.runtimeType != typeOf<B Function({required Object? value})>()) {
    return false;
  }
  if (applied.producer.runtimeType != typeOf<B Function() Function(Object?)>()) {
    return false;
  }
  // A negative occurrence of the class parameter is not erased.
  if (applied.consumer.runtimeType != typeOf<void Function(void Function(B))>()) {
    return false;
  }
  // A method's own generic parameter is not a class parameter.
  if (applied.shadow.runtimeType != typeOf<U Function<U>(U)>()) return false;
  dynamic callable = applied.positional;
  try {
    callable('wrong');
    return false;
  } on TypeError {}
  return true;
}

void main() {
  if (!verify()) throw StateError('folded mixin runtime function type');
  print('folded mixin erasure passed');
}

''';
