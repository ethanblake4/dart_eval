import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = '''
class A { int a = 1; }
class D extends A { int d = 7; }
bool accept(A value) => true;
int inspect(A value) {
  int result = 0;
  if (value is D && ((value = D()) != null)) {
    result += value.d;
  }
  if (value is D && (result = value.d) > 0) {
    result += value.d;
    value = A();
  }
  if ((((value) is D) && (result = (value).d) > 0)) {
    result += value.d;
    value = A();
  }
  if (accept(value = A()) && value is D) {
    result += value.d;
  }
  return result;
}
int negate(A value) {
  if (!(value is! D || ((value = D()) == null))) {
    return value.d;
  }
  return 0;
}
int main() => inspect(D()) * 100 + inspect(A()) * 10 + negate(D());
''';

void main() {
  test('successful logical edges retain assignment promotions', () {
    final program = Compiler().compile({
      'logical_and_assignment': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:logical_and_assignment/main.dart', 'main'),
        1407,
      );
    }
  });

  test('a skipped OR assignment does not promote its successful body', () {
    expect(
      () => Compiler().compile({
        'logical_and_assignment': {
          'main.dart': '''
class A {}
class D extends A { int d = 7; }
int inspect(A value, bool skip) {
  if (skip || (value is D && ((value = D()) != null))) {
    return value.d;
  }
  return 0;
}
int main() => inspect(A(), true);
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
