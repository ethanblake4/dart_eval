import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

// Functional tests
void main() {
  group('Function tests', () {
    late Compiler gen;

    setUp(() {
      gen = Compiler();
    });

    test('Local variable assignment with ints', () {
      final exec = gen.compileWriteAndLoad({'dbc_test': {'main.dart': '''
      int main() {
        var i = 3;
        {
          var k = 2;
          k = i;
          return k;
        }
      }
      '''}});

      expect(exec.executeNamed(0, 'main'), 3);
    });

    test('Simple function call', () {
      final exec = gen.compileWriteAndLoad({'dbc_test': {'main.dart': '''
     
      int main() {
        var i = x();
        return i;
      }
      int x() {
        return 7;
      }
     
      '''}});

      expect(exec.executeNamed(0, 'main'), 7);
    });

    test('Multiple files, boxed ints and correct stack handling',() {
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
        }});

      expect(exec.executeNamed(0, 'main'), EvalInt(7));
    });
  });
  group('Class tests', () {
    late Compiler gen;

    setUp(() {
      gen = Compiler();
    });

    test('Default constructor, basic method', () {
      final exec = gen.compileWriteAndLoad({'dbc_test': {'main.dart': '''
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
      '''}});

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

      expect(exec.executeNamed(0, 'main'), EvalInt(19));
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
              for (; i < 555; i = i + 1) {}
              return i;
            }
          ''',
        }
      });
      expect(exec.executeNamed(0, 'main'), EvalInt(555));
    });

    test('For loop + branching', () {
      final exec = gen.compileWriteAndLoad({
        'example': { 'main.dart': '''
          dynamic doThing() {
            var count = 0;
            for (var i = 0; i < 1000; i = i + 1) {
              if (count < 500) {
                count = count - 1;
              } else if (count < 750) {
                count = count + 1;
              }
              count = count + i;
            }
            
            return count;
          }
        ''' }
      });

      expect(exec.executeNamed(0, 'doThing'), EvalInt(499472));
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
        for (var i = someNumber; i < 100; i = i + 1) {
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
        'example': { 'main.dart': source }
      });


      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final result = exec.executeNamed(0, 'main');
      expect(result, EvalInt(555));
      expect(DateTime.now().millisecondsSinceEpoch - timestamp, lessThan(100));
    });

  });
}
