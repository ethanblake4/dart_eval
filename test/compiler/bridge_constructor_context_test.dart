import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('reentrant native callbacks retain each constructor payload type', () async {
    final program = Compiler().compile({
      'constructor_context': {
        'main.dart': '''
          Future<bool> main() => Future<bool>.sync(() async {
            var condition = Future.value(true);
            var values = Future.value([1, 2]);
            var entry = Future.value(3);
            final collected = [
              if (await condition) ...await values,
              for (var value in await values) value + await entry,
            ];
            final mapping = {if (await condition) 1: await entry};
            final set = {if (await condition) await entry};
            return collected.length == 4 && collected[0] == 1 &&
                collected[1] == 2 && collected[2] == 4 &&
                collected[3] == 5 && mapping[1] == 3 && set.single == 3;
          });
        ''',
      },
    });
    for (final (mode, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      expect(
        await runtime.executeLib('package:constructor_context/main.dart', 'main'),
        $bool(true),
        reason: mode,
      );
    }
  });
}
