import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('Function.apply preserves named arguments of bound methods', () {
    final program = Compiler().compile({
      'bound_apply': {
        'main.dart': '''
          class C {
            final int offset;
            C(this.offset);
            int method(int first, {int last = 3, int middle = 2}) =>
                offset + first * 100 + middle * 10 + last;
          }
          int main() {
            final method = C(1000).method;
            return Function.apply(method, [4], {#last: 6, #middle: 5}) +
                Function.apply(method, [7]);
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:bound_apply/main.dart', 'main'), 3179);
    }
  });
}
