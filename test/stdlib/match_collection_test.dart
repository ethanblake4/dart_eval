import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  for (final encoded in [false, true]) {
    final mode = encoded ? 'encoded' : 'fresh';

    test(
      'native matches retain their interfaces through a raw view ($mode)',
      () {
        final program = Compiler().compile({
          'example': {
            'main.dart': r'''
            import 'dart:collection';

            String main() {
              final parts = [];
              'user'.splitMapJoin(RegExp(r'(?<name>user)'), onMatch: (m) {
                parts.add(m);
                return '';
              });
              'user'.splitMapJoin('user', onMatch: (m) {
                parts.add(m);
                return '';
              });
              parts.add(Object());
              final view = UnmodifiableListView(parts);
              var result = '';
              for (var part in view) {
                if (part is RegExpMatch) {
                  result += part.namedGroup('name')!;
                } else if (part is Match) {
                  result += ':' + part.group(0)!;
                } else {
                  result += ':object';
                }
              }
              return result;
            }
          ''',
          },
        });
        final runtime = encoded
            ? Runtime(program.write().buffer)
            : Runtime.ofProgram(program);
        expect(
          runtime.executeLib('package:example/main.dart', 'main'),
          'user:user:object',
        );
      },
    );

    test('unrelated objects still fail a Match cast ($mode)', () {
      final program = Compiler().compile({
        'example': {
          'main.dart': '''
            import 'dart:collection';
            String main() {
              final view = UnmodifiableListView([Object()]);
              for (var part in view) {
                return (part as Match).group(0)!;
              }
              return '';
            }
          ''',
        },
      });
      final runtime = encoded
          ? Runtime(program.write().buffer)
          : Runtime.ofProgram(program);
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        throwsA(
          predicate<Object>(
            (error) =>
                error.toString().contains("not a subtype of type 'Match'"),
          ),
        ),
      );
    });
  }
}
