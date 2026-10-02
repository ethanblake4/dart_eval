import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('generic callback inference completes schema holes before metadata', () {
    final program = Compiler().compile({
      'inference': {
        'main.dart': '''
          Never never() => throw '!';

          bool main() {
            final bottom = (<F>(F Function() f) => F)(() => throw never());
            final identity = (<F>(F Function(F) f) => f)((value) => value);
            final asyncCallback =
                (<F>(Future<F> Function() f) => f)(() async => 1);
            return bottom == Never && identity(1) == 1 &&
                asyncCallback() is Future<int>;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:inference/main.dart', 'main'), true);
    }
  });

  test(
    'generic local calls infer collection elements through context holes',
    () {
      final program = Compiler().compile({
        'inference': {
          'main.dart': '''
          import 'dart:async';

          bool main() {
            Object setContext<T>(Set<T> value) => value;
            Object iterableContext<T>(Iterable<T> value) => value;
            Object futureContext<T>(FutureOr<Set<T>> value) => value;
            Object mapContext<K, V>(Map<K, V> value) => value;
            return setContext(const {1}) is Set<int> &&
                iterableContext(const {1}) is Set<int> &&
                futureContext(const {1}) is Set<int> &&
                iterableContext(const [1]) is List<int> &&
                mapContext(const {'key': 1}) is Map<String, int> &&
                setContext<num>(const {1}) is Set<num> &&
                setContext(const {}) is Set<dynamic>;
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:inference/main.dart', 'main'), true);
      }
    },
  );
}
