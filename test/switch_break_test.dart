import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  late Compiler compiler;

  setUp(() {
    compiler = Compiler();
  });

  group('Switch break targets switch, not enclosing loop', () {
    test('for loop continues after switch break', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = 'a';
              for (var i = 0; i < 3; i++) {
                switch (x) {
                  case 'a':
                    x = 'b';
                    break;
                  case 'b':
                    x = 'a';
                    break;
                }
                print(x);
              }
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('b\na\nb\n'),
      );
    });

    test('while loop continues after switch break', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var i = 0;
              while (i < 3) {
                switch (i) {
                  case 0:
                    print('zero');
                    break;
                  case 1:
                    print('one');
                    break;
                  default:
                    print('other');
                }
                i++;
              }
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('zero\none\nother\n'),
      );
    });

    test('switch inside for inside while', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var n = 0;
              while (n < 2) {
                for (var i = 0; i < 2; i++) {
                  switch (i) {
                    case 0:
                      print('a');
                      break;
                    case 1:
                      print('b');
                      break;
                  }
                }
                n++;
              }
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('a\nb\na\nb\n'),
      );
    });
  });

  group('Switch variable reassignment in loops', () {
    test('string variable reassigned across iterations', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var mode = 'read';
              var log = <String>[];
              for (var i = 0; i < 4; i++) {
                switch (mode) {
                  case 'read':
                    log.add('R');
                    mode = 'write';
                    break;
                  case 'write':
                    log.add('W');
                    mode = 'idle';
                    break;
                  case 'idle':
                    log.add('I');
                    mode = 'read';
                    break;
                }
              }
              print(log.join(','));
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('R,W,I,R\n'),
      );
    });

    test('int variable cycles through cases', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = 0;
              for (var i = 0; i < 3; i++) {
                switch (x) {
                  case 0:
                    x = 1;
                    break;
                  case 1:
                    x = 2;
                    break;
                  default:
                    x = 0;
                }
              }
              print(x);
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('0\n'),
      );
    });

    test('default case hit after reassignment', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = 1;
              for (var i = 0; i < 2; i++) {
                switch (x) {
                  case 1:
                    print('one');
                    x = 99;
                    break;
                  default:
                    print('default');
                }
              }
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('one\ndefault\n'),
      );
    });
  });

  group('Nested switches', () {
    test('code runs after inner switch before outer break', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              for (var i = 0; i < 2; i++) {
                switch (i) {
                  case 0:
                    switch ('a') {
                      case 'a':
                        print('inner');
                        break;
                    }
                    print('after-inner');
                    break;
                  case 1:
                    print('one');
                    break;
                }
              }
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('inner\nafter-inner\none\n'),
      );
    });
  });

  group('Case fallthrough in loops', () {
    test('empty cases fall through', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              for (var i = 0; i < 4; i++) {
                switch (i) {
                  case 0:
                  case 1:
                    print('low');
                    break;
                  case 2:
                  case 3:
                    print('high');
                    break;
                }
              }
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('low\nlow\nhigh\nhigh\n'),
      );
    });
  });

  group('Switch on expressions', () {
    test('scrutinee function called exactly once', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            int calls = 0;
            int bump() {
              calls++;
              return 2;
            }
            void main() {
              switch (bump()) {
                case 1:
                  print('one');
                  break;
                case 2:
                  print('two');
                  break;
              }
              print(calls);
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('two\n1\n'),
      );
    });
  });

  group('Bare break in case', () {
    test('case with only break and fallthrough cases', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            void main() {
              var x = 1;
              switch (x) {
                case 1:
                  break;
                case 2:
                case 3:
                  print('two or three');
                  break;
              }
              print('done');
            }
          ''',
        },
      });
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        prints('done\n'),
      );
    });
  });
}
