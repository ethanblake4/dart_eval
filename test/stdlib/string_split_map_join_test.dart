import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('String.splitMapJoin forwards optional callbacks and defaults', () {
    final program = Compiler().compile({
      'example': {
        'main.dart': '''
          int main() {
            final mapped = 'a1b2'.splitMapJoin(
              RegExp(r'\\d'),
              onMatch: (match) => '[\${match.group(0)}]',
              onNonMatch: (text) => text.toUpperCase(),
            );
            if (mapped != 'A[1]B[2]') return 1;

            var matches = 0;
            final unmatched = 'abc'.splitMapJoin(
              RegExp(r'z'),
              onMatch: (match) {
                matches++;
                return 'unexpected';
              },
              onNonMatch: (text) => '<\$text>',
            );
            if (unmatched != '<abc>' || matches != 0) return 2;

            final zeroWidth = 'ab'.splitMapJoin(
              RegExp(r'(?=b)'),
              onMatch: (match) => '|',
              onNonMatch: (text) => '<\$text>',
            );
            if (zeroWidth != '<a>|<b>') return 3;

            if ('a1b'.splitMapJoin(RegExp(r'\\d')) != 'a1b') return 4;
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
