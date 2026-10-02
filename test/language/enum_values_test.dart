import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
enum Plain { first, second, third }
enum Generic<T extends num> { first, second }

enum Enhanced {
  first(10), second(20);
  const Enhanced(this.value);
  final int value;
  static List<Enhanced> all() => values;
}

typedef Alias = Plain;

bool main() {
  const all = Plain.values;
  var values = Plain.values;
  if (values.length != 3 ||
      !identical(values, Plain.values) ||
      !identical(values, Alias.values) ||
      !identical(values, all) ||
      !identical(values, const [Plain.first, Plain.second, Plain.third]) ||
      !identical(values[0], Plain.first) ||
      !identical(values[1], Plain.second) ||
      !identical(values[2], Plain.third) ||
      values is! List<Plain> ||
      Generic.values is! List<Generic<num>> ||
      !identical(Enhanced.values, Enhanced.all()) ||
      Enhanced.values[1].value != 20) return false;
  try {
    values.add(Plain.first);
    return false;
  } on UnsupportedError {}
  try {
    values[0] = Plain.third;
    return false;
  } on UnsupportedError {}
  return true;
}
''';

void main() {
  test('enum values preserve order, identity, type and immutability', () {
    final program = Compiler().compile({
      'enum_values': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:enum_values/main.dart', 'main'), true);
    }
  });
}
