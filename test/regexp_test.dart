import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';

void main() {
  late Compiler compiler;

  setUp(() {
    compiler = Compiler();
  });
  group('Regex Tests', () {
    test('RegExp.firstMatch()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              final string = '[00:13.37] This is a chat message.';
              final regExp = RegExp(r'c\\w*');
              final match = regExp.firstMatch(string);
              return match![0]!;
          }''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'main') as $String)
            .$value,
        'chat',
      );
    });

    test('RegExp.allMatches()', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            List<String> main() {
              final List<String> results = [];
              final exp = RegExp(r'(\\w+)');
              final str = 'Dash is a bird';
              
              final matches = exp.allMatches(str, 8);
              for (final m in matches) {
                results.add(m[0]);
              }
              return results;
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'main') as List).map(
          (e) => (e as $String).$value,
        ),
        ['a', 'bird'],
      );
    });

    test('RegExp.stringMatch() if has match', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String main() {
              var string = 'Dash is a bird';
              var regExp = RegExp(r'(humming)?bird');
              
              var match = regExp.stringMatch(string);
              
              return match;  
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'main') as $String)
            .$value,
        'bird',
      );
    });

    test('RegExp.stringMatch() if no match', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            String? main() {
              final string = 'Dash is a bird';
              final regExp = RegExp(r'dog');
              final match = regExp.stringMatch(string);
              return match;  
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'main') as $null)
            .$value,
        null,
      );
    });

    test('RegExp.groups', () {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:convert';

            String main() {
              final string = '[00:13.37] This is a chat message.';
              final regExp = RegExp(r'^\\[\\s*(\\d+):(\\d+)\\.(\\d+)\\]\\s*(.*)\$');
              final match = regExp.firstMatch(string);
              final message = json.encode(match.groups([1, 2, 3, 4]));
            
              return message;
            }
          ''',
        },
      });
      expect(
        (runtime.executeLib('package:example/main.dart', 'main') as $String)
            .$value,
        '["00","13","37","This is a chat message."]',
      );
    });
  });

  test('RegExp.groupNames', () {
    final runtime = compiler.compileWriteAndLoad({
      'example': {
        'main.dart': '''
            List<String> main() {
              final regex = RegExp(r'(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})');
              final match = regex.firstMatch('2023-10-27');

              return match.groupNames.toList();
            }
          ''',
      },
    });
    expect(
      (runtime.executeLib('package:example/main.dart', 'main') as List).map(
        (e) => (e as $String).$value,
      ),
      ['year', 'month', 'day'],
    );
  });

  test('RegExp.groupCount', () {
    final runtime = compiler.compileWriteAndLoad({
      'example': {
        'main.dart': '''
            int main() {
              final string = '[00:13.37] This is a chat message.';
              final regExp = RegExp(r'c\\w*');
              final match = regExp.firstMatch(string);
              return match.groupCount;
            }
          ''',
      },
    });
    expect((runtime.executeLib('package:example/main.dart', 'main') as int), 0);
  });

  test('RegExp.pattern', () {
    final runtime = compiler.compileWriteAndLoad({
      'example': {
        'main.dart': '''
            RegExp main() {
              final string = '[00:13.37] This is a chat message.';
              final regExp = RegExp(r'c\\w*');
              final match = regExp.firstMatch(string);
              return match.pattern;
            }
          ''',
      },
    });
    expect(
      (runtime.executeLib('package:example/main.dart', 'main') as $RegExp)
          .$value,
      RegExp(r'c\w*'),
    );
  });

  test('RegExp.input', () {
    final runtime = compiler.compileWriteAndLoad({
      'example': {
        'main.dart': '''
            String main() {
              final string = '[00:13.37] This is a chat message.';
              final regExp = RegExp(r'c\\w*');
              final match = regExp.firstMatch(string);
              return match.input;
            }
          ''',
      },
    });
    expect(
      (runtime.executeLib('package:example/main.dart', 'main') as $String)
          .$value,
      '[00:13.37] This is a chat message.',
    );
  });
}
