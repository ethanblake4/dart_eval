import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _types = '''
  class Token {}
  class Tag extends Token {
    final String name;
    Tag(this.name);
  }
''';

void main() {
  test('completed condition null assertions promote on both outcomes', () {
    final program = Compiler().compile({
      'assertions': {
        'main.dart': '''
          String take(String value) => value;
          String inspect(String? data) {
            if ('abc'.contains(data!)) return take(data);
            return take(data);
          }
          bool throwing() {
            try { inspect(null); } on TypeError { return true; }
            return false;
          }
          bool skipped(String? data) => true || 'abc'.contains(data!);
          bool main() => inspect('a') == 'a' && inspect('z') == 'z' &&
              skipped(null) && throwing();
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:assertions/main.dart', 'main'), true);
    }
  });

  for (final (label, body) in <(String, String)>[
    ('skipped OR assertion', "if (skip || 'abc'.contains(data!)) take(data);"),
    (
      'skipped conditional assertion',
      "if (skip ? true : 'abc'.contains(data!)) take(data);",
    ),
    (
      'later assertion condition assignment',
      "if ('abc'.contains(data!) && (data = null) == null) take(data);",
    ),
    (
      'recorded assertion proof after a write',
      "bool matched = 'abc'.contains(data!); data = null; if (matched) take(data);",
    ),
    (
      'write-captured assertion local',
      "void replace() { data = null; } if ('abc'.contains(data!)) take(data); replace();",
    ),
    (
      'skipped coalescing assignment assertion',
      "bool? matched = skip; if (matched ??= 'abc'.contains(data!)) take(data);",
    ),
  ]) {
    test('$label does not establish a non-null promotion', () {
      expect(
        () => Compiler().compile({
          'assertions': {
            'main.dart':
                '''
          void take(String value) {}
          void inspect(String? data, bool skip) { $body }
          void main() { inspect('a', true); }
        ''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }

  test('completed condition casts promote on the executed logical paths', () {
    final program = Compiler().compile({
      'casts': {
        'main.dart':
            '''
          $_types
          bool and(Token token, bool enabled) => enabled &&
              (token as Tag).name != 'x' && token.name != 'y';
          bool or(Token token) =>
              (token as Tag).name == 'x' || token.name == 'y';
          bool skipped(Token token, bool skip) =>
              skip || (token as Tag).name == 'x';
          String branches(Token token) {
            if ((token as Tag).name == 'x') return token.name;
            return token.name;
          }
          bool throwing() {
            try { and(Token(), true); } on TypeError { return true; }
            return false;
          }
          bool main() => and(Tag('z'), true) && !and(Token(), false) &&
              or(Tag('y')) && skipped(Token(), true) &&
              branches(Tag('x')) == 'x' && branches(Tag('z')) == 'z' &&
              throwing();
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:casts/main.dart', 'main'), true);
    }
  });

  for (final (label, body) in <(String, String)>[
    (
      'skipped OR cast',
      '''
      if (skip || (token as Tag).name == 'x') return token.name;
    ''',
    ),
    (
      'skipped conditional cast',
      '''
      if (skip ? true : (token as Tag).name == 'x') return token.name;
    ''',
    ),
    (
      'later condition assignment',
      '''
      if ((token as Tag).name == 'x' && (token = Token()) != null) {
        return token.name;
      }
    ''',
    ),
    (
      'recorded proof after a write',
      '''
      bool matched = (token as Tag).name == 'x';
      token = Token();
      if (matched) return token.name;
    ''',
    ),
    (
      'write-captured local',
      '''
      void replace() { token = Token(); }
      if ((token as Tag).name == 'x') return token.name;
      replace();
    ''',
    ),
    (
      'skipped coalescing assignment cast',
      '''
      bool? matched = skip;
      if (matched ??= (token as Tag).name == 'x') return token.name;
    ''',
    ),
  ]) {
    test('$label does not establish a cast promotion', () {
      expect(
        () => Compiler().compile({
          'casts': {
            'main.dart':
                '''
              $_types
              String inspect(Token token, bool skip) {
                $body
                return '';
              }
              String main() => inspect(Tag('x'), true);
            ''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
