import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('abstract operators check arguments and noSuchMethod results', () {
    final program = Compiler().compile({
      'operators': {
        'main.dart': r'''
          class Forwarded {
            int calls = 0;
            bool badResult = false;
            int operator >>>(int value);
            dynamic noSuchMethod(Invocation invocation) {
              calls++;
              if (invocation.memberName != #>>>) throw 'wrong invocation';
              return badResult ? 'invalid' : invocation.positionalArguments[0];
            }
          }
          class Base {
            int operator >>>(int value) => value + 1;
          }
          class Inherited extends Base {
            int operator >>>(int value);
            dynamic noSuchMethod(Invocation invocation) => -100;
          }
          bool main() {
            final receiver = Forwarded();
            dynamic dynamicReceiver = receiver;
            if ((dynamicReceiver >>> 7) != 7 || receiver.calls != 1) return false;
            try { dynamicReceiver >>> 'invalid'; return false; } catch (e) {}
            if (receiver.calls != 1) return false;
            receiver.badResult = true;
            try { dynamicReceiver >>> 7; return false; } catch (e) {}
            if (receiver.calls != 2) return false;
            dynamic inherited = Inherited();
            return (inherited >>> 7) == 8;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:operators/main.dart', 'main'), true);
    }
  });
}
