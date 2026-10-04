import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('Stopwatch is registered in the core plugin', () {
    final program = Compiler().compile({
      'example': {
        'main.dart': '''
          int main() {
            final watch = Stopwatch();
            if (watch.isRunning) return 1;
            watch.start();
            if (!watch.isRunning) return 2;
            watch.stop();
            if (watch.isRunning) return 3;
            if (watch.elapsedMicroseconds < 0) return 4;
            watch.reset();
            return watch.isRunning ? 5 : 0;
          }
        ''',
      },
    });

    for (final (kind, candidate) in [
      ('fresh', program),
      ('serialized', Program.read(program.write().buffer)),
    ]) {
      final runtime = Runtime.ofProgram(candidate);
      expect(
        runtime.executeLib('package:example/main.dart', 'main'),
        0,
        reason: kind,
      );
    }
  });
}
