import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('FutureOr extensions infer payloads and preserve specificity', () {
    final program = Compiler().compile({
      'extensions': {
        'main.dart': '''
import 'dart:async';
extension Payload<T> on FutureOr<T> {
  Type get payloadType => T;
  int get priority => 1;
}
extension Integer on int { int get priority => 2; }
extension IntegerFuture on Future<int> { int get priority => 3; }
Type typeOf<T>() => T;
Type unionType(FutureOr<FutureOr<int>> value) => value.payloadType;
Type nullableType(int? value) => value.payloadType;
Type futureNullableType(Future<int?> value) => value.payloadType;
Type? promotedFutureType(Future<int>? value) => value?.payloadType;
bool main() {
  final int value = 1;
  final Future<int> future = Future<int>.value(1);
  final Future<Future<int>> nested = Future<Future<int>>.value(future);
  final Future<int?> nullableFuture = Future<int?>.value(null);
  return value.payloadType == int && future.payloadType == int &&
      nested.payloadType == typeOf<Future<int>>() &&
      unionType(1) == typeOf<FutureOr<int>>() &&
      nullableType(null) == typeOf<int?>() &&
      futureNullableType(nullableFuture) == typeOf<int?>() &&
      promotedFutureType(future) == int && promotedFutureType(null) == null &&
      value.priority == 2 && future.priority == 3;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:extensions/main.dart', 'main'), true);
    }
  });

  test('nullable Futures require null-aware extension access', () {
    expect(
      () => Compiler().compile({
        'extensions': {
          'main.dart': '''
import 'dart:async';
extension Payload<T> on FutureOr<T> { Type get payloadType => T; }
Type main(Future<int>? value) => value.payloadType;
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
