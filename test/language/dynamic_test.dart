import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectValue(String source, Object? expected) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.value(expected), reason: mode);
  }
}

void _expectError(String source, Type expected) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.error(expected), reason: mode);
  }
}

void main() {
  group('checked dynamic conversions', () {
    test('guest code catches TypeError and still runs finally', () {
      _expectValue('''
        class A {}
        String main() {
          var trace = '';
          try {
            dynamic value = 'bad';
            A destination = value;
            trace += 'body';
          } on TypeError {
            trace += 'type';
          } finally {
            trace += ':finally';
          }
          return trace;
        }
      ''', 'type:finally');
    });

    test('checks a declaration before an unused destination write', () {
      _expectError('''
        class A {}
        int main() {
          dynamic value = 'bad';
          A destination = value;
          return 1;
        }
      ''', TypeError);
    });

    test('checks an assignment before an unused destination write', () {
      _expectError('''
        class A {}
        int main() {
          A destination = A();
          dynamic value = 'bad';
          destination = value;
          return 1;
        }
      ''', TypeError);
    });

    test('a reassigned dynamic value still downcasts at runtime', () {
      _expectError('''
        class A {}
        int main() {
          dynamic value = 1;
          value = 'bad';
          A destination = value;
          return 1;
        }
      ''', TypeError);
    });

    test('checks a direct-call argument before entering the body', () {
      _expectValue('''
        class A {}
        int called = 0;
        int consume(A value) {
          called++;
          return called;
        }
        int main() {
          dynamic value = 'bad';
          try {
            consume(value);
          } catch (_) {
            return called;
          }
          return 99;
        }
      ''', 0);
    });

    test('checks dynamic conditions without truthiness', () {
      _expectError('''
        int main() {
          dynamic value = 1;
          if (value) return 1;
          return 0;
        }
      ''', TypeError);
    });

    test('checks a dynamic method argument before entering the body', () {
      _expectValue('''
        class A {}
        int called = 0;
        class Receiver {
          int consume(A value) {
            called++;
            return called;
          }
        }
        int main() {
          dynamic receiver = Receiver();
          dynamic value = 'bad';
          try {
            receiver.consume(value);
          } catch (_) {
            return called;
          }
          return 99;
        }
      ''', 0);
    });

    test('checks an exact closure argument before entering the body', () {
      _expectValue('''
        class A {}
        int main() {
          var called = 0;
          int Function(A) closure = (A value) {
            called++;
            return called;
          };
          dynamic value = 'bad';
          try {
            closure(value);
          } catch (_) {
            return called;
          }
          return 99;
        }
      ''', 0);
    });

    test('checks a dynamic setter before entering its body', () {
      _expectValue('''
        class A {}
        int called = 0;
        class Receiver {
          set value(A value) { called++; }
        }
        int main() {
          dynamic receiver = Receiver();
          dynamic value = 'bad';
          try {
            receiver.value = value;
          } catch (_) {
            return called;
          }
          return 99;
        }
      ''', 0);
    });
  });

  group('preserved dynamic behavior', () {
    test('dynamic type tests retain generic list arguments', () {
      _expectValue('''
        int main() {
          dynamic value = <int>[1];
          var result = 0;
          if (value is List<int>) result += 4;
          if (value is List<num>) result += 2;
          if (value is List<String>) result += 1;
          return result;
        }
      ''', 6);
    });

    test('null supports Object.toString through dynamic dispatch', () {
      _expectValue('''
        String main() {
          dynamic value = null;
          return value.toString();
        }
      ''', 'null');
    });

    test('missing guest members produce NoSuchMethodError', () {
      _expectValue('''
        class A {}
        String main() {
          dynamic value = A();
          try {
            value.missing();
          } on NoSuchMethodError {
            return 'NoSuchMethodError';
          }
          return 'no-error';
        }
      ''', 'NoSuchMethodError');
    });

    test('dynamic misses call a guest noSuchMethod override', () {
      _expectValue('''
        class A {
          dynamic noSuchMethod(Invocation invocation) {
            return invocation.isMethod ? 42 : -1;
          }
        }
        int main() {
          dynamic value = A();
          return value.missing(1, named: 2);
        }
      ''', 42);
    });

    test('invalid dynamic call shapes use noSuchMethod', () {
      _expectValue('''
        class A {
          int f(int value, {required int named}) => -1;
          dynamic noSuchMethod(Invocation invocation) => 42;
        }
        int main() {
          dynamic value = A();
          var result = 0;
          result = result + (value.f() as int);
          result = result + (value.f(1, wrong: 2) as int);
          result = result + (value.f(1, 2, named: 3) as int);
          return result;
        }
      ''', 126);
    });

    test('generic checks preserve argument nullability', () {
      _expectValue('''
        int main() {
          dynamic value = <int?>[1, null];
          return value is List<int> ? 1 : 0;
        }
      ''', 0);
    });

    test('Null is a subtype of nullable generic arguments', () {
      _expectValue('''
        int main() {
          dynamic value = <Null>[null];
          return value is List<int?> ? 1 : 0;
        }
      ''', 1);
    });

    test('Null parameters accept null through dynamic invocation', () {
      _expectValue('''
        int main() {
          dynamic closure = (Null value) => 1;
          return closure(null);
        }
      ''', 1);
    });

    test('invalid dynamic closure shapes produce NoSuchMethodError', () {
      _expectValue('''
        int main() {
          dynamic closure = (int value) => value;
          try {
            closure();
          } on NoSuchMethodError {
            return 1;
          }
          return 0;
        }
      ''', 1);
    });

    test('dynamic closure calls bind named arguments', () {
      _expectValue('''
        int main() {
          dynamic closure = ({required int value}) => value;
          return closure(value: 9);
        }
      ''', 9);
    });

    test('private dynamic selectors retain caller library identity', () {
      final packages = {
        'dynamic_fixtures': {
          'main.dart': '''
            import 'package:private_owner/owner.dart';
            int main() {
              dynamic value = Owner();
              try {
                return value._secret();
              } on NoSuchMethodError {
                return value.callInsideOwner();
              }
            }
          ''',
        },
        'private_owner': {
          'owner.dart': '''
            class Owner {
              int _secret() => 7;
              int callInsideOwner() => _secret();
            }
          ''',
        },
      };
      for (final (mode, result) in runDynamicPackages(
        packages,
        entrypoint: dynamicFixtureLibrary,
      )) {
        expect(result, const DynamicFixtureResult.value(7), reason: mode);
      }
    });

    test('private dynamic tear-offs retain caller library identity', () {
      _expectValue('''
        class Owner {
          int _secret() => 7;
          int call() {
            dynamic self = this;
            dynamic tearOff = self._secret;
            return tearOff();
          }
        }
        int main() => Owner().call();
      ''', 7);
    });

    test('dynamic methods bind named arguments', () {
      _expectValue('''
        class A {
          int f({required int x}) => x;
        }
        int main() {
          dynamic value = A();
          return value.f(x: 9);
        }
      ''', 9);
    });

    test('dynamic methods apply optional defaults', () {
      _expectValue('''
        class A {
          int f([int x = 7]) => x;
        }
        int main() {
          dynamic value = A();
          return value.f();
        }
      ''', 7);
    });

    test('a dynamic local accepts changing runtime types', () {
      _expectValue('''
        int main() {
          dynamic value = 1;
          value = 'abc';
          return value.length;
        }
      ''', 3);
    });

    test('dynamic arithmetic still dispatches', () {
      _expectValue('''
        int main() {
          dynamic value = 2;
          return value + 3;
        }
      ''', 5);
    });

    test('compound assignment of an int expression to an int variable', () {
      _expectValue('''
        int main() {
          var checksum = 0;
          checksum += 1 + [1, 2, 3].length;
          return checksum;
        }
      ''', 4);
    });

    test('compound assignment of map length stays int', () {
      _expectValue('''
        int main() {
          final counts = <String, int>{'a': 1, 'b': 2};
          var checksum = 0;
          checksum += (counts['a'] ?? 0) + (counts['b'] ?? 0) + counts.length;
          return checksum;
        }
      ''', 5);
    });

    test('map length resolves to int for property access', () {
      _expectValue('''
        int main() {
          final counts = <String, int>{'a': 1};
          return counts.length * 10 + (counts.length is int ? 1 : 0);
        }
      ''', 11);
    });
  });
}
