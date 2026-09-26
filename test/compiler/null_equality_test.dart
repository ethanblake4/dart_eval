import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:null_equality/main.dart';

void expectResult(String source, Object? expected) {
  final program = Compiler().compile({
    'null_equality': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('literal null equality skips overrides and evaluates both operands', () {
    expectResult('''
      class Spy {
        static int calls = 0;
        bool operator ==(Object other) { calls++; return true; }
        int get hashCode => 0;
      }

      int trace = 0;
      Object? mark(int digit, Object? value) {
        trace = trace * 10 + digit;
        return value;
      }

      int main() {
        final spy = Spy();
        final unknown = mark(1, spy) == mark(2, null);
        final known = mark(3, spy) == null;
        final reversed = null == mark(4, spy);
        final stringNonNull = mark(5, 'text') != null;
        int? number = 7;
        final intNonNull = number != null;
        dynamic loose = spy;
        final dynamicNull = loose == null;
        return trace * 100000 + Spy.calls * 10000 +
            (unknown ? 1 : 0) + (known ? 2 : 0) +
            (reversed ? 4 : 0) + (stringNonNull ? 8 : 0) +
            (intNonNull ? 16 : 0) + (dynamicNull ? 32 : 0);
      }
    ''', 1234500024);
  });
}
