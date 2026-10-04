import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

class Chunks extends Stream<List<int>> {
  Chunks(this.source);
  final Stream<List<int>> source;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => source.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

void main() {
  test(
    'chunk export keeps the actual guest list witness and native backing',
    () {
      final program = Compiler().compile({
        'chunk_witness': {
          'main.dart': '''
List<int> bytes() => <int>[0x61];
List<List<int>> nested() => <List<int>>[<int>[0x61]];
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        runtime.initialize();
        final bytesType = runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(CoreTypes.int),
        ]);
        final nestedType = runtime.internParameterizedType(CoreTypes.list, [
          bytesType,
        ]);
        final bytes = TypedInterop.boxExternal(
          runtime.executeLib('package:chunk_witness/main.dart', 'bytes'),
          runtime: runtime,
        );
        expect(runtime.isTypedValueType(bytes, bytesType), isTrue);
        final exported = TypedInterop.exportStreamPayload<List<int>>(
          bytes,
          runtime,
          bytesType,
          (payload) => TypedInterop.exportStreamList<int>(
            payload,
            runtime,
            (element) =>
                TypedInterop.exportExternal(element, runtime: runtime) as int,
          ),
        );
        expect(exported, isA<List<int>>());
        expect(exported, [0x61]);
        final nested = TypedInterop.boxExternal(
          runtime.executeLib('package:chunk_witness/main.dart', 'nested'),
          runtime: runtime,
        );
        expect(runtime.isTypedValueType(nested, nestedType), isTrue);
        expect(
          runtime.isTypedValueType(
            TypedInterop.boxExternal(
              TypedInterop.exportExternal(nested, runtime: runtime),
              runtime: runtime,
            ),
            nestedType,
          ),
          isTrue,
        );
        final nestedExport = TypedInterop.exportStreamPayload<List<List<int>>>(
          nested,
          runtime,
          nestedType,
          (payload) => TypedInterop.exportStreamList<List<int>>(
            payload,
            runtime,
            (element) => TypedInterop.exportStreamList<int>(
              element,
              runtime,
              (byte) =>
                  TypedInterop.exportExternal(byte, runtime: runtime) as int,
            ),
          ),
        );
        expect(nestedExport, [
          [0x61],
        ]);
        nestedExport.single.add(0x62);
        expect(TypedInterop.exportExternal(nested, runtime: runtime), [
          [0x61, 0x62],
        ]);
        final native = Uint8List.fromList([0x61]);
        expect(
          TypedInterop.exportExternal(
            TypedInterop.boxExternal(native, runtime: runtime),
            runtime: runtime,
          ),
          same(native),
        );
        expect(
          TypedInterop.exportStreamList<int>(
            TypedInterop.boxExternal(native, runtime: runtime),
            runtime,
            (element) => element as int,
          ),
          same(native),
        );
        expect(
          () => TypedInterop.exportStreamPayload<List<int>>(
            $List.wrap(<dynamic>[$String('bad')]),
            runtime,
            bytesType,
            (payload) => TypedInterop.exportStreamList<int>(
              payload,
              runtime,
              (element) => element as int,
            ),
          ),
          throwsA(isA<TypeError>()),
        );
      }
    },
  );
  test('UTF8 stream arguments preserve lazy checks and errors', () async {
    const source = r'''
import 'dart:async';
import 'dart:convert';
class Chunks extends Stream<List<int>> {
  final Stream<List<int>> source;
  Chunks(this.source);
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
    source.listen(onData, onError: onError, onDone: onDone,
      cancelOnError: cancelOnError);
}
Future<String> decode(Stream<List<int>> source) => utf8.decodeStream(source);
Chunks make(Stream<List<int>> source) => Chunks(source);
Future<String> wrongGuest() async {
  dynamic wrong = <String>['bad'];
  return decode(Chunks(Stream<List<int>>.fromIterable([wrong])));
}
Future<String> guest(int mode) async {
  final source = mode == 0
    ? Stream<List<int>>.fromIterable(<List<int>>[<int>[0xe2], <int>[0x82, 0xac]])
    : mode == 1 ? Stream<List<int>>.value(<int>[0xff])
    : Stream<List<int>>.error('source-error');
  return decode(Chunks(source));
}
''';
    final program = Compiler().compile({
      'utf8_stream_argument': {'main.dart': source},
    });
    const library = 'package:utf8_stream_argument/main.dart';
    expect(
      await utf8.decodeStream(
        Chunks(
          Stream.fromIterable([
            [0xe2],
            [0x82, 0xac],
          ]),
        ),
      ),
      '\u20ac',
    );
    await expectLater(
      utf8.decodeStream(Chunks(Stream.value([0xff]))),
      throwsFormatException,
    );
    await expectLater(
      utf8.decodeStream(Chunks(Stream.error('source-error'))),
      throwsA('source-error'),
    );
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.initialize();
      final bytesType = runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.int),
      ]);
      final streamType = runtime.internParameterizedType(CoreTypes.stream, [
        bytesType,
      ]);
      $Stream wrap(Stream<Object?> source) =>
          $Stream.wrap(source, runtime: runtime, runtimeTypeId: streamType);

      expect(
        await runtime.executeLib(
          library,
          'guest',
          arguments: {'mode': $int(0)},
        ),
        $String('\u20ac'),
      );
      await expectLater(
        runtime.executeLib(library, 'guest', arguments: {'mode': $int(1)}),
        throwsFormatException,
      );
      await expectLater(
        runtime.executeLib(library, 'guest', arguments: {'mode': $int(2)}),
        throwsA('source-error'),
      );
      await expectLater(
        runtime.executeLib(library, 'wrongGuest'),
        throwsA(isA<TypeError>()),
      );
      final poisoned = $List.wrap(
        <dynamic>[$String('bad')],
        runtime: runtime,
        runtimeTypeId: bytesType,
      );
      final lazy = TypedInterop.exportStreamPayload<List<int>>(
        poisoned,
        runtime,
        bytesType,
        (payload) => TypedInterop.exportStreamList<int>(
          payload,
          runtime,
          (element) =>
              TypedInterop.exportExternal(element, runtime: runtime) as int,
        ),
      );
      expect(() => lazy.single, throwsA(isA<TypeError>()));
      expect(
        await runtime.executeLib(
          library,
          'decode',
          arguments: {
            'source': wrap(
              Chunks(
                Stream.fromIterable(<List<int>>[
                  <int>[0xe2],
                  <int>[0x82, 0xac],
                ]),
              ),
            ),
          },
        ),
        $String('\u20ac'),
      );
      await expectLater(
        runtime.executeLib(
          library,
          'decode',
          arguments: {
            'source': wrap(Chunks(Stream.value(<int>[0xff]))),
          },
        ),
        throwsFormatException,
      );
      final sourceError = StateError('identity');
      final sourceTrace = StackTrace.current;
      final controller = StreamController<List<int>>(onCancel: () {});
      final receiver = TypedInterop.boxExternal(
        runtime.executeLib(
          library,
          'make',
          arguments: {'source': wrap(controller.stream)},
        ),
        runtime: runtime,
      );
      final errors = <Object>[];
      final traces = <StackTrace>[];
      final subscription = TypedInterop.stream(
        receiver,
        runtime,
        exportErrors: true,
      ).listen(
        (_) {},
        onError: (Object error, StackTrace trace) {
          errors.add(error);
          traces.add(trace);
        },
      );
      controller.addError(sourceError, sourceTrace);
      await Future<void>.delayed(Duration.zero);
      expect(errors.single, same(sourceError));
      expect(traces.single, same(sourceTrace));
      await subscription.cancel();
      expect(controller.hasListener, isFalse);
      await controller.close();
      final wrong = wrap(Stream<Object?>.value(<dynamic>[0x61]));
      await expectLater(
        runtime.executeLib(library, 'decode', arguments: {'source': wrong}),
        throwsA(isA<TypeError>()),
      );
      await expectLater(
        runtime.executeLib(
          library,
          'decode',
          arguments: {'source': wrap(Stream<Object?>.value('bad'))},
        ),
        throwsA(isA<TypeError>()),
      );
      await expectLater(
        runtime.executeLib(
          library,
          'decode',
          arguments: {
            'source': wrap(Stream<Object?>.value(<String>['bad'])),
          },
        ),
        throwsA(isA<TypeError>()),
      );
    }
  });
}
