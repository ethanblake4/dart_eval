import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Standard library tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Int unary -', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return -5;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), -5);
    });

    test('% operator', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              return 4.5 % 2;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 0.5);
    });

    test('Future.delayed()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          Future main(int milliseconds) {
            return Future.delayed(Duration(milliseconds: milliseconds));
          }
          '''
        }
      });

      final startTime = DateTime.now().millisecondsSinceEpoch;
      final future = runtime.executeLib('package:example/main.dart', 'main', [150]) as Future;
      await expectLater(future, completion(null));
      final endTime = DateTime.now().millisecondsSinceEpoch;
      expect(endTime - startTime, greaterThan(100));
      expect(endTime - startTime, lessThan(200));
    });

    test('Using a Future result', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          import 'dart:math';
          Future<num> main(int milliseconds) async {
            final result = await getPoint(milliseconds);
            return result.x + result.y;
          }

          Future<Point> getPoint(int milliseconds) async {
            await Future.delayed(Duration(milliseconds: milliseconds));
            return Point(5, 5);
          }
          '''
        }
      });

      final future = runtime.executeLib('package:example/main.dart', 'main', [150]) as Future;
      await expectLater(future, completion($num<num>(10)));
    });

    test('print()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
          void main(int whatToSay) {
            print(whatToSay);
          }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main', [56890]);
      }, prints('56890\n'));
    });

    test('Boolean literals', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              final a = true;
              final b = false;
              print(a);
              print(b);
              return b;
            }
          ''',
        }
      });
      expect(() {
        final a = runtime.executeLib('package:example/main.dart', 'main');
        expect(a, equals(false));
      }, prints('true\nfalse\n'));
    });

    test('Boxed bools, logical && and ||', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            dynamic main() {
              final a = true;
              final b = false;
              print(a && b);
              print(a || b);
              return b && a;
            }
          ''',
        }
      });
      expect(() {
        expect(runtime.executeLib('package:example/main.dart', 'main'), $bool(false));
      }, prints('false\ntrue\n'));
    });
    test('String interpolation', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              final a = "Hello";
              final b = 2;
              print("Fluffy\$a\$b, says the cat");
              return 2;
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('FluffyHello2, says the cat\n'));
    });

    test('dart:math Point', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:math';
            void main() {
              final a = Point(1, 2);
              final b = Point(3, 4);
              print(a.distanceTo(b));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('2.8284271247461903\n'));
    });

    test('Specifying doubles with int literals', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              final a = abc(3);
              return 4 + a + abc(3);
            }

            double abc(double x) {
              return x + 2.0;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 14.0);
    });

    test('Boxed null', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            dynamic main() {
              final a = abc();
              print(a['hello']);
              return a['hello'];
            }

            Map abc() {
              return {
                'hello': null
              };
            }
          ''',
        }
      });
      expect(() {
        expect(runtime.executeLib('package:example/main.dart', 'main'), $null());
      }, prints('null\n'));
    });

    test('StreamController and Stream.listen()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:async';
            Future main() async {
              final controller = StreamController<int>();
              controller.stream.listen((event) {
                print(event);
              });
              controller.add(1);
              controller.add(2);
              controller.add(3);
              await controller.close();
            }
          ''',
        }
      });
      expect(() async {
        await runtime.executeLib('package:example/main.dart', 'main').$value;
      }, prints('1\n2\n3\n'));
    });

    test('dart:math', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:math';
            void main() {
              print(pi.toString().substring(0, 8));
              print(pow(2, 3));
              print(sin(0));
              print(cos(0));
              print(tan(0));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('3.141592\n8\n0.0\n1.0\n0.0\n'));
    });

    test('RegExp hasMatch()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              final rg = RegExp(r'..s');
              print(rg.hasMatch('snakes'));
              print(rg.hasMatch('moon'));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('true\nfalse\n'));
    });

    test('RegExp hasMatch()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              final rg = RegExp(r'..s');
              print(rg.hasMatch('snakes'));
              print(rg.hasMatch('moon'));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('true\nfalse\n'));
    });

    test('Pattern allMatches() with RegExp', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              final exp = RegExp(r'(\\w+)');
              var str = 'Dash is a bird';
              final matches = exp.allMatches(str, 8);
              for (final Match m in matches) {
                final match = m[0];
                print(match);
              }
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('a\nbird\n'));
    });
  });
}
