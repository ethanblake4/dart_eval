import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:test/test.dart';

import 'bridge_lib.dart';

void main() {
  group('Bridge tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Using a bridge class', () {
      compiler.defineBridgeClasses([$TestClass.$declaration]);

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:bridge_lib/bridge_lib.dart';
            
            bool main() {
              final test = TestClass(4);
              return test.runTest(5, b: 'hi');
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $TestClass.$construct,
          isBridge: true);

      runtime.setup();
      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('Using a subclassed bridge class inside the runtime', () {
      compiler.defineBridgeClasses([$TestClass.$declaration]);

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:bridge_lib/bridge_lib.dart';
            
            class MyTestClass extends TestClass {
              MyTestClass(int someNumber) : super(someNumber);
            
              @override
              bool runTest(int a, {String b = 'wow'}) {
                return super.runTest(a + 2, b: b);
              }
            }
            
            bool main() {
              final test = MyTestClass(18);
              return test.runTest(5, b: 'cool');
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $TestClass.$construct,
          isBridge: true);

      runtime.setup();
      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('Using a subclassed bridge class outside the runtime', () {
      compiler.defineBridgeClasses([$TestClass.$declaration]);

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:bridge_lib/bridge_lib.dart';
            
            class MyTestClass extends TestClass {
              MyTestClass(int someNumber) : super(someNumber);
            
              @override
              bool runTest(int a, {String b = 'wow'}) {
                return super.runTest(a + 2, b: b);
              }
            }
            
            TestClass main() {
              final test = MyTestClass(0, b: 'hello');
              return test;
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $TestClass.$construct,
          isBridge: true);

      runtime.setup();
      final res = runtime.executeLib('package:example/main.dart', 'main');

      expect(res is TestClass, true);
      expect((res as TestClass).runTest(4), true);
      expect(res.runTest(2), false);
    });

    test('Using an external static method', () {
      compiler.defineBridgeClasses([$TestClass.$declaration]);

      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:bridge_lib/bridge_lib.dart';
            
            bool main() {
              return TestClass.runStaticTest('Okay');
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $TestClass.$construct,
          isBridge: true);
      runtime.registerBridgeFunc(
          'package:bridge_lib/bridge_lib.dart', 'TestClass.runStaticTest', $TestClass.$runStaticTest);

      runtime.setup();
      expect(runtime.executeLib('package:example/main.dart', 'main'), false);
    });

    test('Using a bridged enum', () {
      compiler.defineBridgeEnum($TestEnum.$declaration);
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:bridge_lib/bridge_lib.dart';
            
            TestEnum main() {
              final map = {
                'one': TestEnum.one,
                'two': TestEnum.two,
              };

              return map['two'];
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);

      runtime.registerBridgeEnumValues('package:bridge_lib/bridge_lib.dart', 'TestEnum', $TestEnum.$values);
      runtime.setup();

      expect(runtime.executeLib('package:example/main.dart', 'main').$value, TestEnum.two);
    });

    test('Passing a map to a function externally', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''            
            int main(Map<String, int> map) {
              return map['hi'];
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);

      runtime.setup();
      expect(
          runtime.executeLib('package:example/main.dart', 'main', [
            $Map<$String, $int>.wrap({$String('hi'): $int(5)})
          ]),
          5);
    });
  });
}
