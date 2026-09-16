import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void _check(String source, Object expected) {
  final program = Compiler().compile({
    'scopes': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:scopes/main.dart', 'main'), expected);
  }
}

void main() {
  test('rethrow in inner finally uses its lexical outer catch trace', () {
    const bridgeLibrary = 'package:scopes/bridge.dart';
    final compiler = Compiler();
    compiler.defineBridgeTopLevelFunction(
      const BridgeFunctionDeclaration(
        bridgeLibrary,
        'fail',
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
        ),
      ),
    );
    final program = compiler.compile({
      'scopes': {
        'main.dart':
            '''
        import '$bridgeLibrary';
        bool main() {
          var original = '';
          try {
            try { fail(); }
            catch (outer, outerTrace) {
              original = outerTrace.toString();
              try { fail(); }
              catch (inner) {}
              finally { rethrow; }
            }
          } catch (error, trace) {
            return trace.toString() == original;
          }
          return false;
        }
      ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      var count = 0;
      final shared = $String('same exception');
      runtime.registerBridgeFunc(bridgeLibrary, 'fail', (
        runtime,
        target,
        arguments,
      ) {
        Error.throwWithStackTrace(
          shared,
          StackTrace.fromString(count++ == 0 ? 'outer trace' : 'inner trace'),
        );
      });
      expect(runtime.executeLib('package:scopes/main.dart', 'main'), isTrue);
    }
  });
  test('a throwing assignment retains its previous value in the handler', () {
    _check('''
      int fail() { throw 'failed'; }
      int main() {
        var value = 11;
        var other = 2;
        try {
          other = 7;
          value = fail();
        } catch (error) {
          value += other;
        } finally {
          value += 100;
        }
        return value;
      }
    ''', 118);
  });

  test('nested loop completions reload locals declared inside outer try', () {
    _check('''
      int main() {
        var result = 0;
        try {
          var value = 1;
          for (var i = 0; i < 4; i++) {
            try {
              value += 2;
              if (i == 0) continue;
              if (i == 2) break;
              result += value;
            } finally {
              value += 10;
            }
          }
          result += value;
        } finally {
          result += 100;
        }
        return result;
      }
    ''', 152);
  });

  test('finally break replaces continue after an inner finally', () {
    _check('''
      int main() {
        var result = 0;
        for (var i = 0; i < 3; i++) {
          try {
            try { continue; }
            finally { result += 1; }
          } finally {
            result += 10;
            break;
          }
        }
        return result;
      }
    ''', 11);
  });

  test('typed handler slots preserve independent banks and shadowed names', () {
    _check('''
      int main() {
        var value = 3;
        var fraction = 1.5;
        var enabled = false;
        var text = 'a';
        try {
          value = 9;
          fraction = 2.5;
          enabled = true;
          text = 'abcd';
          {
            var value = 100;
            if (value == 100) throw 'failed';
          }
        } catch (error) {
          if (enabled && fraction == 2.5) value += text.length;
        } finally {
          value += 20;
        }
        return value;
      }
    ''', 33);
  });

  test('closure writes remain visible to catch and finally', () {
    _check('''
      int main() {
        var value = 2;
        final change = () { value = 8; throw 'failed'; };
        try { change(); }
        catch (error) { value += 3; }
        finally { value += 5; }
        return value;
      }
    ''', 16);
  });

  test('unmatched catch executes finally before the outer handler', () {
    _check('''
      int main() {
        var value = 1;
        try {
          try {
            value = 4;
            throw 'failed';
          } on int {
            value = 100;
          } finally {
            value += 3;
          }
        } catch (error) {
          value *= 2;
        }
        return value;
      }
    ''', 14);
  });
}
