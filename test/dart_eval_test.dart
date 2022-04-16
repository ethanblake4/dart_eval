import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

import 'bridge_lib.dart';

// Functional tests
void main() {
  group('Function tests', () {
    late Compiler gen;

    setUp(() {
      gen = Compiler();
    });

    test('Local variable assignment with ints', () {
      final exec = gen.compileWriteAndLoad({
        'dbc_test': {
          'main.dart': '''
      int main() {
        var i = 3;
        {
          var k = 2;
          k = i;
          return k;
        }
      }
      '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 3);
    });

    test('Simple function call', () {
      final exec = gen.compileWriteAndLoad({
        'dbc_test': {
          'main.dart': '''
     
      int main() {
        var i = x();
        return i;
      }
      int x() {
        return 7;
      }
     
      '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 7);
    });

    test('Recursion (fibonacci)', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int fib(int n) {
              if (n <= 1) return 1;
              return fib(n - 1) + fib(n - 2);
            }
            
            int main () {
              return fib(24);
            }
          '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 75025);
    });

    test('Multiple files, boxed ints and correct stack handling', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'package:example/x.dart';
            num main() {
              var i = x();
              return i + 3;
            }
            num x() {
              return x2();
            }
      ''',
          'x.dart': '''
            int x2() {
               var b = 4;
               var q = r();
               var c = 2;
               c = b;
               b = q;
               b = c;
               return b;
            }
        
            int r() {
              var ra = 99;
              return ra;
            }
      '''
        }
      });

      expect(exec.executeNamed(0, 'main'), $num<num>(7));
    });

    test('Basic anonymous function', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            Function r() {
              return () {
                return 2;
              };
            }
            
            int main () {
              return r()();
            }
           '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 2);
    });

    test('Basic inline anonymous function', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var r = () {
                return 2;
              };
              return r();
            }
           '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 2);
    });

    test('Anonymous function with arg', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var myfunc = (a) {
                return a + 1;
              };
              
              return myfunc(2);
            }
           '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 3);
    });

    test('Anonymous function with named args, same sorting as call site', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main () {
              var myfunc = ({a, b}) {
                return a / b + 1;
              };
              
              return myfunc(a: 2, b: 4);
            }
          '''
        }
      });

      expect(exec.executeNamed(0, 'main'), $double(1.5));
    });

    test('Anonymous function with named args, different sorting from call site', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main () {
              var myfunc = ({b, a}) {
                return a / b + 1;
              };
              
              return myfunc(a: 2, b: 4);
            }
          '''
        }
      });

      expect(exec.executeNamed(0, 'main'), $double(1.5));
    });
  });

  group('Class tests', () {
    late Compiler gen;

    setUp(() {
      gen = Compiler();
    });

    test('Default constructor, basic method', () {
      final exec = gen.compileWriteAndLoad({
        'dbc_test': {
          'main.dart': '''
      class MyClass {
        MyClass();
        
        int someMethod() {
          return 4 + 4;
        }
      }
      int main() {
        final cls = MyClass();
        return cls.someMethod() + 2;
      }
      '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 10);
    });

    test('Field formal parameters, external field access', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'package:example/x.dart';
            num main() {
              var i = Vib(z: 5);
              var m = Vib();
              return i.z + m.z + i.h();
            }
          ''',
          'x.dart': '''
            class Vib {
              Vib({this.z = 3});
              
              int z;
              
              int h() {
                return 11;
              }
            }
          '''
        }
      });

      expect(exec.executeNamed(0, 'main'), $int(19));
    });

    test('Simple static method', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return M.getNum(4) + 2;
            }
            
            class M {
              static int getNum(int b) {
                return 12 - b;
              }
            }
          '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 10);
    });

    test('Implicit static method scoping', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          int main () {
            return M(4).load();
          }
          
          class M {
            M(this.x);
            
            final int x;
            
            static int getNum(int b) {
              return 12 - b;
            }
            
            int load() {
              return getNum(5 + x);
            }
          }
          '''
        }
      });

      expect(exec.executeNamed(0, 'main'), 3);
    });
  });

  group('Statement tests', () {
    late Compiler gen;

    setUp(() {
      gen = Compiler();
    });

    test('For loop', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              for (; i < 555; i++) {}
              return i;
            }
          ''',
        }
      });
      expect(exec.executeNamed(0, 'main'), $int(555));
    });

    test('For loop + branching', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          dynamic doThing() {
            var count = 0;
            for (var i = 0; i < 1000; i++) {
              if (count < 500) {
                count--;
              } else if (count < 750) {
                count++;
              }
              count += i;
            }
            
            return count;
          }
        '''
        }
      });

      expect(exec.executeNamed(0, 'doThing'), $int(499472));
    });
  });

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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $Function($TestClass.$construct));

      runtime.setup();
      expect(runtime.executeNamed(0, 'main'), true);
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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $Function($TestClass.$construct));

      runtime.setup();
      expect(runtime.executeNamed(0, 'main'), true);
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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $Function($TestClass.$construct));

      runtime.setup();
      final res = runtime.executeNamed(0, 'main');

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

      runtime.registerBridgeFunc('package:bridge_lib/bridge_lib.dart', 'TestClass.', $Function($TestClass.$construct));
      runtime.registerBridgeFunc(
          'package:bridge_lib/bridge_lib.dart', 'TestClass.runStaticTest', $Function($TestClass.$runStaticTest));

      runtime.setup();
      expect(runtime.executeNamed(0, 'main'), false);
    });
  });

  group('Large functional tests', () {
    late Compiler gen;

    setUp(() {
      gen = Compiler();
    });

    test('Functional test 1', () {
      final source = '''
      dynamic main() {
        var someNumber = 19;
      
        var a = A(45);
        for (var i = someNumber; i < 20; i = i + 1) {
          final n = a.calculate(i);
          if (n > someNumber) {
            a = B(555);
          } else {
            if (a.number > B(a.number).calculate(2)) {
              a = C(888 + a.number);
            }
            someNumber = someNumber + 1;
          }
      
          if (n > a.calculate(a.number - i)) {
            a = D(21 + n);
            someNumber = someNumber - 1;
          }
        }
      
        return a.number;
      }
      
      class A {
        final int number;
      
        A(this.number);
      
        int calculate(int other) {
          return number + other;
        }
      }
      
      class B extends A {
        B(int number) : super(number);
      
        @override
        int calculate(int other) {
          var d = 1334;
          for (var i = 0; i < 15 + number; i = i + 1) {
            if (d > 4000) {
              d = d - 14;
            }
            d += i;
          }
          return d;
        }
      }
      
      class C extends A {
        C(int number) : super(number);
      
        @override
        int calculate(int other) {
          var d = 1556;
          for (var i = 0; i < 24 - number; i = i + 1) {
            if (d > 4000) {
              d = d - 14;
            } else if (d < 299) {
              d = d + 5 + 5;
            }
            d += i;
          }
          return d;
        }
      }
      
      class D extends A {
        D(int number) : super(number);
      
        @override
        int calculate(int other) {
          var d = 1334;
          for (var i = 0; i < 15 + number; i = i + 1) {
            if (d > 4000) {
              d = d - 14;
            }
            d += super.number;
          }
          return d;
        }
      }''';

      final exec = gen.compileWriteAndLoad({
        'example': {'main.dart': source}
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final result = exec.executeNamed(0, 'main');
      expect(result, $int(555));
      expect(DateTime.now().millisecondsSinceEpoch - timestamp, lessThan(100));
    });
  });
}
