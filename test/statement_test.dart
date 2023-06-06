import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Statement tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('For loop', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              for (; i < 555; i++) {}
              return i;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(555));
    });

    test('For loop + branching', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          dynamic doThing() {
            var count = 0;
            for (var i = 0; i < 1000; i++) {
              if (count < 500) {
                count--;
              } else if (count < 750) {
                count++;
              }
              count += i;
            }
            
            return count;
          }
        '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'doThing'), $int(499472));
    });

    test('Simple foreach', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              var i = 0;
              for (var x in [1, 2, 3, 4, 5]) {
                i += x;
              }
              return i;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), $int(15));
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
      expect(runtime.executeLib('package:example/main.dart', 'main').$value, 'error2');
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
      expect(runtime.executeLib('package:example/main.dart', 'main').$value, 'errorno');
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
      expect(runtime.executeLib('package:example/main.dart', 'main').$value, 'errorno');
    });
  });
}
