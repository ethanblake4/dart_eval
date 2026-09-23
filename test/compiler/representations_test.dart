import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/invocation/deferred.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:test/test.dart';

cfg.ControlFlowGraph singleBlock(List<cfg.Operation> operations) {
  final graph = cfg.ControlFlowGraph();
  final root = cfg.BasicBlock<cfg.Operation>(operations);
  graph.append(root);
  graph.root = root;
  graph.insertPhiNodes();
  graph.computeSemiPrunedSSA();
  return graph;
}

cfg.ControlFlowGraph branchGraph({bool mixed = false}) {
  final graph = cfg.ControlFlowGraph();
  final root = cfg.BasicBlock<cfg.Operation>([
    Parameter(
      cfg.SSA('condition'),
      0,
      representation: MachineRepresentation.boolean,
    ),
    JumpIfFalse(cfg.SSA('condition'), 'right'),
  ], label: 'entry');
  final left = cfg.BasicBlock<cfg.Operation>([
    LoadInt(cfg.SSA('value'), 1),
    Jump('join'),
  ], label: 'left');
  final right = cfg.BasicBlock<cfg.Operation>([
    if (mixed)
      LoadDouble(cfg.SSA('value'), 2.5)
    else
      LoadInt(cfg.SSA('value'), 2),
    Jump('join'),
  ], label: 'right');
  final join = cfg.BasicBlock<cfg.Operation>([
    Return(cfg.SSA('value')),
  ], label: 'join');
  graph.append(root);
  graph.root = root;
  graph.link(root, left);
  graph.link(root, right);
  graph.link(left, join);
  graph.link(right, join);
  graph.insertPhiNodes();
  graph.computeSemiPrunedSSA();
  return graph;
}

class UnknownValue extends cfg.Operation {
  UnknownValue(this.target);
  final cfg.SSA target;
  @override
  cfg.SSA get writesTo => target;
  @override
  cfg.Operation copyWith({cfg.SSA? writesTo, Set<cfg.SSA>? readsFrom}) =>
      UnknownValue(writesTo ?? target);
}

