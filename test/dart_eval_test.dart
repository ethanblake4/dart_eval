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
  });
}
