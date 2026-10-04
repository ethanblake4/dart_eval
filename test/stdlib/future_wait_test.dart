import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('Future.wait result keeps the declared widened type argument', () async {
    final program = Compiler().compile({
      'probe': {
        'main.dart': '''
          Future<List<T>> collect<T>() => Future.wait<T>([]);
          Future<bool> main() async {
            final widened = await Future.wait<num>(<Future<int>>[
              Future<int>.value(1),
            ]);
            widened.add(2.5);
            final empty = await Future.wait<num>([]);
            empty.add(2.5);
            final generic = await collect<num>();
            generic.add(2.5);
            dynamic checked = empty;
            try {
              checked.add('wrong element');
              return false;
            } on TypeError {}
            return widened is List<num> && widened[1] == 2.5 &&
                empty is List<num> && empty.single == 2.5 &&
                generic.single == 2.5;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      final result =
          await (runtime.executeLib('package:probe/main.dart', 'main')
                  as Future)
              .timeout(Duration(seconds: 10));
      expect((result as $Value).$value, isTrue);
    }
  });

  test(
    'Future.wait preserves ordered typed results and SDK error cleanup',
    () async {
      final program = Compiler().compile({
        'probe': {
          'main.dart': '''
      class Item { final int value; Item(this.value); }
      Future<int> main() async {
        final values = await Future.wait<Item>([
          Future<Item>.delayed(Duration(milliseconds: 10), () => Item(4)),
          Future<Item>.value(Item(7)),
        ]);
        if (values is! List<Item>) return -1;
        final empty = await Future.wait<int>(<Future<int>>[]);
        if (empty is! List<int> || empty.length != 0) return -2;
        int cleaned = 0;
        try {
          await Future.wait<int>([
            Future<int>.value(3),
            Future<int>.error('failure'),
            Future<int>.delayed(Duration(milliseconds: 1), () => 5),
          ], eagerError: false, cleanUp: (int value) { cleaned += value; });
          return -3;
        } catch (error) {
          if (error != 'failure') return -4;
        }
        bool slowCompleted = false;
        try {
          await Future.wait<int>([
            Future<int>.error('early'),
            Future<int>.delayed(Duration(milliseconds: 20), () {
              slowCompleted = true;
              return 6;
            }),
          ], eagerError: true);
        } catch (error) {
          if (error != 'early' || slowCompleted) return -5;
        }
        await Future.delayed(Duration(milliseconds: 25));
        if (!slowCompleted) return -6;
        await Future.wait<void>([Future<void>.value()]);
        return values[0].value * 100 + values[1].value * 10 + cleaned;
      }
    ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        final result =
            await (runtime.executeLib('package:probe/main.dart', 'main')
                    as Future)
                .timeout(Duration(seconds: 10));
        expect((result as $Value).$value, 478);
      }
    },
  );
}
