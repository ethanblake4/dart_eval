import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
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

    test('~/ operator', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              final a =  45 ~/ 21;
              return a;
            }
          '''
        }
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 2);
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
        expect(runtime.executeLib('package:example/main.dart', 'main'),
            $bool(false));
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
        expect(
            runtime.executeLib('package:example/main.dart', 'main'), $null());
      }, prints('null\n'));
    });

    test('dynamic.toString', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            dynamic main() {
              final a = abc();
              print(a.toString());
            }
            
            dynamic abc() {
              return {
                'hello': null
              };
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('{hello: null}\n'));
    });

    test('List.where', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            Iterable<int> main() {
              final List<int> a = [1, 2, 1, 4, 1];              
              return a.where((element) => element == 1);
            }
          ''',
        }
      });
      expect(
          ((runtime.executeLib('package:example/main.dart', 'main') as $Value)
                  .$reified as Iterable)
              .toList(),
          [$int(1), $int(1), $int(1)]);
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

    test('Num add', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num ADD(num a, num b){
              return a + b;
            }
            void main() {
              print(ADD(3,4));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('7\n'));
    });

    test('Num/int parse and tryParse', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(num.parse('3'));
              print(num.tryParse('3'));
              print(num.tryParse('3.5'));
              print(num.tryParse('3.5a'));
              print(int.parse('3'));
              print(int.tryParse('3'));
              print(int.tryParse('3.5'));
              print(int.tryParse('3.5a'));
              print(int.tryParse('11', radix: 2));
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('3\n3\n3.5\nnull\n3\n3\nnull\nnull\n3\n'));
    });

    test('int.parse value from String.split', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              final a = '3:4';
              final b = a.split(':');
              print(int.parse(b[0]));
            }
          '''
        }
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('3\n'));
    });
    test('Iterable.generate', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(Iterable.generate(3, (i) => i)); 
              // check if works for non-integers
              print(Iterable.generate(2, (i) => 'test'));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('(0, 1, 2)\n(\$"test", \$"test")\n'));
    });

    test('Iterable.generate without generator', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(Iterable.generate(3));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('(0, 1, 2)\n'));
    });

    test('List.generate', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(List.generate(3, (i) => i));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('[0, 1, 2]\n'));
    });

    test('List.of', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(List.of([0, 1, 2], growable: true));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('[0, 1, 2]\n'));
    });

    test('List.from', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(List<int>.from([0, 1, 2], growable: true));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('[0, 1, 2]\n'));
    });

    test('Object.hash', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(Object.hash(1, 2, 3));
              print(Object.hash(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, null));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      },
          prints('${Object.hash(1, 2, 3)}\n'
              '${Object.hash(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, null)}\n'));
    });

    test('int.compareTo', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(1.compareTo(2));
              print(2.compareTo(1));
              print(1.compareTo(1));
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('-1\n1\n0\n'));
    });

    test('num.toDouble', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print(1.toDouble());
              print(2.toDouble());
              print(1.toDouble());
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('1.0\n2.0\n1.0\n'));
    });

    test('num.abs', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              print((-5).abs());
              print((5).abs());
              print((0).abs());
              print((-2.5).abs());
              print((1.5).abs());
            }
          ''',
        }
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('5\n5\n0\n2.5\n1.5\n'));
    });

    test('Printing hashCode', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            bool main() {
              final value = 5;
              final valueHashCode = value.hashCode;
              print('hashCode \$valueHashCode');
              return true;
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('double.infinity', () {
      final program = compiler.compile({
        'example': {
          'main.dart': '''
            double main() {
              return double.infinity;
            }
          '''
        }
      });

      final runtime = Runtime.ofProgram(program);
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          double.infinity);
    });
  });
}
