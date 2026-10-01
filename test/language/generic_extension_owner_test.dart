import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('anonymous generic extensions retain separate parameter scopes', () {
    const source = '''
      import 'dart:async';
      extension<T> on FutureOr<T> { Type get payloadType => T; }
      extension<R, A> on R Function(A) {
        Type get resultType => R;
        Type get argumentType => A;
      }
      extension<B> on List<B> {
        Type inspect<C>(C value) => B;
      }
      String stringify(int value) => value.toString();
      String optional([int value = 0, int extra = 0]) => value.toString();
      bool main() => 1.payloadType == int &&
          stringify.resultType == String && stringify.argumentType == int &&
          optional.resultType == String && optional.argumentType == int &&
          <double>[1].inspect<bool>(true) == double;
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('generic extension and method arguments retain distinct owners', () {
    const source = '''
      Type typeOf<X>() => X;

      extension Inspect<T> on List<T> {
        bool check<U>(U value) =>
            typeOf<T>() == int &&
            typeOf<U>() == String &&
            this is List<int> &&
            this is List<T> &&
            value is String &&
            value is U;
      }

      bool main() {
        final values = <int>[1, 2];
        return values.check<String>('direct');
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
