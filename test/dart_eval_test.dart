import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/primitives.dart';
import 'package:test/test.dart';

// Functional tests
void main() {
  group('Parsing tests', () {
    late Parse parse;

    setUp(() {
      parse = Parse();
    });

    test('Parse creates function', () {
      final scope = parse.parse('void main() {}').scope;
      expect(scope.lookup('main')?.value is EvalFunction, true);
    });

    test('Parse creates class', () {
      final scope = parse.parse('class MyClass {}').scope;
      expect(scope.lookup('MyClass')?.value is EvalClass, true);
    });
  });

  group('dart:core tests', () {
    late Parse parse;

    setUp(() {
      parse = Parse();
    });

    test('Object toString', () {
      final scope = parse.parse('String main() { return 1.toString(); }');
      expect(scope('main', []).realValue == '1', true);
    });
  });

  group('Function tests', () {
    late Parse parse;

    setUp(() {
      parse = Parse();
    });

    test('Returning a value', () {
      final scopeWrapper = parse.parse('String xyz() { return "success"; }');
      final result = scopeWrapper('xyz', []);
      expect(result is EvalString, true);
      expect((result as EvalString).realValue == 'success', true);
    });

    test('Calling a function', () {
      final scopeWrapper = parse.parse('''
      String xyz() { return second();  }
      String second() { return "success"; }
      ''');
      final result = scopeWrapper('xyz', []);
      expect(result is EvalString, true);
      expect((result as EvalString).realValue == 'success', true);
    });

    test('Calling a function with parameters', () {
      final scopeWrapper = parse.parse('''
        String xyz(int y) { return second(y);  }
        String second(int x) { return x.toString(); }
      ''');
      final result = scopeWrapper('xyz', [Parameter(EvalInt(32))]);
      expect(result is EvalString, true);
      expect((result as EvalString).realValue == '32', true);
    });

    test('Named parameters', () {
      final scopeWrapper = parse.parse('''
        String xyz() { return second(x: 5); }
        String second({int x}) { return x.toString(); }
      ''');
      final result = scopeWrapper('xyz', []);
      expect(result is EvalString, true);
      expect((result as EvalString).realValue == '5', true);
    });
  });

  group('Class tests', () {
    late Parse parse;

    setUp(() {
      parse = Parse();
    });

    test('Class fields', () {
      final scopeWrapper = parse.parse('''
        class CandyBar {
          CandyBar();
          bool eaten = false;
          
          void eat() {
            eaten = true;
          }
        }
        bool fn() {
          var x = CandyBar();
          x.eat();
          return x.eaten;
        }
      ''');

      final result = scopeWrapper('fn', []);
      expect(result is EvalBool, true);
      expect(true, (result as EvalBool).realValue);
    });

    test('Default constructor with positional parameters', () {
      final scopeWrapper = parse.parse('''
        class CandyBar {
          CandyBar(this.brand);
          final String brand;
        }
        bool fn() {
          var x = CandyBar('Mars');
          return x.brand;
        }
      ''');

      final result = scopeWrapper('fn', []);
      expect(result is EvalString, true);
      expect('Mars', (result as EvalString).realValue);
    });
  });

  group('Interop tests', () {
    late Parse parse;

    setUp(() {
      parse = Parse();
      parse.additionalDefines.add({
        _interopTest1Type.refName: EvalField(_interopTest1Type.refName, EvalInteropTest1.cls, null, Getter(null)),
      });
    });

    test('Rectified bridge class', () {
      final scopeWrapper = parse.parse('''
        class MyInteropTest1 extends InteropTest1 {
          @override
          String getData(int input) {
            return "Hello";
          }
        }
        String fn() {
          return MyInteropTest1().getData(1);
        }
      ''');
      final result = scopeWrapper('fn', []);
      expect(result is EvalString, true);
      expect((result as EvalString).realValue == 'Hello', true);
    });

    test('Exporting rectified bridge class', () {
      final scopeWrapper = parse.parse('''
        class MyInteropTest1 extends InteropTest1 {
          @override
          String getData(int input) {
            return "Hello" + 1.toString();
          }
        }
        String fn() {
          return MyInteropTest1();
        }
      ''');
      final result = scopeWrapper('fn', []);
      expect(result is InteropTest1, true);
      expect((result as InteropTest1).getData(1), 'Hello1');
    });

  });
}

const _interopTest1Type = EvalType('InteropTest1', 'InteropTest1', 'dart_eval_test.dart', [EvalType.objectType], true);

abstract class InteropTest1 {
  String getData(int input);
}

class EvalInteropTest1 extends InteropTest1
    with ValueInterop<InteropTest1>, EvalBridgeObjectMixin<InteropTest1>, BridgeRectifier<InteropTest1> {

  static final cls = EvalBridgeClass([], EvalGenericsList([]), _interopTest1Type, EvalScope.empty, InteropTest1,
      (_1, _2, _3) => EvalInteropTest1());

  @override
  EvalBridgeData evalBridgeData = EvalBridgeData(cls);

  @override
  String getData(int input) => bridgeCall('getData', [EvalInt(input)]);

  @override
  EvalValue setField(String name, EvalValue value) {
    throw ArgumentError();
  }
}
