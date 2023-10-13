import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  group('Enum tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Basic enum', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum MyEnum {
              A, B, C
            }
            int main() {
              return MyEnum.B.index + MyEnum.C.index;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('Enum with field', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum MyEnum {
              A(1), B(2);
              final int x;
              const MyEnum(this.x);
            }
            int main() {
              return MyEnum.B.index + MyEnum.A.x;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 2);
    });

    test('Enum equality', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum MyEnum {
              A, B, C
            }
            void main() {
              print(MyEnum.B == MyEnum.C);
              print(MyEnum.B == MyEnum.B);
            }
          '''
        }
      });

      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          prints('false\ntrue\n'));
    });
  });
}
