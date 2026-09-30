import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
Type staticType<T>(T value) => T;
class Base<T> {}
class Child<T> extends Base<T> {
  Child(this.value);
  final T value;
  List<T> get values => [value];
}
bool inferred(Base<num> input) {
  switch (input) {
    case Child(values: var values):
      values.check<Exactly<List<num>>>();
      input.check<Exactly<Child<num>>>();
      return true;
    default:
      return false;
  }
}
bool explicit(Base<int> input) {
  switch ((input)) {
    case Child<num>(values: var values):
      values.check<Exactly<List<num>>>();
      input.check<Exactly<Base<int>>>();
      return true;
    default:
      return false;
  }
}
bool later(Object input) {
  switch (input) {
    case String():
      return false;
    case Child<num>():
      input.check<Exactly<Child<num>>>();
      return true;
    default:
      return false;
  }
}
bool changedStatement() {
  Object input = 1;
  switch (input) {
    case int() when (input = 'changed') == 'unused':
      return false;
    case int():
      return staticType(input) == Object && input == 'changed';
    default:
      return false;
  }
}
bool changedExpression() {
  Object input = 1;
  return switch (input) {
    int() when (input = 'changed') == 'unused' => false,
    int() => staticType(input) == Object && input == 'changed',
    _ => false,
  };
}
bool main() => inferred(Child<int>(1)) && explicit(Child<int>(2)) &&
    later(Child<int>(3)) && changedStatement() && changedExpression();
''';

void main() {
  test(
    'pattern cases promote the original subject until a guard writes it',
    () {
      final program = Compiler().compile({
        'pattern_subject': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:pattern_subject/main.dart', 'main'),
          true,
        );
      }
    },
  );
}
