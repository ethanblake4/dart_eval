import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
class Base { late Value<int> field; }
class Child extends Base {}
class Value<T> {}
var receivers = <dynamic>[Child()];
var mapping = <dynamic, dynamic>{'child': Child()};
var members = <dynamic>{Child()};

bool main() {
  mapping[7] = Value<bool>();
  members.add(Value<bool>());
  if (mapping[7] is! Value<bool> || members.length != 2) return false;
  receivers[0].field = Value<int>();
  try {
    receivers[0].field = Value<bool>();
    return false;
  } on TypeError {
    return receivers[0].field is Value<int>;
  }
}
''';

void main() {
  test('dynamic field write checks the runtime field type', () {
    final program = Compiler().compile({
      'dynamic_field_write': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:dynamic_field_write/main.dart', 'main'),
        true,
      );
    }
  });
}
