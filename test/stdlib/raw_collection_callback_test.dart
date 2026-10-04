import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('imported raw collection callbacks use default class arguments', () {
    final program = Compiler().compile({
      'probe': {
        'values.dart': '''
          int read(int token) => token;
          int sum(dynamic values) {
            if (values is Map) {
              return values.map((key, value) =>
                MapEntry(read(key), read(value))).values.first;
            }
            if (values is List) return values.map((value) => read(value)).first;
            return 0;
          }
        ''',
        'main.dart': '''
          import 'values.dart';
          int main() => sum({2: 3}) + sum([4]);
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:probe/main.dart', 'main'), 7);
    }
  });

  test('raw map callback retains imported guest instances', () {
    final program = Compiler().compile({
      'probe': {
        'values.dart': '''
          class Token { final int value; Token(this.value); }
          int read(Token token) => token.value;
          int sum(dynamic values) {
            if (values is Map) {
              return values.map((key, value) =>
                MapEntry(read(key), read(value))).values.first;
            }
            if (values is List) return values.map((value) => read(value)).first;
            return 0;
          }
        ''',
        'main.dart': '''
          import 'values.dart';
          int main() => sum({Token(2): Token(3)}) + sum([Token(4)]);
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:probe/main.dart', 'main'), 7);
    }
  });

  for (final (body, call) in [
    ('int checked<K>(K value) => read(value);', 'checked<String>("wrong")'),
    (
      'int checked<K, V>(Map<K, V> values) => '
          'values.map((key, value) => MapEntry(read(key), read(value))).values.first;',
      'checked<String, String>({"key": "wrong"})',
    ),
    (
      'int checked<T>(List<T> values) => values.map((value) => read(value)).first;',
      'checked<String>(["wrong"])',
    ),
  ]) {
    test('explicit generic callback arguments remain checked: $body', () {
      expect(
        () => Compiler().compile({
          'probe': {
            'values.dart':
                '''
              int read(int token) => 1;
              $body
            ''',
            'main.dart': "import 'values.dart'; int main() => $call;",
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
