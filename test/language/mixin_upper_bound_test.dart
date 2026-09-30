import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  void check<R extends Exactly<T>>() {}
}
class A {}
mixin M {}
class Alias = A with M;
class B extends Alias {}
class C {}
class D extends C {}
class E extends D {}
class F1 extends B implements E {}
class F2 extends B implements E {}
class Applied extends A with M {}
class B2 extends Applied {}
class F12 extends B2 implements E {}
class F22 extends B2 implements E {}

void checkSingle(bool flag, F1 first, F2 second, F12 third, F22 fourth) {
  (flag ? first : second).check<Exactly<Object>>();
  (flag ? third : fourth).check<Exactly<B2>>();
}

mixin M1 {}
class P1 {}
class P2 extends P1 {}
mixin M2 implements P2 {}
mixin M3 {}
class Multi = A with M1, M2, M3;
class MultiChild extends Multi {}
class D4 extends E {}
class D5 extends D4 {}
class D6 extends D5 {}
class Left extends MultiChild implements D6 {}
class Right extends MultiChild implements D6 {}
void checkMultiple(bool flag, Left left, Right right) {
  (flag ? left : right).check<Exactly<D4>>();
}
int main() {
  checkSingle(true, F1(), F2(), F12(), F22());
  checkSingle(false, F1(), F2(), F12(), F22());
  checkMultiple(true, Left(), Right());
  checkMultiple(false, Left(), Right());
  return 1;
}
''';

void main() {
  test('mixin applications contribute their individual upper-bound depths', () {
    final program = Compiler().compile({
      'mixin_upper_bound': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:mixin_upper_bound/main.dart', 'main'), 1);
    }
  });
}
