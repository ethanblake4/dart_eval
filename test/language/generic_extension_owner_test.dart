import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('extension receiver inference enforces substituted bounds', () {
    const source = '''
      extension Fallback on Object {
        String get numeric => 'fallback';
        String get recursive => 'fallback';
      }
      extension Numeric<T extends num> on List<T> {
        String get numeric => 'numeric';
      }
      class Rec<T extends Rec<T>> {}
      class Solution extends Rec<Solution> {}
      extension Recursive<T extends Rec<T>> on T {
        String get recursive => 'recursive';
      }
      bool main() => <Object>[1].numeric == 'fallback' &&
          <num>[1].numeric == 'numeric' &&
          <int>[1].numeric == 'numeric' &&
          Object().recursive == 'fallback' &&
          Solution().recursive == 'recursive' &&
          Recursive(Solution()).recursive == 'recursive';
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('repeated extension parameters join receiver argument types', () {
    const source = '''
      class Pair<A, B> {
        final A first;
        final B second;
        Pair(this.first, this.second);
      }
      extension Common<T> on Pair<T, T> {
        Type get commonType => T;
        List<T> get values => <T>[first, second];
      }
      bool main() {
        Pair<int, double> inferred = Pair(1, 2.5);
        final forward = Pair<int, num>(1, 2.5);
        final reverse = Pair<num, int>(2.5, 1);
        return inferred.commonType == num &&
            Common(inferred).commonType == num &&
            inferred.values is List<num> && inferred.values is! List<int> &&
            forward.commonType == num && reverse.commonType == num &&
            Common(forward).values is List<num>;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

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
