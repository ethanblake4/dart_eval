import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/ir/memory.dart' show IsNull;
import 'package:dart_eval/src/eval/ir/objects.dart' show DynamicEquals;
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:test/test.dart';
import 'compiler_cfg_test.dart' as graph;

void main() {
  for (final source in <String>[
    'int main(bool a, bool b) => a ? (b ? 1 : 2) : (b ? 3 : 4);',
    'bool main(bool a, bool b, bool c) => a && (b || c);',
    'int main(int? a, int? b) => a ?? b ?? 3;',
    'int main(bool a, bool b, int? x) => (a && b) ? (x ?? 1) : (a ? 2 : 3);',
    'List<int> main() => <int>[...?null];',
    'List<int> main(List<int> input, bool a) => [if (a) ...input else ...input];',
    'List<int> main(List<int> input) => [0, ...input, 9];',
    'List<int> main(List<int>? input) => [0, ...?input];',
    'Set<int> main(Set<int> input) => <int>{0, ...input};',
    'Map<String, int> main(Map<String, int> input) => <String, int>{...input};',
    'Map<String, int> main(Map<String, int>? input) => <String, int>{...?input};',
    'Map<String, int> main(Map<String, int> input) => {...input};',
  ]) {
    test('read definitions and SSA conversion: $source', () {
      final result = graph.namedGraph(graph.compileGraph(source), 'main()');
      graph.expectDefinedReads(result);
      result.insertPhiNodes();
      result.computeSemiPrunedSSA();
      expect(result.inSSAForm, isTrue);
      graph.expectDefinedReads(result);
    });
  }
  test('short circuit places RHS call only on the taken branch', () {
    final result = graph.namedGraph(
      graph.compileGraph('''
      bool sideEffect() => true;
      bool main(bool condition) => condition && sideEffect();
    '''),
      'main()',
    );
    final call = graph.operations(result).whereType<Call>().single;
    final callBlock = [
      for (var id = 0; id < result.lastBlockId; id++)
        if (result[id]?.code.contains(call) ?? false) result[id]!,
    ].single;
    bool reaches(int start, int target) {
      final pending = [start];
      final seen = <int>{};
      while (pending.isNotEmpty) {
        final next = pending.removeLast();
        if (next == target) return true;
        if (seen.add(next)) pending.addAll(result.graph.successorsOf(next));
      }
      return false;
    }

    final taken = result.labels.entries
        .singleWhere((entry) => entry.key.startsWith('if_true'))
        .value;
    final skipped = result.labels.entries
        .singleWhere((entry) => entry.key.startsWith('if_false'))
        .value;
    expect(reaches(taken, callBlock.id!), isTrue);
    expect(reaches(skipped, callBlock.id!), isFalse);
    expect(graph.operations(result).whereType<JumpIfFalse>(), hasLength(1));
  });
  test('spreads append inside a loop, null-aware source adds a guard', () {
    final result = graph.namedGraph(
      graph.compileGraph('List<int> main(List<int>? input) => [0, ...?input];'),
      'main()',
    );
    expect(graph.operations(result).whereType<ListAppend>(), hasLength(2));
    expect(graph.operations(result).whereType<JumpIfFalse>(), hasLength(2));
  });
  test('null coalescing tests nullness without dispatching equality', () {
    final result = graph.namedGraph(
      graph.compileGraph('int main(int? value) => value ?? 1;'),
      'main()',
    );
    expect(graph.operations(result).whereType<IsNull>(), hasLength(1));
    expect(graph.operations(result).whereType<DynamicEquals>(), isEmpty);
  });
  test('short circuit rejects non-boolean RHS', () {
    expect(
      () => graph.compileGraph('bool main(bool value) => value && 1;'),
      throwsA(isA<CompileError>()),
    );
  });
  test('spread rejects incompatible element types', () {
    expect(
      () => graph.compileGraph(
        'List<int> main(List<String> values) => <int>[...values];',
      ),
      throwsA(isA<CompileError>()),
    );
  });
}
