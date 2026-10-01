import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
String typeOf<T>(T value) => '$T';
String main() {
  int? value = 0;
  final map = {?null: (value = null, 1).$2};
  if (map.isNotEmpty || value != 0) throw StateError('absent value executed');
  return typeOf(value);
}
''';

void main() {
  for (final (version, expected) in [('3.8', 'int?'), ('3.9', 'int')]) {
    test('null map keys retain Dart $version flow rules', () {
      final program = Compiler().compile({
        'flow': {'main.dart': '// @dart=$version\n$_source'},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:flow/main.dart', 'main'), expected);
      }
    });
  }
}
