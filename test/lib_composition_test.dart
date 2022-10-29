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
}
