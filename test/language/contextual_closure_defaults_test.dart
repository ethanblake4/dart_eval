import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
bool main() {
  var explicit = ([List<num> value = const []]) =>
      identical(value, const <num>[]);
  bool Function(List<int>) positional = ([value = const []]) =>
      identical(value, const <int>[]);
  bool Function({required List<int> value}) named =
      ({double extra = 0, value = const []}) =>
          extra == 0.0 && identical(value, const <int>[]);
  double Function(double) numeric = ([value = 0]) => value;
  return explicit() &&
      (positional as bool Function([List<int>]))() &&
      (named as bool Function({double extra, List<int> value}))() &&
      (numeric as double Function([double]))() == 0.0 &&
      (numeric as dynamic)() is double;
}
''';

void main() {
  test('closure defaults retain inferred types and optional calling shape', () {
    final program = Compiler().compile({
      'closure_defaults': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:closure_defaults/main.dart', 'main'),
        true,
      );
    }
  });
}
