import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';

void main() {
  group('Symbol literal tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Simple symbol literal', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(#hello);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('Symbol("hello")\n'));
    });

    test('Dotted symbol literal', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(#foo.bar);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('Symbol("foo.bar")\n'));
    });

    test('Private symbol literal strips leading underscore', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(#_private);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('Symbol("private")\n'));
    });

    test('Symbol literal can be assigned and compared', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var s = #test;
              print(s == #test);
              print(s == #other);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('true\nfalse\n'));
    });
  });
}
