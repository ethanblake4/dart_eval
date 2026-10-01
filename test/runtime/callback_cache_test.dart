import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('native callbacks are cached by callable identity and signature', () {
    final runtime = Runtime(Uint8List(0).buffer);
    final otherRuntime = Runtime(Uint8List(0).buffer);
    $Value? invoke(
      Runtime runtime,
      $Value? target,
      Object? r,
      Object? s,
      Object? c,
    ) => null;
    final callable = $Function(invoke);
    final equalCallable = $Function(invoke);
    expect(equalCallable, callable);
    var creations = 0;
    void Function() factory(EvalCallable callable) {
      creations++;
      return () => callable.call(runtime, null, null, null, 0);
    }

    final first = runtime.cachedCallback(callable, 'void()', factory);
    final again = runtime.cachedCallback(callable, 'void()', factory);
    expect(again, same(first));
    expect(creations, 1);
    expect(
      runtime.cachedCallback(equalCallable, 'void()', factory),
      isNot(same(first)),
    );
    expect(
      runtime.cachedCallback(callable, 'dynamic()', factory),
      isNot(same(first)),
    );
    expect(
      otherRuntime.cachedCallback(callable, 'void()', factory),
      isNot(same(first)),
    );
  });
}
