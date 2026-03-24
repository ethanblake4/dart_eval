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
          ''',
        },
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
          ''',
        },
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
          ''',
        },
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
          ''',
        },
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
        },
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
        },
      });
      expect(() {
        expect(
          runtime.executeLib('package:example/main.dart', 'main'),
          $bool(false),
        );
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
        },
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('FluffyHello2, says the cat\n'));
    });

    test('toString inside interpolation', () {
      final runtime = compiler.compileWriteAndLoad({
        'eval_test': {
          'main.dart': '''
            class X {
              toString() => 'string';
            }

            void main() {
              print('test \${X()}');
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:eval_test/main.dart', 'main');
      }, prints('test string\n'));
    }, skip: true);

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
        },
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
        },
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
        },
      });
      expect(() {
        expect(
          runtime.executeLib('package:example/main.dart', 'main'),
          $null(),
        );
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
        },
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
        },
      });
      expect(
        ((runtime.executeLib('package:example/main.dart', 'main') as $Value)
                    .$reified
                as Iterable)
            .toList(),
        [$int(1), $int(1), $int(1)],
      );
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
        },
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
        },
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
        },
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
        },
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
        },
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
        },
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
          ''',
        },
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
          ''',
        },
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
        },
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
        },
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
        },
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
        },
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
        },
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
        },
      });
      expect(
        () {
          runtime.executeLib('package:example/main.dart', 'main');
        },
        prints(
          '${Object.hash(1, 2, 3)}\n'
          '${Object.hash(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, null)}\n',
        ),
      );
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
        },
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
        },
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
        },
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
          ''',
        },
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
          ''',
        },
      });

      final runtime = Runtime.ofProgram(program);
      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        double.infinity,
      );
    });

    test('num.floor()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return 3.7.floor();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('num.round()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return 3.7.round();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 4);
    });

    test('num.truncate()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return 3.7.truncate();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('num.clamp()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              return 5.clamp(1, 3);
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $num ? result.$value : result, 3);
    });

    test('num.remainder()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            num main() {
              return 5.remainder(3);
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $num ? result.$value : result, 2);
    });

    test('num.toStringAsFixed()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final a = 3.14159;
              return a.toStringAsFixed(2);
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $String ? result.$reified : result, '3.14');
    });

    test('num.toStringAsExponential()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final a = 1234;
              return a.toStringAsExponential(2);
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $String ? result.$reified : result, '1.23e+3');
    });

    test('num.toStringAsPrecision()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final a = 0.00012;
              return a.toStringAsPrecision(2);
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $String ? result.$reified : result, '0.00012');
    });

    test('num.ceilToDouble()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              return 3.2.ceilToDouble();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 4.0);
    });

    test('num.floorToDouble()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              return 3.8.floorToDouble();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3.0);
    });

    test('num.roundToDouble()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              return 3.4.roundToDouble();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3.0);
    });

    test('num.truncateToDouble()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              return 3.7.truncateToDouble();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3.0);
    });

    test('num.isNaN', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              return double.nan.isNaN;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('num.isInfinite', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              return double.infinity.isInfinite;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('num.isNegative', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              final a = -5;
              return a.isNegative;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('num.isFinite', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              final a = 3.14;
              return a.isFinite;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('num.sign', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              final a = -5;
              print(a.sign);
            }
          ''',
        },
      });

      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('-1\n'));
    });

    test('int.gcd()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return 48.gcd(18);
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 6);
    });

    test('int.modPow()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return 2.modPow(10, 1000);
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 24);
    });

    test('int.modInverse()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return 3.modInverse(11);
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 4);
    });

    test('int.toSigned()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return 0xFF.toSigned(8);
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), -1);
    });

    test('int.toUnsigned()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return (-1).toUnsigned(8);
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 255);
    });

    test('int.isEven', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              final a = 4;
              return a.isEven;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('int.isOdd', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              final a = 5;
              return a.isOdd;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('int.bitLength', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              final a = 7;
              return a.bitLength;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3);
    });

    test('int.sign', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              final a = 5;
              return a.sign;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 1);
    });

    test('double.parse()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              return double.parse('3.14');
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 3.14);
    });

    test('double.tryParse()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double? main() {
              final result = double.tryParse('3.14');
              if (result != null) {
                return result;
              }
              return null;
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $double ? result.$value : result, 3.14);
    });

    test('double.tryParse() returns null for invalid input', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              final result = double.tryParse('invalid');
              return result == null;
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });

    test('double.parse() with onError callback', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            double main() {
              return double.parse('invalid', (source) => 42.0);
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), 42.0);
    });

    test('double.parse() throws FormatException without onError', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              try {
                double.parse('invalid');
                return 'no exception';
              } catch (e) {
                return 'caught exception';
              }
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $String ? result.$reified : result, 'caught exception');
    });

    test('num.floor() with negative number', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return (-3.7).floor();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), -4);
    });

    test('num.ceil() with negative number', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return (-3.7).ceil();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), -3);
    });

    test('num.round() with negative number', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return (-3.7).round();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), -4);
    });

    test('num.truncate() with negative number', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              return (-3.7).truncate();
            }
          ''',
        },
      });

      expect(runtime.executeLib('package:example/main.dart', 'main'), -3);
    });

    test('num.toStringAsExponential() without arguments', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              return 123.456.toStringAsExponential();
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      final stringResult = result is $String ? result.$reified : result;
      expect(stringResult, contains('e'));
      expect(stringResult, contains('1.23456'));
    });

    test('num.toStringAsExponential() with fractionDigits parameter', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              return 123.456.toStringAsExponential(2);
            }
          ''',
        },
      });

      final result = runtime.executeLib('package:example/main.dart', 'main');
      expect(result is $String ? result.$reified : result, '1.23e+2');
    });

    test('int.parse in map chain with accumulation', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var raw = '10,20,30,40,50';
              var values = raw.split(',').map((s) => int.parse(s));
              var total = 0;
              for (final v in values) {
                total += v;
              }
              print(total);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('150\n'));
    });

    test('double + dynamic', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = 1.5;
              dynamic y = 2;
              print(x + y);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('3.5\n'));
    });

    test('num -= dynamic in loop', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              num x = 100;
              List<dynamic> nums = [10, 20, 30];
              for (final v in nums) {
                x -= v;
              }
              print(x);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('40\n'));
    });
  });
}
