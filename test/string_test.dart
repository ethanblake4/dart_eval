import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';

void main() {
  late Compiler compiler;

  setUp(() {
    compiler = Compiler();
  });
  group('String Class method tests', () {
    test('String has isEmpty getter', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              if (cat.isNotEmpty) return 1;
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 1);
    });
    test('String has length getter', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              return cat.length;
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 6);
    });
    test('String substring method works with only 1 parameter', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              String sub = cat.substring(3);
              print(sub);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('ffy\n'));
    });
    test('String has substring method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              String sub = cat.substring(0,3);
              print(sub);
            }
          ''',
        },
      });
      expect(() {
        runtime.executeLib('package:example/main.dart', 'main');
      }, prints('Flu\n'));
    });
    test('String has compareTo method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              String cat2 = "Fluffz";
              return cat.compareTo(cat2);
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), -1);
    });
    test('String has endsWith method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              String fin = "fy";
              if (cat.endsWith(fin)) return 1; else return 0;
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 1);
    });
    test('String has codeUnitAt method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              return cat.codeUnitAt(3);
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 102);
    });

    test('String has contains method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool main() {
              String cat = "Fluffy";
              return cat.contains("fy");
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), true);
    });
    test('String has indexOf method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              return cat.indexOf("uf");
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 2);
    });
    test('String indexOf method uses start optional parameter', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              return cat.indexOf("uf", 3);
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), -1);
    });
    test('String has lastIndexOf method', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              return cat.lastIndexOf("f");
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), 4);
    });
    test('String lastIndexOf method uses start optional parameter', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int main() {
              String cat = "Fluffy";
              return cat.lastIndexOf("f", 2);
            }
          ''',
        },
      });
      expect(runtime.executeLib('package:example/main.dart', 'main'), -1);
    });
    test('String padLeft method formats with default padding', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const str = "D";
              return str.padLeft(4);
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        '   D',
      );
    });
    test('String padLeft method formats with given padding', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const str = "D";
              return str.padLeft(4, "y");
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'yyyD',
      );
    });
    test('String padRight method formats with default padding', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const str = "D";
              return str.padRight(4);
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'D   ',
      );
    });
    test('String padRight method formats with given padding', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const str = "D";
              return str.padRight(4, "y");
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'Dyyy',
      );
    });
    test('String replaceAll method replaces text', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "Fluffy";
              return cat.replaceAll("f", "z");
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'Fluzzy',
      );
    });
    test('String replaceFirst method replaces with default start index', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "Fluffy";
              return cat.replaceFirst('f', 'z');
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'Fluzfy',
      );
    });
    test('String replaceFirst method replaces with given start index', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "Fluffy";
              return cat.replaceFirst('f', 'z', 4);
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'Flufzy',
      );
    });
    test('String toString method returns same string', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "Fluffy";
              return cat.toString();
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'Fluffy',
      );
    });
    test('String replaceRange method replaces default range', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "Fluffy";
              return cat.replaceRange(4, null, 'z');
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'Flufz',
      );
    });
    test('String replaceRange method replaces given range', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "Fluffy";
              return cat.replaceRange(4, 6, 'z');
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        'Flufz',
      );
    });
    test('String startsWith method finds match', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            bool test() {
              const cat = "Fluffy";
              return cat.startsWith('Flu');
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as bool),
        true,
      );
    });
    test('String trimLeft method trims whitespace', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "  Fluffy ";
              return cat.trimLeft();
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        "Fluffy ",
      );
    });
    test('String split splits on given pattern', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            List<String> test() {
              const cat = "Fluffy";
              return cat.split("ff");
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test')).length,
        2,
      );
      expect(
        (runtime.executeLib('package:example/main.dart', 'test'))[0],
        $String("Flu"),
      );
      expect(
        (runtime.executeLib('package:example/main.dart', 'test'))[1],
        $String("y"),
      );
    });
    test('String trimRight method trims whitespace', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String test() {
              const cat = "  Fluffy   ";
              return cat.trimRight();
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'test') as $String)
            .$value,
        "  Fluffy",
      );
    });
  });
}
