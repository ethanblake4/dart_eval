import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;
import 'package:test/test.dart';

const _library = 'package:exceptions/main.dart';
const _bridge = 'package:exceptions/bridge.dart';

Program _compile(String source, {bool nativeFailure = false}) {
  final compiler = Compiler();
  if (nativeFailure) {
    compiler.defineBridgeTopLevelFunction(
      const BridgeFunctionDeclaration(
        _bridge,
        'failFromHost',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        ),
      ),
    );
  }
  return compiler.compile({
    'exceptions': {
      'main.dart': "${nativeFailure ? "import '$_bridge';" : ''}\n$source",
    },
  });
}

Iterable<(String, Runtime)> _runtimes(Program program) sync* {
  yield ('fresh', Runtime.ofProgram(program));
  yield ('serialized', Runtime(program.write().buffer));
}

void main() {
  test('source throws select a typed catch and expose a stack trace', () {
    final program = _compile('''
      class Marker implements Exception {
        final int value;
        Marker(this.value);
      }

      int main() {
        try {
          throw Marker(7);
        } on StateError {
          return -1;
        } on Marker catch (error, stack) {
          return stack.toString().length > 0 ? error.value : -2;
        }
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 7, reason: kind);
    }
  });

  test('native bridge throws use the source handler chain', () {
    final program = _compile('''
        void fail() { failFromHost(); }

        int main() {
          try {
            fail();
          } on FormatException {
            return 1;
          } on StateError catch (error, stack) {
            return error.toString().length + stack.toString().length;
          }
          return -1;
        }
      ''', nativeFailure: true);
    for (final (kind, runtime) in _runtimes(program)) {
      runtime.registerBridgeFunc(_bridge, 'failFromHost', (
        runtime,
        target,
        arguments,
      ) {
        throw StateError('native failure');
      });
      expect(
        runtime.executeLib(_library, 'main'),
        greaterThan('Bad state: native failure'.length),
        reason: kind,
      );
    }
  });

  test('unwinding nested calls and closures preserves captured locals', () {
    final program = _compile('''
      int invoke(Function callback) => callback();

      int main() {
        var value = 3;
        final callback = () {
          value += 4;
          throw 'closure failure';
        };
        try {
          invoke(callback);
        } catch (error) {
          return error.toString().length + value;
        }
        return -1;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 22, reason: kind);
    }
  });

  test('caller handlers survive repeated cached child unwinds', () {
    final program = _compile('''
      int leaf(bool fail) {
        if (fail) throw 'leaf failure';
        return 3;
      }

      int middle(bool fail) {
        var base = 10;
        try {
          return base + leaf(fail);
        } catch (error) {
          return base + 1;
        } finally {
          base += 100;
        }
      }

      int main() {
        var result = 0;
        for (var i = 0; i < 6; i++) {
          result += middle(i % 2 == 0);
        }
        return result;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 72, reason: kind);
    }
  });

  test('recursive frame chains can be reused after an unwind', () {
    final program = _compile('''
      int descend(int depth, bool fail) {
        if (depth == 0) {
          if (fail) throw 'bottom';
          return 1;
        }
        return descend(depth - 1, fail) + 1;
      }

      int main() {
        var result = 0;
        try {
          descend(5, true);
        } catch (error) {
          result = 10;
        }
        return result + descend(5, false);
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 16, reason: kind);
    }
  });

  test('recovery reloads live values from every register bank', () {
    final program = _compile('''
      void fail() { throw 'failure'; }

      double main() {
        var integer = 7;
        var decimal = 1.5;
        var enabled = true;
        var text = 'four';
        try {
          fail();
        } catch (error) {
          return (enabled ? integer + decimal : 0.0) + text.length;
        }
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 12.5, reason: kind);
    }
  });

  test('failed global initializers retry after exception unwinding', () {
    final program = _compile('''
      int attempts = 0;
      int value = initialize();

      int initialize() {
        attempts++;
        if (attempts == 1) throw 'first attempt';
        return 19;
      }

      int main() => value;
      int calls() => attempts;
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(
        () => runtime.executeLib(_library, 'main'),
        throwsA(anything),
        reason: kind,
      );
      expect(runtime.executeLib(_library, 'main'), 19, reason: kind);
      expect(runtime.executeLib(_library, 'calls'), 2, reason: kind);
    }
  });

  test('finally return replaces pending throw and return completions', () {
    final program = _compile('''
      int replaceThrow() {
        try {
          throw 'discarded';
        } finally {
          return 4;
        }
      }

      int replaceReturn() {
        try {
          return 5;
        } finally {
          return 6;
        }
      }

      int main() => replaceThrow() * 10 + replaceReturn();
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 46, reason: kind);
    }
  });

  test('rethrow preserves the thrown object identity', () {
    final program = _compile('''
      Object main(Object token) {
        try {
          try {
            throw token;
          } catch (error) {
            rethrow;
          }
        } catch (error) {
          return error;
        }
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      int token(int value) => value + 1;
      final result = runtime.executeLib(
        _library,
        'main',
        arguments: {'token': token},
      );
      expect(identical(result, token), isTrue, reason: kind);
    }
  });

  test('rethrow ignores writes to the catch parameter', () {
    final program = _compile('''
      String main() {
        try {
          try {
            throw 'original';
          } catch (error) {
            error = 'replacement';
            rethrow;
          }
        } catch (error) {
          return error;
        }
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 'original', reason: kind);
    }
  });

  test('rethrow preserves a native exception instance', () {
    final program = _compile('''
        void main() {
          try {
            failFromHost();
          } catch (error) {
            rethrow;
          }
        }
      ''', nativeFailure: true);
    for (final (kind, runtime) in _runtimes(program)) {
      final failure = StateError('same instance');
      runtime.registerBridgeFunc(_bridge, 'failFromHost', (
        runtime,
        target,
        arguments,
      ) {
        throw failure;
      });
      expect(
        () => runtime.executeLib(_library, 'main'),
        throwsA(
          isA<RuntimeException>().having(
            (error) => identical(error.caughtException, failure),
            'caughtException identity',
            isTrue,
          ),
        ),
        reason: kind,
      );
    }
  });

  test('nested catch restores the exception and trace used by rethrow', () {
    final program = _compile('''
      bool main() {
        StackTrace? originalTrace;
        try {
          try {
            throw 'outer';
          } catch (error, stack) {
            originalTrace = stack;
            try {
              throw 'inner';
            } catch (innerError, innerStack) {
              if (innerError != 'inner') return false;
            }
            rethrow;
          }
        } catch (error, stack) {
          return error == 'outer' && stack == originalTrace;
        }
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), isTrue, reason: kind);
    }
  });

  test('break and continue resume after running finally', () {
    final program = _compile('''
      int main() {
        var result = 0;
        for (var i = 0; i < 4; i++) {
          try {
            if (i == 0) continue;
            if (i == 2) break;
            result += i;
          } finally {
            result += 10;
          }
        }
        return result;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 31, reason: kind);
    }
  });

  test('a conditional try merges its updated local into following code', () {
    final program = _compile('''
      int main(bool run) {
        var value = 1;
        if (run) {
          try {
            value = 4;
          } finally {
            value += 3;
          }
        }
        return value + 5;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(
        runtime.executeLib(_library, 'main', arguments: {'run': false}),
        6,
        reason: kind,
      );
      expect(
        runtime.executeLib(_library, 'main', arguments: {'run': true}),
        12,
        reason: kind,
      );
    }
  });

  test('loop jumps run finally only when they leave its protected body', () {
    final program = _compile('''
      int main() {
        var result = 0;
        for (var i = 0; i < 5; i++) {
          if (i == 0) continue;
          try {
            if (i == 1) continue;
            if (i == 3) break;
            result += i;
          } finally {
            result += 10;
          }
        }
        for (var i = 0; i < 3; i++) {
          if (i == 1) break;
          try {
            result += 100;
          } finally {
            result += 1000;
          }
        }
        return result;
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 1132, reason: kind);
    }
  });

  test(
    'handler sees locals written before throw and retains pending return',
    () {
      final program = _compile('''
      int throwPath() {
        var value = 1;
        try {
          value = 7;
          throw 'failure';
        } catch (error) {
          return value;
        }
      }

      int returnPath() {
        var value = 5;
        try {
          return value;
        } finally {
          value = 9;
        }
      }

      int main() => throwPath() * 10 + returnPath();
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        expect(runtime.executeLib(_library, 'main'), 75, reason: kind);
      }
    },
  );

  test('handled try inside finally does not replace the pending return', () {
    final program = _compile('''
      int main() {
        var value = 1;
        try {
          return value;
        } finally {
          try {
            value = 2;
            throw 'inner';
          } catch (error) {
            value = 3;
          }
        }
      }
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 1, reason: kind);
    }
  });
}
