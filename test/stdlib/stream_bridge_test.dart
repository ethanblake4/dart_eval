import 'dart:async';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'native stream collection events retain their declared type and backing',
    () async {
      const library = 'package:stream_collections/main.dart';
      final program = Compiler().compile({
        'stream_collections': {
          'main.dart': r'''
import 'dart:async';
Future<List<int>> relay(Stream<List<int>> source) async {
  final controller = StreamController<List<int>>();
  final result = controller.stream.first;
  source.listen(controller.add, onDone: controller.close);
  final event = await result;
  event[0] = event[0] + 1;
  return event;
}
Future<bool> rejectsDynamicList() async {
  final controller = StreamController<List<int>>();
  controller.stream.listen((event) {});
  dynamic widened = controller;
  bool rejected = false;
  try { widened.add(<dynamic>[1, 2]); } on TypeError { rejected = true; }
  await controller.close();
  return rejected;
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        runtime.prepareTypedRuntime();
        final listType = runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(CoreTypes.int),
        ]);
        final streamType = runtime.internParameterizedType(CoreTypes.stream, [
          listType,
        ]);
        for (final event in <List<int>>[
          <int>[1, 2],
          Uint8List.fromList([1, 2]),
        ]) {
          final source = $Stream.wrap(
            Stream<List<int>>.value(event),
            runtime: runtime,
            runtimeTypeId: streamType,
          );
          final result = await runtime.executeLib(
            library,
            'relay',
            arguments: {'source': source},
          );
          expect(
            identical(
              TypedInterop.exportExternal(result, runtime: runtime),
              event,
            ),
            isTrue,
          );
          expect(event, [2, 2]);
        }
        expect(
          await runtime.executeLib(library, 'rejectsDynamicList'),
          $bool(true),
        );
      }
    },
  );

  test('native controllers preserve guest event identity and checks', () async {
    const library = 'package:controller_events/main.dart';
    final program = Compiler().compile({
      'controller_events': {
        'main.dart': r'''
import 'dart:async';
class Token {
  final int value;
  Token(this.value);
}
Future<bool> check(bool sync, bool broadcast) async {
  final controller = broadcast
      ? StreamController<Token>.broadcast(sync: sync)
      : StreamController<Token>(sync: sync);
  final token = Token(7);
  int received = 0;
  int secondReceived = 0;
  bool same = true;
  final subscription = controller.stream.listen((event) {
    received++;
    same = same && identical(event, token) && event.value == 7;
  });
  StreamSubscription<Token>? second;
  if (broadcast) {
    second = controller.stream.listen((event) {
      secondReceived++;
      same = same && identical(event, token);
    });
  }
  controller.add(token);
  if (received != (sync ? 1 : 0)) return false;
  dynamic widened = controller;
  try { widened.add('wrong'); return false; } on TypeError {}
  await controller.close();
  await subscription.cancel();
  if (second != null) await second.cancel();
  return same && received == 1 && secondReceived == (broadcast ? 1 : 0);
}
Future<bool> main() async {
  return await check(false, false) && await check(true, false) &&
      await check(false, true) && await check(true, true);
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(await runtime.executeLib(library, 'main'), $bool(true));
    }
  });

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
