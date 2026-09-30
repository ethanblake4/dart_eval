import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
int main() {
  int choose(Object? value) {
    final list = [
      if (value case final int value when value > 2) value else 0,
    ];
    final set = <int>{
      if (value case final int value when value > 2) value else 0,
    };
    final map = <int, String>{
      if (value case final int value when value > 2)
        value: 'matched'
      else
        0: 'missed',
    };
    return list.single + set.single + map.keys.single;
  }

  return choose(3) + choose(1) + choose('not an int');
}
''';

void main() {
  test('if-case collection elements match, guard, and shadow the subject', () {
    final program = Compiler().compile({
      'collection_if_case': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:collection_if_case/main.dart', 'main'),
        9,
      );
    }
  });
}

