import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  for (final version in ['3.1', '3.8', '3.9']) {
    test(
      'Dart $version preserves Never reachability and non-null interests',
      () {
        final program = Compiler().compile({
          'flow_reachability': {
            'main.dart':
                '''
// @dart = $version
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
class Value {
  Null get value => null;
  int check(int? number) {
    if (number == null) return 0;
    if (value is Never) number = null;
    number.check<Exactly<int>>();
    return number;
  }
}
int checkProperty(Value value, int? number) {
  if (number == null) return 0;
  if (value.value is Never) number = null;
  number.check<Exactly<int>>();
  return number;
}
int main() {
  Object number = 0;
  if (number is int?) {}
  number = 1;
  number.check<Exactly<int>>();
  return number + Value().check(2) + checkProperty(Value(), 3);
}
''',
          },
        });
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          expect(
            runtime.executeLib('package:flow_reachability/main.dart', 'main'),
            6,
          );
        }
      },
    );
  }
}
