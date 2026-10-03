import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:test/test.dart';

void main() {
  test('leaf constructors inline without borrowing generic caller state', () {
    final compiler = Compiler();
    final program = compiler.compile({
      'test': {
        'main.dart': '''
          class Row {
            final int first;
            final int second;
            final int third;
            Row(this.first, this.second, this.third);
          }
          int make<T>(int value) {
            final row = Row(value++, value++, value++);
            return row.first * 100 + row.second * 10 + row.third + value;
          }
          int main() => make<String>(2);
        ''',
      },
    });
    final makeId = compiler.functionNames.entries
        .singleWhere((entry) => entry.value.startsWith('make'))
        .key;
    final graph = compiler.functionGraphs[makeId]!;
    expect([
      for (final id in graph.graph.vertices)
        ...graph[id]!.code.whereType<Call>(),
    ], isEmpty);
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:test/main.dart', 'main'), 239);
    }
  });

  test('inlined parameters remain independent and arguments evaluate once', () {
    final compiler = Compiler();
    final program = compiler.compile({
      'test': {
        'main.dart': '''
          int adjust(int first, int second) {
            first += 7;
            second *= 3;
            return first + second;
          }
          int main() {
            var value = 2;
            final first = adjust(value, value);
            final second = adjust(value++, value++);
            return first * 100000 + second * 100 + value;
          }
        ''',
      },
    });
    final mainId = compiler.functionNames.entries
        .singleWhere((entry) => entry.value.startsWith('main'))
        .key;
    final graph = compiler.functionGraphs[mainId]!;
    expect(
      [
        for (final id in graph.graph.vertices)
          ...graph[id]!.code.whereType<Call>(),
      ],
      isEmpty,
      reason: 'The regression must exercise the expanded leaf body.',
    );
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:test/main.dart', 'main'), 1501804);
    }
  });
}
