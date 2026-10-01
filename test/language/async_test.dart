import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:typed_async/main.dart';
const _bridge = 'package:typed_async/bridge.dart';

Program _compile(String source, {bool nativeFuture = false}) {
  final compiler = Compiler();
  if (nativeFuture) {
    compiler.defineBridgeTopLevelFunction(
      const BridgeFunctionDeclaration(
        _bridge,
        'nativeFailure',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
        ),
      ),
    );
  }
  return compiler.compile({
    'typed_async': {
      'main.dart': "${nativeFuture ? "import '$_bridge';" : ''}\n$source",
    },
  });
}

Iterable<(String, Runtime)> _runtimes(Program program) sync* {
  yield ('fresh', Runtime.ofProgram(program));
  yield ('serialized', Runtime(program.write().buffer));
}

void main() {
  test(
    'Future constructors preserve unions and nested generic payloads',
    () async {
      final program = _compile('''
      import 'dart:async';
      FutureOr<Object> union() async => Future<Object>.value(42);
      Future<T> generic<T>(T value) async => await Future<T>.value(value);
      Future<bool> main() async {
        final inner = Future<int>.value(3);
        final outer = Future<Future<int>>.value(inner);
        final retained = await outer;
        final synchronous = await Future<Future<int>>.sync(() => inner);
        final microtask = await Future<Future<int>>.microtask(() => inner);
        final scheduled = await Future<Future<int>>(() => inner);
        final delayed = await Future<Future<int>>.delayed(Duration.zero, () => inner);
        return await retained == 3 && await Future.value(inner) == 3 &&
            await union() == 42 && await generic<int>(7) == 7 &&
            identical(synchronous, inner) && identical(microtask, inner) &&
            identical(scheduled, inner) && identical(delayed, inner) &&
            await synchronous == 3 && await microtask == 3 &&
            await scheduled == 3 && await delayed == 3;
      }
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        expect(
          await runtime.executeLib(_library, 'main'),
          $bool(true),
          reason: kind,
        );
      }
    },
  );
  test(
    'custom Futures preserve inline values and catchable early errors',
    () async {
      final program = _compile('''
      import 'dart:async';
      class ThrowingFuture implements Future<int> {
        dynamic noSuchMethod(Invocation invocation) { throw 'sentinel'; }
      }
      class InlineFuture implements Future<int> {
        final dynamic value;
        InlineFuture([this.value = 7]);
        dynamic noSuchMethod(Invocation invocation) {
          invocation.positionalArguments[0](value);
          return Future.value(value);
        }
      }
      int stage = 0;
      int readStage() => stage;
      Future<int> inline() async {
        stage = 1;
        var value = await InlineFuture();
        stage = 2;
        return value;
      }
      Future<int> returned() async => ThrowingFuture();
      Future<int> awaited() async => await ThrowingFuture();
      Future<int> wrongInline() async => await InlineFuture('wrong type');
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        for (final function in ['returned', 'awaited']) {
          await expectLater(
            runtime.executeLib(_library, function),
            throwsA(
              predicate<Object>(
                (error) => error is $Value && error.$value == 'sentinel',
              ),
            ),
            reason: '$kind $function',
          );
        }
        final pending = runtime.executeLib(_library, 'inline');
        expect(runtime.executeLib(_library, 'readStage'), 2, reason: kind);
        expect(await pending, $int(7), reason: kind);
        expect(runtime.executeLib(_library, 'readStage'), 2, reason: kind);
        await expectLater(
          runtime.executeLib(_library, 'wrongInline'),
          throwsA(isA<TypeError>()),
          reason: kind,
        );
      }
    },
  );

  test(
    'resumed async errors notify listeners before the next microtask',
    () async {
      final program = _compile('''
      import 'dart:async';
      Future<String> main() async {
        var events = <String>[];
        Future<void> fail() async {
          await null;
          events.add('throw');
          throw 'failure';
        }
        scheduleMicrotask(() => events.add('before'));
        var pending = fail().catchError((error) { events.add('caught'); });
        scheduleMicrotask(() => events.add('after'));
        await pending;
        await Future<void>.delayed(Duration.zero);
        return events.join(',');
      }
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        expect(
          await runtime.executeLib(_library, 'main'),
          $String('before,throw,caught,after'),
          reason: kind,
        );
      }
    },
  );

  test(
    'Future factories and recovery callbacks preserve collection aliases',
    () async {
      final program = _compile('''
      import 'dart:async';
      Future<bool> main() async {
        var source = <int, dynamic>{1: 9};
        source[2] = source;
        var failure = Completer<Map<int, dynamic>>();
        failure.completeError('failure');
        var pending = [
          Future.value(source),
          Future.sync(() => source),
          Future.microtask(() => source),
          Future(() => source),
          Future.delayed(Duration.zero, () => source),
          Future<Map<int, dynamic>>.error('failure').catchError((e) => source),
          failure.future.catchError((e) => source),
          Completer<Map<int, dynamic>>().future.timeout(
            Duration.zero, onTimeout: () => source),
        ];
        for (var future in pending) {
          var value = await future;
          if (!identical(value, source) ||
              !identical(value[2], source) || value[1] != 9) return false;
          value[3] = 11;
          if (source[3] != 11) return false;
        }
        return true;
      }
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        expect(
          await runtime.executeLib(_library, 'main'),
          $bool(true),
          reason: kind,
        );
      }
    },
  );

  test(
    'async result checks deliver failures through the returned Future',
    () async {
      final program = _compile('''
      Future<int> immediate(dynamic value) async => value;
      Future<int> resumed(dynamic value) async {
        await 0;
        return value;
      }
      Future<int> adopted(dynamic value) async => Future.value(value);
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        for (final function in ['immediate', 'resumed', 'adopted']) {
          final future = runtime.executeLib(
            _library,
            function,
            arguments: {'value': 'wrong type'},
          );
          expect(future, isA<Future>(), reason: '$kind $function');
          await expectLater(
            future,
            throwsA(isA<TypeError>()),
            reason: '$kind $function',
          );
        }
      }
    },
  );

  test('async code runs synchronously through its first await', () async {
    final program = _compile('''
      int stage = 0;

      Future<int> start() async {
        stage = 1;
        await 0;
        stage = 2;
        return stage;
      }

      int readStage() => stage;
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      final result = runtime.executeLib(_library, 'start') as Future;
      expect(runtime.executeLib(_library, 'readStage'), 1, reason: kind);
      expect(await result, $int(2), reason: kind);
      expect(runtime.executeLib(_library, 'readStage'), 2, reason: kind);
    }
  });

  test(
    'concurrent suspended invocations keep locals and frames isolated',
    () async {
      final program = _compile('''
      Future<int> calculate(int value) async {
        var local = value + 1;
        await value;
        local = local * 3;
        await 0;
        return local + value;
      }
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        final first =
            runtime.executeLib(_library, 'calculate', arguments: {'value': 2})
                as Future;
        final second =
            runtime.executeLib(_library, 'calculate', arguments: {'value': 7})
                as Future;
        expect(await Future.wait([first, second]), [
          $int(11),
          $int(31),
        ], reason: kind);
      }
    },
  );

  test('one parent can keep overlapping child invocations pending', () async {
    final program = _compile('''
      Future<int> child(int value) async {
        var local = value;
        await 0;
        return local * 2;
      }

      Future<int> parent() async {
        final first = child(3);
        final second = child(8);
        return (await first) + (await second);
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(
        await runtime.executeLib(_library, 'parent'),
        $int(22),
        reason: kind,
      );
    }
  });

  test('await accepts values and composes nested async calls', () async {
    final program = _compile('''
      Future<int> leaf(int value) async {
        final awaited = await value;
        return awaited + 1;
      }

      Future<int> middle(int value) async {
        return (await leaf(value)) * 2;
      }

      Future<int> main() async {
        return await middle(5);
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(
        await runtime.executeLib(_library, 'main'),
        $int(12),
        reason: kind,
      );
    }
  });

  test('captured local mutations survive suspension', () async {
    final program = _compile('''
      Future<int> main() async {
        var value = 3;
        final bump = () async {
          await 0;
          value += 4;
        };
        await bump();
        return value;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(await runtime.executeLib(_library, 'main'), $int(7), reason: kind);
    }
  });

  test('await in finally resumes pending returns and throws', () async {
    final program = _compile('''
      int marker = 0;

      Future<int> pendingReturn() async {
        marker = 0;
        try {
          return 7;
        } finally {
          await 0;
          marker = 3;
        }
      }

      Future<void> pendingThrow() async {
        marker = 0;
        try {
          throw 'original';
        } finally {
          await 0;
          marker = 5;
        }
      }

      Future<int> observeThrow() async {
        try {
          await pendingThrow();
        } catch (error) {
          return marker + (error == 'original' ? 10 : 100);
        }
        return -1;
      }

      int readMarker() => marker;
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(
        await runtime.executeLib(_library, 'pendingReturn'),
        $int(7),
        reason: kind,
      );
      expect(runtime.executeLib(_library, 'readMarker'), 3, reason: kind);
      expect(
        await runtime.executeLib(_library, 'observeThrow'),
        $int(15),
        reason: kind,
      );
    }
  });

  test('source and native Future errors enter await catch handlers', () async {
    final program = _compile('''
      Future<int> sourceFailure() async {
        throw 'source failure';
      }

      Future<int> catchSource() async {
        try {
          await sourceFailure();
        } catch (error) {
          return error == 'source failure' ? 3 : -1;
        }
        return -2;
      }

      Future<int> catchNative() async {
        try {
          await nativeFailure();
        } on StateError catch (error) {
          return error.toString().length > 0 ? 5 : -3;
        }
        return -4;
      }
    ''', nativeFuture: true);
    for (final (kind, runtime) in _runtimes(program)) {
      runtime.registerBridgeFuncRegisters(_bridge, 'nativeFailure', (
        runtime,
        r,
        s,
        c,
      ) {
        return $Future.wrap(Future<int>.error(StateError('native failure')));
      });
      expect(
        await runtime.executeLib(_library, 'catchSource'),
        $int(3),
        reason: kind,
      );
      expect(
        await runtime.executeLib(_library, 'catchNative'),
        $int(5),
        reason: kind,
      );
    }
  });

  test(
    'awaits a typed bridge Future with an erased host type argument',
    () async {
      final compiler = Compiler();
      compiler.defineBridgeTopLevelFunction(
        const BridgeFunctionDeclaration(
          _bridge,
          'nativeText',
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.future, [
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              ]),
            ),
          ),
        ),
      );
      final program = compiler.compile({
        'typed_async': {
          'main.dart':
              '''
          import '$_bridge';
          Future<String> main() async => await nativeText();
          Future<bool> mismatched() async => (await nativeText()) is Future;
        ''',
        },
      });
      for (final (kind, runtime) in _runtimes(program)) {
        var explicitObjectFuture = false;
        runtime.registerBridgeFuncRegisters(_bridge, 'nativeText', (
          runtime,
          r,
          s,
          c,
        ) {
          return $Future.wrap(
            Future<$Value>.value($String('ok')),
            runtime: runtime,
            runtimeTypeId: explicitObjectFuture
                ? runtime.lookupType(CoreTypes.future)
                : null,
          );
        });
        expect(
          await runtime.executeLib(_library, 'main'),
          $String('ok'),
          reason: kind,
        );
        explicitObjectFuture = true;
        expect(
          await runtime.executeLib(_library, 'mismatched'),
          $bool(true),
          reason: kind,
        );
      }
    },
  );

  test('async void and fallthrough complete normally', () async {
    final program = _compile('''
      int marker = 0;

      Future<void> noAwait() async {
        marker = 2;
      }

      Future<void> afterAwait() async {
        await 0;
        marker += 3;
      }

      int readMarker() => marker;
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(
        await runtime.executeLib(_library, 'noAwait'),
        isNull,
        reason: kind,
      );
      expect(runtime.executeLib(_library, 'readMarker'), 2, reason: kind);
      expect(
        await runtime.executeLib(_library, 'afterAwait'),
        isNull,
        reason: kind,
      );
      expect(runtime.executeLib(_library, 'readMarker'), 5, reason: kind);
    }
  });

  test(
    'async returns flatten Futures without implicitly awaiting in try',
    () async {
      final program = _compile('''
      Future<int> value() async {
        await 0;
        return 9;
      }

      Future<int> flattened() async {
        return value();
      }

      Future<int> failure() async {
        await 0;
        throw 'late failure';
      }

      Future<int> passThroughFailure() async {
        try {
          return failure();
        } catch (error) {
          return -1;
        }
      }

      Future<int> callbackFailure() async {
        return value().then((value) {
          throw 'callback failure';
        });
      }
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        expect(
          await runtime.executeLib(_library, 'flattened'),
          $int(9),
          reason: kind,
        );
        await expectLater(
          runtime.executeLib(_library, 'passThroughFailure'),
          throwsA(
            predicate<Object>(
              (error) => error is $Value && error.$value == 'late failure',
              'the original guest error',
            ),
          ),
          reason: kind,
        );
        await expectLater(
          runtime.executeLib(_library, 'callbackFailure'),
          throwsA(
            predicate<Object>(
              (error) => error is $Value && error.$value == 'callback failure',
              'the original guest callback error',
            ),
          ),
          reason: kind,
        );
      }
    },
  );
}
