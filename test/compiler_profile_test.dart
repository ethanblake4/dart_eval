import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('profiling preserves fresh and cached compilation output', () {
    final phases = <String, int>{};
    final compiler = Compiler(onPhase: (phase, time) => phases[phase] = time);
    final sources = {
      'profile': {
        'main.dart': '''
int sum(List<int> values) {
  var total = 0;
  for (final value in values) total += value;
  return total;
}
int main() => sum([1, 2, 3]);
''',
      },
    };
    final expected = Compiler().compile(sources).write();
    for (var i = 0; i < 2; i++) {
      expect(compiler.compile(sources).write(), expected);
      expect(phases, isNotEmpty);
      phases.clear();
    }
    final typed = compiler.compileTyped(
      sources,
      entrypoint: 'package:profile/main.dart',
    );
    expect(
      typed.write().buffer.asUint8List(),
      Compiler()
          .compileTyped(sources, entrypoint: 'package:profile/main.dart')
          .write()
          .buffer
          .asUint8List(),
    );
  });

  test('explicit loading leaves guest global initialization lazy', () {
    final program = Compiler().compile({
      'profile': {
        'main.dart': '''
int fail() => throw StateError('guest initializer');
final value = fail();
int main() => value;
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.initialize();
      runtime.initialize();
      expect(
        () => runtime.executeLib('package:profile/main.dart', 'main'),
        throwsA(anything),
      );
    }
  });
}