void main() {
  test('literal definitions keep all five machine register banks', () {
    final graph = singleBlock([
      LoadInt(cfg.SSA('integer'), 1),
      LoadDouble(cfg.SSA('double'), 2.5),
      LoadBool(cfg.SSA('boolean'), true),
      LoadString(cfg.SSA('string'), 'text'),
      LoadNull(cfg.SSA('object')),
      Return(null),
    ]);
    final representations = analyzeRepresentations(graph);
    expect(
      {
        for (final entry in representations.entries)
          entry.key.name: entry.value,
      },
      {
        'integer': MachineRepresentation.integer,
        'double': MachineRepresentation.doublePrecision,
        'boolean': MachineRepresentation.boolean,
        'string': MachineRepresentation.string,
        'object': MachineRepresentation.object,
      },
    );
  });

  test(
    'boxing and unboxing retain distinct representations of SSA versions',
    () {
      final graph = singleBlock([
        LoadInt(cfg.SSA('value'), 3),
        BoxInt(cfg.SSA('value'), cfg.SSA('value')),
        Unbox(
          cfg.SSA('unboxed'),
          cfg.SSA('value'),
          MachineRepresentation.integer,
        ),
        Return(cfg.SSA('unboxed')),
      ]);
      final representations = analyzeRepresentations(graph);
      final versions =
          representations.entries
              .where((entry) => entry.key.name == 'value')
              .toList()
            ..sort(
              (left, right) => left.key.version.compareTo(right.key.version),
            );
      expect(versions.map((entry) => entry.value), [
        MachineRepresentation.integer,
        MachineRepresentation.object,
      ]);
      expect(
        representations.entries
            .singleWhere((entry) => entry.key.name == 'unboxed')
            .value,
        MachineRepresentation.integer,
      );
    },
  );

  test('phi nodes agree with both incoming integer definitions', () {
    final graph = branchGraph();
    final representations = analyzeRepresentations(graph);
    final phi = graph['join']!.code.whereType<cfg.PhiNode>().single;
    expect(representations[phi.target], MachineRepresentation.integer);
    expect(
      phi.sources.map((source) => representations[source]),
      everyElement(MachineRepresentation.integer),
    );
  });

  test('incompatible phi inputs require an explicit conversion', () {
    expect(
      () => analyzeRepresentations(branchGraph(mixed: true)),
      throwsStateError,
    );
  });

  test('call ABI supplies primitive parameter and result representations', () {
    final graph = singleBlock([
      LoadDouble(cfg.SSA('argument'), 3.5),
      Call(DeferredOrOffset(offset: 7), [
        cfg.SSA('argument'),
      ], result: cfg.SSA('result')),
      Return(cfg.SSA('result')),
    ]);
    final representations = analyzeRepresentations(
      graph,
      functionId: 9,
      functions: {
        7: MachineFunctionSignature([
          MachineRepresentation.doublePrecision,
        ], MachineRepresentation.boolean),
        9: MachineFunctionSignature([], MachineRepresentation.boolean),
      },
    );
    expect(
      representations.entries
          .singleWhere((entry) => entry.key.name == 'argument')
          .value,
      MachineRepresentation.doublePrecision,
    );
    expect(
      representations.entries
          .singleWhere((entry) => entry.key.name == 'result')
          .value,
      MachineRepresentation.boolean,
    );
  });

  test('wrong call representations and unresolved callees are rejected', () {
    final graph = singleBlock([
      LoadBool(cfg.SSA('argument'), true),
      Call(DeferredOrOffset(offset: 7), [
        cfg.SSA('argument'),
      ], result: cfg.SSA('result')),
      Return(cfg.SSA('result')),
    ]);
    expect(() => analyzeRepresentations(graph), throwsStateError);
    expect(
      () => analyzeRepresentations(
        graph,
        functions: {
          7: MachineFunctionSignature([
            MachineRepresentation.integer,
          ], MachineRepresentation.integer),
        },
      ),
      throwsStateError,
    );
  });

  test('unbox output uses typed consumers and never defaults to object', () {
    final graph = singleBlock([
      Parameter(cfg.SSA('boxed'), 0),
      Unbox(cfg.SSA('raw'), cfg.SSA('boxed'), MachineRepresentation.integer),
      LoadInt(cfg.SSA('one'), 1),
      IntAdd(cfg.SSA('sum'), cfg.SSA('raw'), cfg.SSA('one')),
      Return(cfg.SSA('sum')),
    ]);
    final representations = analyzeRepresentations(graph);
    expect(
      representations.entries
          .singleWhere((entry) => entry.key.name == 'raw')
          .value,
      MachineRepresentation.integer,
    );
    final ambiguous = singleBlock([
      Parameter(cfg.SSA('boxed'), 0),
      Unbox(cfg.SSA('raw'), cfg.SSA('boxed'), MachineRepresentation.integer),
      Return(cfg.SSA('raw')),
    ]);
    final explicit = analyzeRepresentations(ambiguous);
    expect(
      explicit.entries.singleWhere((entry) => entry.key.name == 'raw').value,
      MachineRepresentation.integer,
    );
  });

  test('unknown IR definitions are rejected explicitly', () {
    final graph = singleBlock([
      UnknownValue(cfg.SSA('unknown')),
      Return(cfg.SSA('unknown')),
    ]);
    expect(() => analyzeRepresentations(graph), throwsUnsupportedError);
  });

  test(
    'frontend parameters retain declared ABI metadata through SSA conversion',
    () {
      final compiler = Compiler();
      compiler.compile({
        'representation_test': {
          'main.dart':
              'int main(int count, double fraction, bool choose, String text) => count + 1;',
        },
      });
      final id = compiler.functionNames.entries
          .singleWhere((entry) => entry.value.startsWith('main()'))
          .key;
      final raw = compiler.functionGraphs[id]!;
      final parameters = [
        for (final block in raw.graph.vertices)
          ...raw[block]!.code.whereType<Parameter>(),
      ];
      expect(parameters.map((parameter) => parameter.representation), [
        MachineRepresentation.integer,
        MachineRepresentation.doublePrecision,
        MachineRepresentation.boolean,
        MachineRepresentation.object, // String parameters use the boxed ABI.
      ]);
      final ssa = compiler.ssaFunctionGraphs[id]!;
      final representations = analyzeRepresentations(ssa);
      expect(
        representations.entries
            .where((entry) => entry.key.name == 'arg_0')
            .single
            .value,
        MachineRepresentation.integer,
      );
    },
  );
}
