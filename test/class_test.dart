import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Class tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Default constructor, basic method', () {
      final runtime = compiler.compileWriteAndLoad({
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

      expect(runtime.executeLib('package:dbc_test/main.dart', 'main'), 10);
    });

    test('Field formal parameters, external field access', () {
      final runtime = compiler.compileWriteAndLoad({
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

      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(19));
    });

    test('Trying to access nonexistent method throws error', () {
      final packages = {
        'example': {
          'main.dart': '''
            class MyClass {
              MyClass();
              
              int someMethod() {
                return 4 + 4;
              }
            }
            int main() {
              final cls = MyClass();
              return cls.someMethod() + cls.someOtherMethod();
            }
          '''
        }
      };

      expect(() => compiler.compileWriteAndLoad(packages), throwsA(isA<CompileError>()));
      expect(() => compiler.compileWriteAndLoad(packages), throwsA(predicate((CompileError e) {
        return e.toString().contains('someOtherMethod') && e.toString().contains('file package:example/main.dart');
      })));
    });

    test('"this" keyword', () {
      final runtime = compiler.compileWriteAndLoad({
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

      expect(runtime.executeLib('package:example/main.dart', 'main'), 8);
    });

    test('Implicit and "this" field access from closure', () {
      final runtime = compiler.compileWriteAndLoad({
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

      expect(runtime.executeLib('package:example/main.dart', 'main'), 12);
    });

    test('Simple static method', () {
      final runtime = compiler.compileWriteAndLoad({
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

      expect(runtime.executeLib('package:example/main.dart', 'main'), 10);
    });

    test('Implicit static method scoping', () {
      final runtime = compiler.compileWriteAndLoad({
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

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('"new" keyword', () {
      final runtime = compiler.compileWriteAndLoad({
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

      expect(runtime.executeLib('package:example/main.dart', 'main'), 9);
    });

    test('Getters and setters', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              final m = M();
              m.x = 5;
              return m.x + 1;
            }
            
            class M {
              int _x = 0;
              
              int get x => _x;
              set x(int value) => _x = value;
            }
            
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 6);
    });

    test('New-style super constructor parameters', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              final c = OldCat('Julian');
              return c.age + c.name.length;
            }
            
            class Cat {
              Cat(this.name, {required this.age});
              final String name;
              final int age;
            }

            class OldCat extends Cat {
              OldCat(super.name) : super(age: 10);
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 16);
    });

    test('Accessing list element from instance method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main () {
              final c = Cat();
              return c.load();
            }
            
            class Cat {
              final _list = [1, 2, 3];
              List<int> _list2 = [4, 5, 6];
              
              int load() {
                return _list[1] + _list2[1];
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 7);
    });

    test('Method call on field with inferred type from closure', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main () {
              final c = Cat();
              c.load()();
              return c.list[3];
            }
            
            class Cat {
              final list = ['a', 'b', 'c'];
              
              Function load() {
                return () {
                  list.add('d');
                };
              }
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), $String('d'));
    });

    test('Accessing methods and fields on super', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            class Animal {
              Animal(this.name);
              final String name;
              
              String getLabel() {
                return name + ' the animal';
              }
            }

            class Cat extends Animal {
              Cat(String name) : super(name);
              
              String getLabel() {
                return super.getLabel() + ' (cat)';
              }
            }

            String main () {
              final c = Cat('Julian');
              return c.getLabel();
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), $String('Julian the animal (cat)'));
    });

    test('Constructor field initializers', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = X("Hi");
              x.printValues();
            }

            class X {
              X(String s) : _a = 1, this._b = s + "!";
              final int _a;
              final String _b;
              void printValues() => print(_a + _b.length);
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('4\n'));
    });
  });
}
