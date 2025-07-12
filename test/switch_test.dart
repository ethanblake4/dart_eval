import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  group('Switch statement tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('Basic switch with int cases', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var x = 2;
              switch (x) {
                case 1:
                  return 'one';
                case 2:
                  return 'two';
                case 3:
                  return 'three';
              }
              return 'none';
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('two'));
    });

    test('Switch with default case', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var x = 5;
              switch (x) {
                case 1:
                  return 'one';
                case 2:
                  return 'two';
                default:
                  return 'default';
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('default'));
    });

    test('Switch with string cases', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var fruit = 'apple';
              switch (fruit) {
                case 'apple':
                  return 1;
                case 'banana':
                  return 2;
                case 'orange':
                  return 3;
                default:
                  return 0;
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 1);
    });

    test('Switch with proper fall-through (empty cases)', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var x = 1;
              switch (x) {
                case 1:
                case 2:
                case 3:
                  return 'weekday';
                case 6:
                case 7:
                  return 'weekend';
                default:
                  return 'unknown';
              }
            }
          ''',
        }
      });
      expect(
          runtime.executeLib('package:example/main.dart', 'main'),
          $String(
              'weekday')); // x=1 falls through empty cases to execute 'weekday'
    });

    test('Switch with invalid fall-through should throw error', () {
      expect(() {
        compiler.compileWriteAndLoad({
          'example': {
            'main.dart': '''
              int main() {
                var x = 1;
                switch (x) {
                  case 1:
                    print("case 1");  // Code here
                  case 2:             // Invalid fall-through!
                    return 2;
                  default:
                    return 0;
                }
              }
            ''',
          }
        });
      }, throwsA(isA<Exception>()));
    });

    test('Switch with break statements', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var result = 0;
              var x = 2;
              switch (x) {
                case 1:
                  result += 10;
                  break;
                case 2:
                  result += 20;
                  break;
                case 3:
                  result += 30;
                  break;
                default:
                  result += 100;
              }
              return result;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 20);
    });

    test('Switch with multiple statements per case', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var x = 1;
              var result = 0;
              switch (x) {
                case 1:
                  result += 5;
                  result *= 2;
                  result += 3;
                  break;
                case 2:
                  result = 100;
                  break;
                default:
                  result = -1;
              }
              return result;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          13); // (0 + 5) * 2 + 3 = 13
    });

    test('Switch with no matching case and no default', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var x = 5;
              var result = 42;
              switch (x) {
                case 1:
                  result = 1;
                  break;
                case 2:
                  result = 2;
                  break;
              }
              return result;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 42);
    });

    test('Switch with expression evaluation', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var a = 2;
              var b = 3;
              switch (a + b) {
                case 4:
                  return 40;
                case 5:
                  return 50;
                case 6:
                  return 60;
                default:
                  return 0;
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 50);
    });

    test('Switch with boolean cases', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var flag = true;
              switch (flag) {
                case true:
                  return 'yes';
                case false:
                  return 'no';
              }
              return 'unknown';
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('yes'));
    });

    test('Nested switch statements', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var x = 1;
              var y = 2;
              switch (x) {
                case 1:
                  if (y == 1) return 11;
                  if (y == 2) return 12;
                  return 10;
                case 2:
                  return 20;
                default:
                  return 0;
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 12);
    });

    test('Switch with variable assignment in cases', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var x = 2;
              var result = 0;
              switch (x) {
                case 1:
                  var temp = 10;
                  result = temp;
                  break;
                case 2:
                  var temp = 20;
                  result = temp * 2;
                  break;
                default:
                  result = -1;
              }
              return result;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 40);
    });

    test('Switch with function calls in cases', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int helper(int value) {
              return value * 10;
            }
            
            int main() {
              var x = 1;
              switch (x) {
                case 1:
                  return helper(5);
                case 2:
                  return helper(3);
                default:
                  return 0;
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 50);
    });

    test('Switch with return in default case', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var x = 100;
              switch (x) {
                case 1:
                  return 'one';
                case 2:
                  return 'two';
                default:
                  return 'unknown value';
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('unknown value'));
    });

    test('Switch with multiple empty cases (enum-like)', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var day = 2; // Tuesday
              switch (day) {
                case 1: // Monday
                case 2: // Tuesday  
                case 3: // Wednesday
                case 4: // Thursday
                case 5: // Friday
                  return 'weekday';
                case 6: // Saturday
                case 7: // Sunday
                  return 'weekend';
                default:
                  return 'invalid';
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('weekday')); // Day 2 falls through to 'weekday'
    });

    test('Switch with const expression case', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            const int VALUE = 5;
            
            int main() {
              var x = 5;
              switch (x) {
                case VALUE:
                  return 100;
                case 6:
                  return 200;
                default:
                  return 0;
              }
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 100);
    });

    test('Empty switch statement', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              var x = 1;
              var result = 42;
              switch (x) {
              }
              return result;
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 42);
    });

    test('Switch with enum and proper fall-through', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum DiaDaSemana {
              segunda,
              terca,
              quarta,
              quinta,
              sexta,
              sabado,
              domingo,
            }

            String saudacao(DiaDaSemana dia) {
              switch (dia) {
                case DiaDaSemana.segunda:
                case DiaDaSemana.terca:
                case DiaDaSemana.quarta:
                case DiaDaSemana.quinta:
                case DiaDaSemana.sexta:
                  return 'Dia útil. Vamos trabalhar!';
                case DiaDaSemana.sabado:
                case DiaDaSemana.domingo:
                  return 'Final de semana! Aproveite!';
                default:
                  return 'Dia inválido';
              }
            }

            String main() {
              return saudacao(DiaDaSemana.terca);
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Dia útil. Vamos trabalhar!'));
    });

    test('Switch with enum weekend case', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum DiaDaSemana {
              segunda,
              terca,
              quarta,
              quinta,
              sexta,
              sabado,
              domingo,
            }

            String saudacao(DiaDaSemana dia) {
              switch (dia) {
                case DiaDaSemana.segunda:
                case DiaDaSemana.terca:
                case DiaDaSemana.quarta:
                case DiaDaSemana.quinta:
                case DiaDaSemana.sexta:
                  return 'Dia útil. Vamos trabalhar!';
                case DiaDaSemana.sabado:
                case DiaDaSemana.domingo:
                  return 'Final de semana! Aproveite!';
                default:
                  return 'Dia inválido';
              }
            }

            String main() {
              return saudacao(DiaDaSemana.domingo);
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Final de semana! Aproveite!'));
    });

    test('Switch with enum and vowel/consonant classification', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            enum Letra {
              a, b, c, d, e, f, g, h, i, j, k, l, m, 
              n, o, p, q, r, s, t, u, v, w, x, y, z
            }

            String classificar(Letra letra) {
              switch (letra) {
                case Letra.a:
                case Letra.e:
                case Letra.i:
                case Letra.o:
                case Letra.u:
                  return 'Vogal';
                default:
                  return 'Consoante';
              }
            }

            String main() {
              return classificar(Letra.e);
            }
          ''',
        }
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'),
          $String('Vogal'));
    });
  });
}
