import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('guest Stream subclasses work with SDK and guest operators', () async {
    const library = 'package:stream_bridge/main.dart';
    final program = Compiler().compile({
      'stream_bridge': {
        'main.dart': '''
          import 'dart:async';

          class Values extends Stream<int> {
            final Stream<int> source;
            Values(this.source);

            StreamSubscription<int> listen(void Function(int)? onData,
                {Function? onError, void Function()? onDone,
                bool? cancelOnError}) => source.listen(onData,
                  onError: onError, onDone: onDone,
                  cancelOnError: cancelOnError);
          }

          class BroadcastValues extends Values {
            BroadcastValues() : super(Stream<int>.value(7).asBroadcastStream());
            bool get isBroadcast => true;
          }

          Stream<int> values() => Values(Stream<int>.fromIterable([1, 2, 3]));
          Stream<int> broadcast() => BroadcastValues();
          Stream<int> errors() => Values(Stream<int>.error(StateError('guest')));
          bool factoryType() {
            final value = Stream<int>.value(1);
            return value is Stream<int> && value is! Stream<String>;
          }
          bool subclassType() {
            final value = values();
            return value is Stream<int> && value is! Stream<String>;
          }
          Future<int> guestOperators() async {
            final result = await values().where((value) => value > 1)
                .map((value) => value * 2).toList();
            return result[0] + result[1];
          }
        ''',
      },
    });
    for (final (kind, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      final stream = runtime.executeLib(library, 'values') as Stream;
      expect(runtime.executeLib(library, 'factoryType'), isTrue, reason: kind);
      expect(runtime.executeLib(library, 'subclassType'), isTrue, reason: kind);
      expect(stream.isBroadcast, isFalse, reason: kind);
      final events = <Object?>[];
      final done = Completer<void>();
      stream.listen(events.add, onDone: done.complete);
      await done.future;
      expect(events, [1, 2, 3], reason: kind);
      final mapped = (runtime.executeLib(library, 'values') as Stream).map(
        (value) => (value as int) + 10,
      );
      expect(await mapped.toList(), [11, 12, 13], reason: kind);
      expect(
        await runtime.executeLib(library, 'guestOperators'),
        $int(10),
        reason: kind,
      );
      final broadcast = runtime.executeLib(library, 'broadcast') as Stream;
      expect(broadcast.isBroadcast, isTrue, reason: kind);
      expect(await broadcast.toList(), [7], reason: kind);
      final errors = runtime.executeLib(library, 'errors') as Stream;
      final failed = Completer<void>();
      errors.listen(
        null,
        onError: (Object error, StackTrace trace) {
          expect(error, isA<StateError>(), reason: kind);
          failed.complete();
        },
        cancelOnError: true,
      );
      await failed.future;
    }
  });
}
