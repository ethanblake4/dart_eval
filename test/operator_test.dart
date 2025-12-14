import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Operator method tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Operator ==', () {
      final runtime = compiler.compileWriteAndLoad({
        'operator_test': {
          'main.dart': '''
            class MyClass {
              final int value;
              
              MyClass(this.value);
              
              @override
              bool operator==(Object other) => other is MyClass && other.value == value;
            }
            
            List<bool> main() {
              final cls = MyClass(1);
              return [
                cls == MyClass(2),
                cls == null,
                cls == MyClass(1),
                cls == cls,
              ];
            }
          '''
        }
      });

      expect(runtime.executeLib('package:operator_test/main.dart', 'main'), [
        $bool(false), $bool(false), $bool(true), $bool(true),
      ]);
    }, skip: true);

    test('Operator has object context', () {
      final runtime = compiler.compileWriteAndLoad({
        'operator_test': {
          'main.dart': '''
            class MyClass {
              final int value = 1;
              int operator+(int add) => value + add;
            }
            int main() => MyClass() + 1;
          '''
        }
      });

      expect(runtime.executeLib('package:operator_test/main.dart', 'main'), 4);
    }, skip: true);

    test('Operator []', () {
      final runtime = compiler.compileWriteAndLoad({
        'operator_test': {
          'main.dart': '''
            class MyClass {
              final value = [1, 2];
              
              MyClass();
              
              int operator[](int index) => value[index];
              
              void operator[]=(int index, int value) {
                this.value[index] = value;
              }
            }
            
            List<int> main() {
              final cls = MyClass();
              cls[0] = 3;
              return [cls[0], cls[1]];
            }
          '''
        }
      });

      expect(runtime.executeLib('package:operator_test/main.dart', 'main'), [
        $int(1), $int(2),
      ]);
    }, skip: true);
  });
}