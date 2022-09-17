import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/stdlib/core.dart';
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

      expect(exec.executeLib('package:dbc_test/main.dart', 'main'), 3);
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

      expect(exec.executeLib('package:dbc_test/main.dart', 'main'), 7);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), 75025);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), $num<num>(7));
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

      expect(exec.executeLib('package:example/main.dart', 'main'), 2);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), 2);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), 3);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), $double(1.5));
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

      expect(exec.executeLib('package:example/main.dart', 'main'), $double(1.5));
    });

    test('Simple async/await', () async {
      final runtime = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          Future main(int milliseconds) async {
            await Future.delayed(Duration(milliseconds: milliseconds));
            return 3;
          }
          '''
        }
      });

      final startTime = DateTime.now().millisecondsSinceEpoch;
      final future = runtime.executeLib('package:example/main.dart', 'main', [150]) as Future;
      await expectLater(future, completion($int(3)));
      final endTime = DateTime.now().millisecondsSinceEpoch;
      expect(endTime - startTime, greaterThan(100));
      expect(endTime - startTime, lessThan(200));
    });

    test('Closure with arg', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return q()(6);
            }
            
            Function q() {
              final b = 12;
              
              var myfunc = (a) {
                return a + b;
              };
              
              return myfunc;
            }
           '''
        }
      });

      expect(exec.executeLib('package:example/main.dart', 'main'), 18);
    });

    test('Arrow function', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main (int y) => 2 + y;
           '''
        }
      });

      expect(exec.executeLib('package:example/main.dart', 'main', [4]), 6);
    });

    test('Arrow function expression', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              var fn = (a) => a + 1;
              return fn(4);
            }
           '''
        }
      });

      expect(exec.executeLib('package:example/main.dart', 'main'), 5);
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

      expect(exec.executeLib('package:dbc_test/main.dart', 'main'), 10);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), $int(19));
    });

    test('"this" keyword', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return M(2).load();
            }
            
            class M {
              M(this.number);
              final int number;
              
              int load() {
                return this._loadInternal(4);
              }
              
              _loadInternal(int times) {
                return this.number * times;
              }
            }
          '''
        }
      });

      expect(exec.executeLib('package:example/main.dart', 'main'), 8);
    });

    test('Implicit and "this" field access from closure', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return M(2).load();
            }
                    
            class M {
              M(this.number);
              int number;
              
              int load() {
                return this._loadInternal(4);
              }
              
              _loadInternal(int times) {
                final f = (t) {
                  number++;
                  return this.number * t;
                };
                return f(times);
              }
            }
          '''
        }
      });

      expect(exec.executeLib('package:example/main.dart', 'main'), 12);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), 10);
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

      expect(exec.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('"new" keyword', () {
      final exec = gen.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              return new M(4).load();
            }
            
            class M {
              M(this.x);
              
              final int x;
              
              int load() {
                return 5 + x;
              }
            }
            
          '''
        }
      });

      expect(exec.executeLib('package:example/main.dart', 'main'), 9);
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
      expect(exec.executeLib('package:example/main.dart', 'main'), $int(555));
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

      expect(exec.executeLib('package:example/main.dart', 'doThing'), $int(499472));
    });
  });

  group('Standard library tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Int unary -', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return -5;
            }
          '''
        }
      });

      expect(exec.executeLib('package:example/main.dart', 'main'), -5);
    });

    test('Future.delayed()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          Future main(int milliseconds) {
            return Future.delayed(Duration(milliseconds: milliseconds));
          }
          '''
        }
      });

      final startTime = DateTime.now().millisecondsSinceEpoch;
      final future = runtime.executeLib('package:example/main.dart', 'main', [150]) as Future;
      await expectLater(future, completion(null));
      final endTime = DateTime.now().millisecondsSinceEpoch;
      expect(endTime - startTime, greaterThan(100));
      expect(endTime - startTime, lessThan(200));
    });

    test('Using a Future result', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          import 'dart:math';
          Future<int> main(int milliseconds) async {
            final result = await getPoint(milliseconds);
            return result.x + result.y;
          }

          Future<Point> getPoint(int milliseconds) async {
            await Future.delayed(Duration(milliseconds: milliseconds));
            return Point(5, 5);
          }
          '''
        }
      });

      final future = runtime.executeLib('package:example/main.dart', 'main', [150]) as Future;
      await expectLater(future, completion($int(10)));
    });

    test('print()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          void main(int whatToSay) {
            print(whatToSay);
          }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main', [56890]);
      }, prints('56890\n'));
    });

    test('String has length getter', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              return cat.length;
            }
          ''',
        }
      });
      expect(exec.executeLib('package:example/main.dart', 'main'), 6);
    });

    test('String has isEmpty getter', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              if (cat.isNotEmpty) return 1;
            }
          ''',
        }
      });
      expect(exec.executeLib('package:example/main.dart', 'main'), 1);
    });

    test('String has substring method', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              String sub = cat.substring(0,3);
              print(sub);
            }
          ''',
        }
      });
      expect(() {
        exec.executeLib('package:example/main.dart', 'main');
      }, prints('Flu\n'));
    });
    test('String substring method works with only 1 parameter', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              String sub = cat.substring(3);
              print(sub);
            }
          ''',
        }
      });
      expect(() {
        exec.executeLib('package:example/main.dart', 'main');
      }, prints('ffy\n'));
    });

    test('Boolean literals', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              final a = true;
              final b = false;
              print(a);
              print(b);
              return b;
            }
          ''',
        }
      });
      expect(() {
        final a = exec.executeLib('package:example/main.dart', 'main');
        expect(a, equals(false));
      }, prints('true\nfalse\n'));
    });

    test('Boxed bools, logical && and ||', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            dynamic main() {
              final a = true;
              final b = false;
              print(a && b);
              print(a || b);
              return b && a;
            }
          ''',
        }
      });
      expect(() {
        expect(exec.executeLib('package:example/main.dart', 'main'), $bool(false));
      }, prints('false\ntrue\n'));
    });
    test('String interpolation', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              final a = "Hello";
              final b = 2;
              print("Fluffy\$a\$b, says the cat");
              return 2;
            }
          ''',
        }
      });
      expect(() {
        exec.executeLib('package:example/main.dart', 'main');
      }, prints('FluffyHello2, says the cat\n'));
    });

    test('dart:math Point', () {
      final exec = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:math';
            void main() {
              final a = Point(1, 2);
              final b = Point(3, 4);
              print(a.distanceTo(b));
            }
          ''',
        }
      });
      expect(() {
        exec.executeLib('package:example/main.dart', 'main');
      }, prints('2.8284271247461903\n'));
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
  });

  group('File and library composition', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Import hiding', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/b1.dart';
            import 'package:example/b2.dart' hide ClassB;
            int main() {
              final b = ClassB();
              return b.number();
            }
          ''',
          'b1.dart': '''
            class ClassB {
              ClassB();
              int number() { return 4; }
            }
          ''',
          'b2.dart': '''
            class ClassB {
              ClassB();
              int number() { return 8; }
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 4);
    });

    test('Export chains', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/b1.dart';
            int main() {
              final b = ClassB();
              return b.number();
            }
          ''',
          'b1.dart': '''
            library b1;
            export 'package:example/b2.dart' show ClassB;
          ''',
          'b2.dart': '''
            export 'package:example/b3.dart';
          ''',
          'b3.dart': '''
            class ClassB {
              ClassB();
              int number() { return 8; }
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 8);
    });

    test('Library composition with parts', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            library my_lib;
            part 'package:example/b1.dart';
            part 'package:example/b2.dart';
          ''',
          'b1.dart': '''
            part of 'package:example/main.dart';
            int main(String arg) {
              return _countChars(arg);
            }
          ''',
          'b2.dart': '''
            part of my_lib;
            int _countChars(String str) {
              return str.length;
            }
          ''',
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main', [$String('Test45678')]);
      expect(result, 9);
    });

    test('Top-level private access with underscore prefixing', () {
      final packages = {
        'example': {
          'main.dart': '''
            import 'package:example/b2.dart';
            int main(String arg) {
              return _countChars(arg);
            }
          ''',
          'b2.dart': '''
            int _countChars(String str) {
              return str.length;
            }
          ''',
        }
      };

      expect(() => compiler.compile(packages), throwsA(isA<CompileError>()));
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

      final result = exec.executeLib('package:example/main.dart', 'main');
      expect(result, $int(555));
      expect(DateTime.now().millisecondsSinceEpoch - timestamp, lessThan(100));
    });
  });
}
