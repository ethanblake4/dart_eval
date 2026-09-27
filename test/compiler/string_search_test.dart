import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:string_search/main.dart';

Program _compile(String source) => Compiler().compile({
  'string_search': {'main.dart': source},
});

void _expectTrue(Program program) {
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), isTrue);
  }
}

void main() {
  test(
    'native search and suffix preserve UTF-16 indices and empty strings',
    () {
      final program = _compile('''
      String suffix(String text, String separator) =>
          text.substring(text.indexOf(separator) + separator.length);
      bool main() {
        final text = '😀=value';
        return text.indexOf('=') == 2 && suffix(text, '=') == 'value' &&
            text.indexOf('missing') == -1 && text.indexOf('') == 0 &&
            text.substring(text.length) == '' && ''.substring(0) == '';
      }
    ''');
      expect(
        program.typedProgram.instructions.map((entry) => entry.$2.name),
        containsAll(['aStringIndexOfRS', 'rStringSubRA']),
      );
      _expectTrue(program);
    },
  );

  test('suffix range errors remain catchable', () {
    _expectTrue(
      _compile('''
      bool invalid(String text, int start) {
        try { text.substring(start); } on RangeError { return true; }
        return false;
      }
      bool main() => invalid('abc', -1) && invalid('abc', 4);
    '''),
    );
  });

  test('explicit offsets and nullable endpoints retain their semantics', () {
    _expectTrue(
      _compile('''
      bool check(String text, int? end) => text.substring(1, end) == 'bcabc';
      bool main() => 'abcabc'.indexOf('a', 1) == 3 && check('abcabc', null);
    '''),
    );
  });

  test('Pattern parameters retain member dispatch', () {
    final program = _compile('''
      int search(String text, Pattern pattern) => text.indexOf(pattern);
      bool main() => search('abc', 'b') == 1;
    ''');
    expect(
      program.typedProgram.instructions.map((entry) => entry.$2.name),
      isNot(contains('aStringIndexOfRS')),
    );
    _expectTrue(program);
  });

  test('custom and null-aware receivers preserve dispatch and evaluation', () {
    _expectTrue(
      _compile('''
      class Custom {
        int indexOf(String value) => 7;
        String substring(int start) => 'custom';
      }
      int calls = 0;
      String key() { calls++; return 'x'; }
      bool absent(String? text) => text?.indexOf(key()) == null;
      bool main() {
        final custom = Custom();
        return custom.indexOf('x') == 7 && custom.substring(2) == 'custom' &&
            absent(null) && calls == 0;
      }
    '''),
    );
  });
}
