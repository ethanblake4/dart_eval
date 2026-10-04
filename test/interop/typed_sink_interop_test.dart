import 'dart:convert';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop, WrappedException;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/stdlib/convert.dart';
import 'package:test/test.dart';

void main() {
  final program = Compiler().compile({
    'sink_test': {
      'main.dart': r'''
      class Collecting implements Sink<List<int>> {
        List<int>? last;
        int closes = 0;
        void add(List<int> bytes) { last = bytes; }
        void close() { closes++; }
      }
      class Wrong implements Sink<String> {
        void add(String bytes) {}
        void close() {}
      }
      class Erased implements Sink<dynamic> {
        void add(dynamic value) {}
        void close() {}
      }
      class Failing implements Sink<List<int>> {
        void add(List<int> bytes) { throw StateError('add'); }
        void close() { throw StateError('close'); }
      }
      Collecting make() => Collecting();
      Wrong wrong() => Wrong();
      Erased erased() => Erased();
      Failing failing() => Failing();
    ''',
    },
  });

  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('serialized', Runtime(program.write().buffer)),
  ]) {
    runtime.initialize();
    final bytesType = runtime.internParameterizedType(CoreTypes.list, [
      runtime.lookupType(CoreTypes.int),
    ]);
    final sinkType = runtime.internParameterizedType(CoreTypes.sink, [
      bytesType,
    ]);
    Object? guest(String name) =>
        runtime.executeLib('package:sink_test/main.dart', name);

    test('$mode exports guest Sink and preserves collection aliases', () {
      final receiver = guest('make');
      final sink = TypedInterop.exportSink<List<int>>(
        receiver,
        runtime,
        sinkType,
      );
      final bytes = <int>[1, 2];
      sink.add(bytes);
      sink.close();
      sink.close();
      final last = TypedInterop.getProperty(runtime, receiver, 'last');
      expect(
        identical(TypedInterop.exportExternal(last, runtime: runtime), bytes),
        isTrue,
      );
      expect(runtime.isTypedValueType(last, bytesType), isTrue);
      expect(
        TypedInterop.toInt(
          TypedInterop.getProperty(runtime, receiver, 'closes'),
        ),
        2,
      );
      expect(
        () => TypedInterop.exportSink<List<int>>(
          guest('wrong'),
          runtime,
          sinkType,
        ),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => TypedInterop.exportSink<List<int>>(
          guest('erased'),
          runtime,
          sinkType,
        ),
        throwsA(isA<TypeError>()),
      );
    });

    test('$mode sink errors propagate through native interface calls', () {
      final sink = TypedInterop.exportSink<List<int>>(
        guest('failing'),
        runtime,
        sinkType,
      );
      Matcher error(String message) => throwsA(
        predicate<Object>((error) {
          final thrown = error is WrappedException ? error.exception : error;
          final native = TypedInterop.exportExternal(thrown, runtime: runtime);
          return native is StateError && native.message == message;
        }),
      );
      expect(() => sink.add([1]), error('add'));
      expect(sink.close, error('close'));
    });

    test('$mode erased native sink uses its typed guest contract', () {
      final received = <List<dynamic>>[];
      final native = ChunkedConversionSink<dynamic>.withCallback(received.add);
      final wrapper = TypedInterop.annotateBridgeType(
        $ChunkedConversionSink.wrap(native),
        runtime,
        sinkType,
      );
      final sink = TypedInterop.exportSink<List<int>>(
        wrapper,
        runtime,
        sinkType,
      );
      sink.add([3]);
      sink.close();
      expect(received.single.single, [3]);

      final typedNative = ChunkedConversionSink<List<int>>.withCallback((_) {});
      final typedWrapper = TypedInterop.annotateBridgeType(
        $Sink.wrap(typedNative),
        runtime,
        sinkType,
      );
      expect(
        identical(
          TypedInterop.exportSink<List<int>>(typedWrapper, runtime, sinkType),
          typedNative,
        ),
        isTrue,
      );

      final narrowNative = ChunkedConversionSink<String>.withCallback((_) {});
      final narrowWrapper = TypedInterop.annotateBridgeType(
        $Sink.wrap(narrowNative),
        runtime,
        sinkType,
      );
      final narrow = TypedInterop.exportSink<List<int>>(
        narrowWrapper,
        runtime,
        sinkType,
      );
      expect(() => narrow.add([1]), throwsA(isA<TypeError>()));

      final nestedType = runtime.internParameterizedType(CoreTypes.list, [
        bytesType,
      ]);
      final nested =
          TypedInterop.boxExternal(
                <List<int>>[
                  [4],
                ],
                runtime: runtime,
                runtimeTypeId: nestedType,
              )
              as $List;
      expect(runtime.isTypedValueType(nested.$value.single, bytesType), isTrue);
    });
  }
}
