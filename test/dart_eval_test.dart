import 'package:dart_eval/src/eval/compiler/compiler.dart';
import 'package:dart_eval/src/eval/runtime/stdlib_base.dart';
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
      '''}})..loadProgram();

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
     
      '''}})..loadProgram();

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
        }})..loadProgram();

      expect(exec.executeNamed(0, 'main'), DbcInt(7));
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
      '''}})..loadProgram();

      expect(exec.executeNamed(0, 'main'), 10);
    });
  });
}
