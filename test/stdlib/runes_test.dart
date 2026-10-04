import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('Runes and RuneIterator preserve SDK Unicode iteration behavior', () {
    final program = Compiler().compile({
      'example': {
        'main.dart': '''
          int main() {
            const text = 'A😀B';
            final runes = text.runes;
            if (runes is! Runes || runes.length != 3) return 1;
            if (runes.first != 65 || runes.elementAt(1) != 128512 ||
                runes.last != 66) {
              return 2;
            }

            final direct = Runes(text);
            if (direct.string != text || direct.length != 3) return 3;

            final iterator = RuneIterator(text);
            if (!iterator.moveNext() ||
                iterator.current != 65 ||
                iterator.currentAsString != 'A' ||
                iterator.rawIndex != 0) {
              return 4;
            }
            if (!iterator.moveNext() ||
                iterator.current != 128512 ||
                iterator.currentSize != 2 ||
                iterator.currentAsString != '😀' ||
                iterator.rawIndex != 1) {
              return 5;
            }
            return 0;
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
