import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/future.dart';
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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart',
          'TestClass.', $TestClass.$construct,
          isBridge: true);

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
                return super.runTest(a + 2 + someNumber, b: b);
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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart',
          'TestClass.', $TestClass.$construct,
          isBridge: true);

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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart',
          'TestClass.', $TestClass.$construct,
          isBridge: true);

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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart',
          'TestClass.', $TestClass.$construct,
          isBridge: true);
      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart',
          'TestClass.runStaticTest', $TestClass.$runStaticTest);

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

      runtime.registerBridgeEnumValues(
          'package:bridge_lib/bridge_lib.dart', 'TestEnum', $TestEnum.$values);

      expect(runtime.executeLib('package:example/main.dart', 'main').$value,
          TestEnum.two);
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

      expect(
          runtime.executeLib('package:example/main.dart', 'main', [
            $Map<$String, $int>.wrap({$String('hi'): $int(5)})
          ]),
          5);
    });

    test('Runtime overrides', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            @RuntimeOverride('#get_list')
            List<int> getList() {
              return [1, 2, 3];
            }
          '''
        }
      });

      runtime.loadGlobalOverrides();
      expect(runtimeOverride('#get_list'), [1, 2, 3]);
    });

    test('Versioned runtime overrides', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            @RuntimeOverride('#get_list', version: '<1.4.0')
            List<int> getList() {
              return [1, 2, 3];
            }
          '''
        }
      });

      runtime.loadGlobalOverrides();
      runtimeOverrideVersion = Version.parse('1.3.0');
      expect(runtimeOverride('#get_list'), [1, 2, 3]);

      runtimeOverrideVersion = Version.parse('1.4.0');
      expect(runtimeOverride('#get_list'), null);
    });

    test('Awaiting a callback', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:async';
            
            void main(Function callback) async {
              callback('a');
              await callback('w');
              callback('b');
            }
          '''
        }
      });

      final callback = $Closure((runtime, target, args) {
        final fn = args[0]!.$value as String;
        switch (fn) {
          case 'a':
            print('a');
            break;
          case 'b':
            print('b');
            break;
          case 'w':
            return $Future.wrap(
                Future.delayed(const Duration(milliseconds: 10), () => 5));
        }
        return null;
      });

      expect(
          () async => (await runtime
              .executeLib('package:example/main.dart', 'main', [callback])),
          prints('a\nb\n'));
    });

    test('Should catch bridge future error', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:async';

            void main(Function callback) async {
              await callback();
            }
          '''
        }
      });

      bool callbackExecuted = false;
      final callback = $Closure((runtime, target, args) {
        callbackExecuted = true;
        return $Future.wrap(Future.error(Exception('Bridge error')));
      });

      Exception? caughtException;
      try {
        await runtime
            .executeLib('package:example/main.dart', 'main', [callback]);
        fail('Expected exception was not thrown');
      } catch (e) {
        caughtException = e as Exception;
      }

      // Verify callback was executed
      expect(callbackExecuted, isTrue);

      // Verify correct exception type and message
      expect(caughtException, isA<Exception>());
      expect(caughtException.toString(), contains('Bridge error'));
    });
  });
}
