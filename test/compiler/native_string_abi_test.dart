import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:string_abi/main.dart';

void expectResult(String source, String expected) {
  final program = Compiler().compile({
    'string_abi': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('String calls cross named defaults and constructor field storage', () {
    expectResult(r'''
      String decorate(String value, {String left = '[', String right = ']'}) =>
          '$left$value$right';

      class Label {
        Label(this.text, {this.suffix = '.'});
        final String text;
        final String suffix;

        String render() => decorate(text, left: '<', right: suffix);
      }

      String main() {
        final first = Label(decorate('x'), suffix: '!');
        final second = Label('q');
        return first.render() + '|' + second.render();
      }
    ''', '<[x]!|<q.');
  });

  test('String tear-offs cross dynamic and generic closure paths', () {
    expectResult(r'''
      String trace = '';

      String suffix(String value, {String ending = '!'}) => '$value$ending';

      String apply<T>(T value, String Function(T) callback) => callback(value);

      String invoke(dynamic callback, String value) => callback(value) as String;

      String recurse(String value, int depth) {
        if (depth == 0) return value;
        try {
          return recurse(suffix(value, ending: 'x'), depth - 1);
        } finally {
          trace += 'f';
        }
      }

      String main() {
        final typed = apply<String>('a', suffix);
        dynamic callback = suffix;
        final loose = invoke(callback, 'b');
        final nested = recurse('c', 2);
        return '$typed|$loose|$nested|$trace';
      }
    ''', 'a!|b!|cxx|ff');
  });
}
