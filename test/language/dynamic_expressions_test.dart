import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void expectDynamicValue(String source, Object? expected) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.value(expected), reason: mode);
  }
}

void main() {
  group('dynamic expression semantics', () {
    test('Object? does not gain dynamic member access', () {
      expect(
        () => Compiler().compile({
          'dynamic_fixtures': {
            'main.dart': '''
              int main(Object? value) => value.length;
            ''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });

    test('operators dispatch to receiver overrides', () {
      expectDynamicValue('''
        class NumberLike {
          NumberLike(this.value);
          int value;
          int operator +(int other) => value + other + 10;
        }
        int main() {
          dynamic value = NumberLike(2);
          return value + 3;
        }
      ''', 15);
    });

    test('compound indexed writes evaluate each operand once', () {
      expectDynamicValue('''
        class Box {
          final List<int> values = [4];
          int operator [](int index) => values[index];
          void operator []=(int index, int value) { values[index] = value; }
        }
        int receiverCalls = 0;
        int indexCalls = 0;
        int valueCalls = 0;
        dynamic box = Box();
        dynamic receiver() { receiverCalls++; return box; }
        dynamic index() { indexCalls++; return 0; }
        dynamic value() { valueCalls++; return 3; }
        int main() {
          receiver()[index()] += value();
          return box[0] + receiverCalls * 10 + indexCalls * 100 + valueCalls * 1000;
        }
      ''', 1117);
    });

    test('compound assignment keeps its implicit dynamic downcast', () {
      expectDynamicValue('''
        int main() {
          int value = 1;
          dynamic good = 2;
          dynamic bad = 'bad';
          value += good;
          try {
            value += bad;
          } on TypeError {
            return value;
          }
          return -1;
        }
      ''', 3);
    });

    test('collection construction and aliased writes keep element checks', () {
      expectDynamicValue('''
        int main() {
          var result = 0;
          dynamic bad = 'bad';
          try {
            <int>[bad];
          } on TypeError {
            result += 1;
          }
          try {
            <int>[...<dynamic>[1, bad]];
          } on TypeError {
            result += 2;
          }
          List<num> values = <int>[1];
          try {
            values[0] = 1.5;
          } on TypeError {
            result += 4;
          }
          return result;
        }
      ''', 7);
    });

    test('boolean and null-aware operators do not use truthiness', () {
      expectDynamicValue('''
        int main() {
          dynamic yes = true;
          dynamic no = false;
          dynamic absent;
          if (yes && !no && absent?.missing == null) return 1;
          return 0;
        }
      ''', 1);
    });

    test('dynamic unary operators use runtime semantics', () {
      expectDynamicValue('''
        class NumberLike {
          NumberLike(this.value);
          final int value;
          int operator -() => value + 10;
          NumberLike operator +(int amount) => NumberLike(value + amount);
        }
        int negate(dynamic value) => -value;
        int increment(dynamic value) {
          ++value;
          return value.value;
        }
        int main() => negate(NumberLike(2)) + increment(NumberLike(4));
      ''', 17);
    });

    test('dynamic boolean and null assertions throw TypeError', () {
      expectDynamicValue('''
        int check(dynamic boolean, dynamic nullable) {
          var result = 0;
          try {
            !boolean;
          } on TypeError {
            result += 1;
          }
          try {
            nullable!;
          } on TypeError {
            result += 2;
          }
          return result;
        }
        int main() => check(1, null);
      ''', 3);
    });

    test('dynamic iteration checks the loop variable', () {
      expectDynamicValue(r'''
        String main() {
          dynamic values = <dynamic>[1, 'bad'];
          var trace = '';
          try {
            for (int value in values) {
              trace += '$value';
            }
          } on TypeError {
            trace += ':type';
          }
          return trace;
        }
      ''', '1:type');
    });

    test('collection-for checks an unused declared loop variable', () {
      expectDynamicValue('''
        int main() {
          dynamic values = <dynamic>['bad'];
          try {
            return <int>[for (int value in values) 1].length;
          } on TypeError {
            return 7;
          }
        }
      ''', 7);
    });

    test('await accepts a dynamically typed future payload', () async {
      const source = '''
        Future<int> makeValue() async => 7;
        Future<int> main() async {
          dynamic value = makeValue();
          return await value;
        }
      ''';
      final program = Compiler().compile({
        'dynamic_fixtures': {'main.dart': source},
      });
      for (final (mode, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('serialized', Runtime(program.write().buffer)),
      ]) {
        expect(
          await runtime.executeLib(dynamicFixtureLibrary, 'main'),
          $int(7),
          reason: mode,
        );
      }
    });
  });
}
