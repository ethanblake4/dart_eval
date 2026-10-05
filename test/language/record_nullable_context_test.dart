import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  const cases = <String, String>{
    'non-nullable record with nullable fields': '''
      bool main() {
        ({int? data, String? error}) value = (data: null, error: null);
        return value.data == null && value.error == null;
      }
    ''',
    'nullable record without null fields': '''
      bool main() {
        (int,)? value = (1,);
        return value!.\$1 == 1;
      }
    ''',
    'nullable record assignment with null fields': '''
      bool main() {
        ({int? data, String? error})? value;
        value = (data: null, error: null);
        return value.data == null && value.error == null;
      }
    ''',
    'nullable generic nested record field assignment': '''
      class Notification<T> {
        ({({T? prev, T next})? data, ({Object error, StackTrace stack})? error})? value;
        void lock() { value = (data: null, error: null); }
        void update(T next) { value = (error: null, data: (prev: null, next: next)); }
      }
      bool main() {
        final notification = Notification<int>();
        notification.lock();
        if (notification.value!.data != null || notification.value!.error != null) return false;
        notification.update(7);
        return notification.value!.data!.next == 7 && notification.value!.data!.prev == null;
      }
    ''',
    'nullable return context retains numeric field inference': '''
      Type typeOf<T>() => T;
      ({double value})? make() => (value: 1);
      bool main() {
        final value = make()!;
        return value.value == 1.0 && value.runtimeType == typeOf<({double value})>();
      }
    ''',
    'nullable record generic unification': '''
      Type typeOf<T>() => T;
      (T,)? echo<T>((T,)? value) => value;
      bool main() {
        (double,)? downward = echo((1,));
        final upward = echo((2,));
        return downward!.runtimeType == typeOf<(double,)>() &&
            upward!.runtimeType == typeOf<(int,)>() && upward.\$1 == 2;
      }
    ''',
  };

  for (final entry in cases.entries) {
    test(entry.key, () {
      for (final (mode, result) in runDynamicFixture(entry.value)) {
        expect(result, const DynamicFixtureResult.value(true), reason: mode);
      }
    });
  }

  const invalid = <String, String>{
    'wrong field type': '({int value})? value = (value: "wrong");',
    'wrong field name': '({int value})? value = (other: 1);',
    'wrong positional count': '(int,)? value = (1, 2);',
    'null in non-nullable field': '({int value})? value = (value: null);',
    'nullable record into non-nullable record':
        '(int,)? value; (int,) required = value;',
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      expect(
        () => Compiler().compile({
          'records': {'main.dart': 'void main() { ${entry.value} }'},
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }

  test('dynamic nullable record casts retain field and shape checks', () {
    const source = '''
      bool rejects(dynamic value) {
        try {
          final record = value as ({int value})?;
          return false;
        } catch (error) {
          return error is TypeError;
        }
      }
      bool main() {
        dynamic empty = null;
        dynamic valid = (value: 1);
        return (empty as ({int value})?) == null &&
            (valid as ({int value})?)!.value == 1 &&
            rejects((value: 'wrong')) && rejects((other: 1)) &&
            rejects((1,)) && rejects((value: null));
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
