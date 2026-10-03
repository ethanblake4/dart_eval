import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

Program _compile(String source) => Compiler().compile({
  'extension_interfaces': {'main.dart': source},
});

void main() {
  test(
    'implemented Future controls await type and preserves identity',
    () async {
      final program = _compile(r'''
import 'dart:async';
extension type NullableFuture(Future<String> value)
    implements Future<String?> {}
extension type ForwardFuture(Future<String> value)
    implements NullableFuture {}
extension type Number<T extends num>(T value) implements num {}
Future<String?> consume(Future<String?> value) async => await value;
Future<String?> bounded<T extends NullableFuture>(T value) async => await value;
Future<String?> chained<T extends U, U extends NullableFuture>(T value)
    async => await value;
Future<String?> nullableUnion<T extends FutureOr<String?>>(T value)
    async => await value;
num widen(num value) => value;
Future<bool> main() async {
  final future = Future<String>.value('value');
  final wrapper = NullableFuture(future);
  String? value = await wrapper;
  final forward = ForwardFuture(future);
  return identical(wrapper, future) && identical(forward, future) &&
      value == 'value' && await consume(forward) == 'value' &&
      await bounded(wrapper) == 'value' &&
      await chained<NullableFuture, NullableFuture>(wrapper) == 'value' &&
      await nullableUnion<String?>(null) == null &&
      widen(Number<int>(3)) == 3;
}
''');
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          await runtime.executeLib(
            'package:extension_interfaces/main.dart',
            'main',
          ),
          $bool(true),
        );
      }
    },
  );

  test('await retains nullable implemented Future argument', () {
    expect(
      () => _compile(r'''
import 'dart:async';
extension type NullableFuture(Future<String> value)
    implements Future<String?> {}
Future<String> main() async => await NullableFuture(Future.value('value'));
'''),
      throwsA(isA<CompileError>()),
    );
  });

  test('bounded await retains nullable implemented Future argument', () {
    expect(
      () => _compile(r'''
import 'dart:async';
extension type NullableFuture(Future<String> value)
    implements Future<String?> {}
Future<String> invalid<T extends NullableFuture>(T value) async => await value;
void main() {}
'''),
      throwsA(isA<CompileError>()),
    );
  });

  test('chained FutureOr bounds preserve nullable payloads', () {
    expect(
      () => _compile(r'''
import 'dart:async';
Future<String> invalid<T extends U, U extends FutureOr<String?>>(T value)
    async => await value;
void main() {}
'''),
      throwsA(isA<CompileError>()),
    );
  });

  test('interfaces require compatible representation and valid arguments', () {
    for (final source in [
      'extension type Invalid(String value) implements num {}',
      'extension type Invalid(int? value) implements num {}',
      'extension type Invalid(int value) implements num? {}',
      'class B<T extends num> {} '
          'extension type Invalid(B<String> value) implements B<String> {}',
      'class B<T> {} '
          'extension type Invalid(B<int> value) implements B<int, int> {}',
      'extension type Invalid(int value) implements Invalid {}',
      'extension type A(int value) implements B {} '
          'extension type B(int value) implements A {}',
    ]) {
      expect(
        () => _compile('$source void main() {}'),
        throwsA(isA<CompileError>()),
        reason: source,
      );
    }
  });
}
