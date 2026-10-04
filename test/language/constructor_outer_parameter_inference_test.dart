import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('constructor context retains the caller generic parameter', () {
    final program = Compiler().compile({
      'constructor_context': {
        'main.dart': r'''
import 'dart:async';
abstract class View<T> {}
class CallableView<T> implements View<T> {
  CallableView(this.callable);
  final FutureOr<T> Function() callable;
  bool accepts(Object value) => value is T;
}
View<T> fromCallable<T>(FutureOr<T> Function() callable) => CallableView(callable);
View<T> fromBlock<T>(FutureOr<T> Function() callable) {
  return CallableView(callable);
}
class Factory {
  static View<T> create<T>(FutureOr<T> Function() callable) => CallableView(callable);
}
class ResourceView<T, R> implements View<T> {
  ResourceView({required FutureOr<R> Function() resourceFactory,
      required T Function(R) valueFactory}) : value = valueFactory(resourceFactory() as R);
  final T value;
}
View<T> withResource<T, R>({required FutureOr<R> Function() resourceFactory,
    required T Function(R) valueFactory}) =>
    ResourceView(resourceFactory: resourceFactory, valueFactory: valueFactory);
bool verify() {
  final first = fromCallable<int>(() => 1);
  final second = fromBlock<String>(() => 'ok');
  final third = Factory.create<num>(() => 2);
  final fourth = withResource<int, String>(resourceFactory: () => 'abc',
      valueFactory: (value) => value.length);
  return first is CallableView<int> && second is CallableView<String> &&
      third is CallableView<num> && fourth is ResourceView<int, String> &&
      (fourth as ResourceView<int, String>).value == 3 &&
      (first as CallableView<int>).accepts(2) &&
      !(first as CallableView<int>).accepts('wrong');
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:constructor_context/main.dart', 'verify'),
        true,
      );
    }
  });
}
