import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Exception tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Basic try/catch', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              try {
                throw 'error';
              } catch (e) {
                return 5;
              }
              return 2;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(5));
    });

    test('Try/catch no error', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              try {
                print('hello');
              } catch (e) {
                return 4;
              }
              return 2;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(2));
    });

    test('Nested try/catch', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                try {
                  throw 'error';
                } catch (e) {
                  throw 'error2';
                }
              } catch (e) {
                return e;
              }
              return 'error3';
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main').$value,
          'error2');
    });

    test('Try/catch across function boundaries', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                return doThing();
              } catch (e) {
                return e + 'no';
              }
            }
            
            String doThing() {
              throw 'error';
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main').$value,
          'errorno');
    });

    test('Try/catch with on', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                return doThing();
              } on int catch (e) {
                return e.toString() + '2';
              } on String catch (e) {
                return e + 'no';
              }
            }
            
            String doThing() {
              throw 'error';
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main').$value,
          'errorno');
    });

    test('Return from finally precedes error', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                throw 'error';
              } finally {
                return 'finally';
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main').$value,
          'finally');
    });

    test('Error propagates through empty finally', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                throw 'error';
              } finally {}
            }
          ''',
        }
      });
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          throwsA($String('error')));
    });

    test('Return from catch is preceded by finally return', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                throw 'error';
              } catch (e) {
                return 'catch';
              } finally {
                return 'finally';
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main').$value,
          'finally');
    });

    test('Finally can do work and return value from catch', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                throw 'error';
              } catch (e) {
                return 'catch';
              } finally {
                print('finally');
              }
              print('should not print');
            }
          ''',
        }
      });
      expect(
          () => expect(
              runtime.executeLib('package:example/main.dart', 'main').$value,
              'catch'),
          prints('finally\n'));
    });

    test('Manipulating local variables in catch and finally', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var i = 0;
              try {
                throw 'error';
              } catch (e) {
                i++;
              } finally {
                i+=3;
              }
              return i;
            }
          ''',
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 4);
    });

    test('Try without throw skips catch but executes finally', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var i = 0;
              try {
                i++;
              } catch (e) {
                i+=2;
              } finally {
                i+=3;
              }
              return i;
            }
          ''',
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 4);
    });

    test('Nested try/catch/finally', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var i = 0;
              try {
                try {
                  throw 'error';
                } catch (e) {
                  i++;
                } finally {
                  i+=3;
                }
              } catch (e) {
                i+=5; // should not execute
              } finally {
                i+=7;
              }
              return i;
            }
          ''',
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 11);
    });

    test('Rethrow', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              try {
                throw 'error';
              } catch (e) {
                rethrow;
              }
              return 2;
            }
          ''',
        }
      });
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          throwsA($String('error')));
    });

    test('Simple assert', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              assert(false);
            }
          ''',
        }
      });
      expect(() => runtime.executeLib('package:example/main.dart', 'main'),
          throwsA(isA<AssertionError>()));
    });
  });
}
