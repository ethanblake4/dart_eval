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
      runtime.registerBridgeFunc(_bridge, 'nativeFailure', (
        runtime,
        target,
        arguments,
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
