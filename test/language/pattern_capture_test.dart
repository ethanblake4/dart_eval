import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
final captures = <String Function()>[];
bool capture(String Function() closure, bool accept) {
  captures.add(closure);
  return accept;
}
bool main() {
  if (['one', 'two'] case [var a, var b]
      when capture(() => a, true) && capture(() => b, true)) {
    a = 'after';
    b = 'then';
  }
  if (captures.map((f) => f()).join(' ') != 'after then') return false;
  captures.clear();
  switch (['one', 'two']) {
    case [var a, var b] when capture(() => a, true):
      a = 'single';
      b = 'unused';
  }
  if (captures.single() != 'single') return false;
  captures.clear();
  switch (['one', 'two']) {
    case [var a, var b] when capture(() => a, false):
    case [var b, var a] when capture(() => a, true):
      captures.add(() => a);
      a = 'body';
      b = 'unused';
  }
  if (captures.map((f) => f()).join(' ') != 'one two body') return false;
  captures.clear();
  if (['one', 'two'] case [var a, 'miss'] || ['one', var a]
      when capture(() => a, true)) {
    a = 'alternative';
  }
  if (captures.single() != 'alternative') return false;
  captures.clear();
  var (a, b) = ('one', 'two');
  captures.add(() => a);
  a = 'declaration';
  return captures.single() == 'declaration' && b == 'two';
}
''';

void main() {
  test('pattern guards and bodies retain their lexical capture identities', () {
    final program = Compiler().compile({
      'pattern_capture': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:pattern_capture/main.dart', 'main'),
        true,
      );
    }
  });
}
