import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  void check<R extends Exactly<T>>() {}
}
class Value<T> {}
T choose<T>(bool flag, T value) {
  if (value is Value<T>?) {
    var result = flag ? value : throw 0;
    result.check<Exactly<T>>();
    return result;
  }
  return value;
}
T narrow<T>(T? value) {
  if (value is int) {
    value.check<Exactly<T>>();
    return value;
  }
  throw 0;
}
int main() => choose<Object?>(true, null) == null ? narrow<int>(1) : 0;
''';

void main() {
  test('nullable promotion bounds preserve the original parameter identity', () {
    final program = Compiler().compile({
      'promoted_parameter': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:promoted_parameter/main.dart', 'main'), 1);
    }
  });
}
