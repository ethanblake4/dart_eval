import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
class A { int a = 1; }
class B extends A { int b = 2; }
class C extends B { int c = 3; }
class D extends A { int d = 4; }
class E implements C, D {
  int a = 1;
  int b = 2;
  int c = 3;
  int d = 4;
}
int inspect(A value) {
  int result = 0;
  if (value is C && value is B) result += value.c;
  if (value is B && value is C) result += value.c;
  if (value is C && value is D) result += value.c;
  if (value is D && value is C) result += value.d;
  if (value is C) {
    if (value is B) result += value.c;
    if (value is D) result += value.c;
  }
  return result;
}
int main() => inspect(E()) * 100 + inspect(C()) * 10 + inspect(A());
''';

void main() {
  test('conjunction promotions retain the most specific saved local type', () {
    final program = Compiler().compile({
      'conjunction_promotion': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:conjunction_promotion/main.dart', 'main'),
        1990,
      );
    }
  });
}
