import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('generic transformer preserves nested stream types', () async {
    const library = 'package:transformer/main.dart';
    final program = Compiler().compile({
      'transformer': {
        'main.dart': r'''
import 'dart:async';
class Relay<T> extends StreamTransformerBase<Stream<T>, T> {
  Stream<T> bind(Stream<Stream<T>> streams) => streams.asyncExpand((s) => s);
}
Future<int> relay(Stream<int> Function(int) make) async {
  final streams = Stream<int>.value(7).map(make);
  final Stream<int> result = streams.transform(Relay<int>());
  return await result.first;
}
Future<int> main() => relay((n) => Stream<int>.value(n));
Stream<int> wrong(int n) {
  dynamic stream = Stream<String>.value('wrong');
  return stream;
}
Future<int> guestWrong() => relay(wrong);
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(await runtime.executeLib(library, 'main'), $int(7));
      runtime.prepareTypedRuntime();
      final intStream = runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(CoreTypes.int),
      ]);
      final stringStream = runtime.internParameterizedType(CoreTypes.stream, [
        runtime.lookupType(CoreTypes.string),
      ]);
      expect(
        await runtime.executeLib(
          library,
          'relay',
          arguments: {
            'make': $Function(
              (rt, target, r, s, c) => $Stream.wrap(
                Stream<int>.value((r as $int).$value),
                runtime: rt,
                runtimeTypeId: intStream,
              ),
            ),
          },
        ),
        $int(7),
      );
      await expectLater(
        runtime.executeLib(
          library,
          'relay',
          arguments: {
            'make': $Function(
              (rt, target, r, s, c) => $Stream.wrap(
                Stream<String>.value('wrong'),
                runtime: rt,
                runtimeTypeId: stringStream,
              ),
            ),
          },
        ),
        throwsA(isA<TypeError>()),
      );
      await expectLater(
        runtime.executeLib(library, 'guestWrong'),
        throwsA(isA<TypeError>()),
      );
    }
  });
}
