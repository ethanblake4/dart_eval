import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
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
      final result = runtime.executeLib(
          'package:example/main.dart', 'main', [$String('Test45678')]);
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

    test('Ignore package:eval_annotation imports', () {
      final packages = {
        'example': {
          'main.dart': '''
          import 'package:eval_annotation/eval_annotation.dart';

          int main(String arg) {
            return arg.length;
          }
          ''',
        }
      };

      final program = compiler.compile(packages);
      final runtime = Runtime.ofProgram(program);

      final result = runtime.executeLib(
          'package:example/main.dart', 'main', [$String('Test45678')]);
      expect(result, 9);
    });

    test('Relative imports', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'b1.dart';
            import 'models/data/c3.dart';
            int main() {
              final b = ClassB();
              final c = ClassC();
              return b.number() + c.number();
            }
          ''',
          'b1.dart': '''
            class ClassB {
              ClassB();
              int number() { return 4; }
            }
          ''',
          'models/data/c3.dart': '''
            class ClassC {
              ClassC();
              int number() { return 6; }
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 10);
    });

    test('Prefixed import in constructor call', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/b1.dart' as b1;
            int main() {
              final b = b1.ClassB();
              return b.number();
            }
          ''',
          'b1.dart': '''
            class ClassB {
              ClassB();
              int number() { return 4; }
            }
          ''',
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 4);
    });

    test('Tree shaking', () {
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
            class ClassB {
              ClassB();
              int number() { return 4; }
            }
            class ClassC {
              ClassC();
              int number() { 
                invalidVariable.makeError(); // Should not be compiled
              }
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 4);
    });

    test('Relative exports', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'b1.dart';
            int main() {
              final b = ClassB();
              return b.number();
            }
          ''',
          'b1.dart': '''
            export 'b2.dart';
          ''',
          'b2.dart': '''
            class ClassB {
              ClassB();
              int number() { return 4; }
            }
          ''',
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 4);
    });

    test('Cyclic imports', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'b1.dart';
            int main() {
              final b = ClassB();
              return b.number();
            }
          ''',
          'b1.dart': '''
            import 'b2.dart';
            class ClassB {
              ClassB();
              static int constant = 4;
              int number() { return 4 + ClassC().number(); }
            }
          ''',
          'b2.dart': '''
            import 'b1.dart';
            class ClassC {
              ClassC();
              int number() { return 8 + ClassB.constant; }
            }
          ''',
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 16);
    });

    test('Correct tree shaking of long reference chains within a single file',
        () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/file.dart';
            int main() {
              return getClass().number();
            }
          ''',
          'file.dart': '''
            Cls getClass() {
              return getClass2();
            }

            Cls getClass2() {
              return getClass3();
            }

            Cls getClass3() {
              return getClass4();
            }

            Cls getClass4() {
              return Cls();
            }

            class Cls {
              int number() {
                return 42;
              }
            }
          ''',
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 42);
    });

    test("Tree shaking doesn't hide top level declarations", () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            import 'package:example/file.dart';
            int main() {
              return getNumber();
            }
          ''',
          'file.dart': '''
            import 'package:example/meta.dart';
            int getNumber() {
              return number;
            }
            
            @internal
            int get number {
              return 42;
            }
          ''',
          'meta.dart': '''
            const _Internal internal = _Internal();
            class _Internal {
              const _Internal();
            }
            const _MustCallSuper mustCallSuper = _MustCallSuper();
            class _MustCallSuper {
              const _MustCallSuper();
            }
          ''',
        }
      });

      final runtime = Runtime.ofProgram(program);
      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result, 42);
    });
  });
}
