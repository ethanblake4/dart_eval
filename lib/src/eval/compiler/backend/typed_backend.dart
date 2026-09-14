import 'dart:typed_data';
import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../../ir/alu.dart' as alu;
import '../../ir/flow.dart' as flow;
import '../../ir/function.dart' as fn;
import '../../ir/logic.dart' as logic;
import '../../ir/memory.dart' as memory;
import '../../ir/operands.dart';
import '../../ir/numeric.dart';
import '../../ir/objects.dart' as objects_ir;
import '../../ir/primitives.dart' as primitives;
import '../../ir/closures.dart' as closures;
import '../../runtime/typed/typed_ops.g.dart';
import '../../runtime/typed/typed_program.dart';
import '../../runtime/typed/typed_function.dart';
import '../context.dart';
import '../offset_tracker.dart';
import 'representation.dart';

/// A fixed-location instruction family before allocation chooses its opcode.
final class TypedOperation extends cfg.Operation {
  TypedOperation(
    this.codes,
    this.result,
    this.inputs, {
    this.immediate,
    this.otherTarget,
    this.terminal = false,
    this.clobbers = const {},
    this.fixedVariant,
  });
  final List<int> codes;
  final cfg.SSA? result;
  final List<cfg.SSA> inputs;
  final int? immediate;
  final int? otherTarget;
  final bool terminal;
  final Set<int> clobbers;
  final cfg.Variant? fixedVariant;
  @override
  cfg.SSA? get writesTo => result;
  @override
  Set<cfg.SSA> get readsFrom => inputs.toSet();
  @override
  List<cfg.SSA> get operands => inputs;
  @override
  bool get isTerminator => terminal;
  @override
  TypedOperation copyWith({cfg.SSA? writesTo, Set<cfg.SSA>? readsFrom}) =>
      copyWithOperands(
        writesTo: writesTo,
        operands: renameOperands(inputs, this.readsFrom, readsFrom),
      );
  @override
  TypedOperation copyWithOperands({
    cfg.SSA? writesTo,
    List<cfg.SSA>? operands,
  }) => TypedOperation(
    codes,
    writesTo ?? result,
    operands ?? inputs,
    immediate: immediate,
    otherTarget: otherTarget,
    terminal: terminal,
    clobbers: clobbers,
    fixedVariant: fixedVariant,
  );
}

final class _Bytes extends cfg.Instruction {
  _Bytes(this.code, [this.immediate, this.otherTarget]);
  int code;
  final int? immediate;
  final int? otherTarget;
  int get length => code < 0
      ? 0
      : TypedOp.instructions[code].length +
            (otherTarget == null
                ? 0
                : TypedOp.instructions[TypedOp.jump].length);
}

/// Lowers an entrypoint to fixed typed registers and byte instructions.
/// Unsupported operations are rejected before a program can execute.
class TypedBackend {
  TypedBackend(this.context);
  final CompilerContext context;
  final integers = <int>[];
  final doubles = <double>[];
  final objects = <Object?>[];

  static final _codes = {
    for (var i = 0; i < TypedOp.instructions.length; i++)
      TypedOp.instructions[i].name: i,
  };
  static const _registerNames = ['a', 'b', 'f', 'g', 'e', 'x', 'r', 's', 'c'];
  static const _banks = [
    [0, 1],
    [2, 3],
    [4, 5],
    [6, 7, 8],
  ];
  List<int> _named(Iterable<String> names) => [
    for (final name in names) _codes[name]!,
  ];

  TypedProgram compile(String library, String function) {
    final libraryId = context.libraryMap[library];
    final id = context.topLevelDeclarationPositions[libraryId]?[function];
    if (id == null)
      throw ArgumentError('Unknown entrypoint $library::$function');
    final reachable = <int>[id];
    for (var next = 0; next < reachable.length; next++) {
      final graph = context.ssaFunctionGraphs[reachable[next]]!;
      for (final block in graph.graph.vertices) {
        for (final op in graph[block]!.code.whereType<flow.Call>()) {
          final callee = _resolveFunction(op.target);
          if (!reachable.contains(callee)) reachable.add(callee);
        }
      }
    }
    final indices = {
      for (var i = 0; i < reachable.length; i++) reachable[i]: i,
    };
    final compiled = [
      for (final functionId in reachable) _compileFunction(functionId, indices),
    ];
    final bytes = BytesBuilder();
    final functions = <TypedFunction>[];
    for (final function in compiled) {
      final base = bytes.length;
      final code = function.code;
      final data = ByteData.sublistView(code);
      for (var pc = 0; pc < code.length;) {
        final instruction = TypedOp.instructions[code[pc]];
        if (instruction.immediate == TypedImmediate.branch) {
          data.setUint32(
            pc + 1,
            data.getUint32(pc + 1, Endian.little) + base,
            Endian.little,
          );
        }
        pc += instruction.length;
      }
      functions.add(
        TypedFunction(
          base,
          intSpillCount: function.spills[0],
          doubleSpillCount: function.spills[1],
          boolSpillCount: function.spills[2],
          objectSpillCount: function.spills[3],
          argumentKinds: function.argumentKinds,
          objectOutgoingCount: function.outgoing,
        ),
      );
      bytes.add(code);
    }
    return TypedProgram(
      bytes.takeBytes(),
      integers: integers,
      doubles: doubles,
      objects: objects,
      functions: functions,
    );
  }

  int _resolveFunction(DeferredOrOffset target) {
    final id =
        target.offset ??
        context.topLevelDeclarationPositions[target.file]?[target.name];
    if (id == null || !context.ssaFunctionGraphs.containsKey(id)) {
      throw UnsupportedError('Typed direct-call target $target');
    }
    return id;
  }

  _FunctionCode _compileFunction(int id, Map<int, int> functionIndices) {
    final spillCounts = [0, 0, 0, 0];
    var outgoingCount = 0;
    var methodCounter = 0;
    final sourceGraph = context.ssaFunctionGraphs[id]!;
    final representations = analyzeRepresentations(
      sourceGraph,
      functions: context.functionSignatures,
      functionId: id,
      resolveFunction: _resolveFunction,
    );
    final graph = sourceGraph.clone();
    cfg.SSA value(cfg.SSA input) {
      final representation = representations[input];
      if (representation == null) {
        throw UnsupportedError(
          'Typed register representation for $input: $representation',
        );
      }
      return cfg.SSA(
        input.name,
        version: input.version,
        type: representation.index < 3 ? representation.index : 3,
      );
    }

    final signature = context.functionSignatures[id]!;
    final argumentKinds = [
      for (final representation in signature.parameters)
        TypedArgumentKind.values[representation.index],
    ];
    final layout = TypedCallLayout(argumentKinds);
    var temporaryCounter = 0;
    cfg.SSA temporary(String name) =>
        cfg.SSA('typed:$name${temporaryCounter++}', version: 0, type: 3);
    final overflowInput = layout.overflowCount == 0
        ? null
        : temporary('overflow');
    final parameterInputs = <int, cfg.SSA>{};
    for (final blockId in graph.graph.vertices.toList()) {
      final block = graph[blockId]!;
      final lowered = <cfg.Operation>[];
      final parameters = block.code.whereType<fn.Parameter>().toList();
      if (parameters.any(
        (op) => layout.arguments[op.index].overflowIndex != null,
      )) {
        lowered.add(cfg.RegisterInput(overflowInput!, 8));
      }
      for (final op in parameters) {
        final location = layout.arguments[op.index];
        if (location.overflowIndex != null) continue;
        final target = value(op.target);
        final input = location.bank.index == target.type
            ? target
            : temporary('parameter');
        parameterInputs[op.index] = input;
        lowered.add(
          cfg.RegisterInput(input, _banks[location.bank.index][location.index]),
        );
      }
      for (final op in block.code) {
        if (op is cfg.PhiNode) {
          lowered.add(
            cfg.PhiNode(
              value(op.target),
              op.sources.map(value).toSet(),
              incoming: op.incoming.map(
                (edge, source) => MapEntry(edge, value(source)),
              ),
            ),
          );
          continue;
        }
        if (op is closures.InvokeClosure || op is objects_ir.InvokeDynamic) {
          final (receiver, arguments) = switch (op) {
            closures.InvokeClosure(
              :final closure,
              :final positional,
              :final named,
            )
                when named.isEmpty =>
              (closure, positional),
            objects_ir.InvokeDynamic(:final object, :final args) => (
              object,
              args,
            ),
            _ => throw UnsupportedError(
              'Typed host calls require positional arguments',
            ),
          };
          for (var index = 0; index < arguments.length; index++) {
            final argument = value(arguments[index]);
            if (argument.type != 3) {
              throw StateError(
                'Host call argument requires object representation',
              );
            }
            lowered.add(
              TypedOperation(
                _named(['rOutgoing', 'sOutgoing', 'cOutgoing']),
                null,
                [argument],
                immediate: index,
              ),
            );
          }
          if (arguments.length > outgoingCount)
            outgoingCount = arguments.length;
          final method = op is objects_ir.InvokeDynamic && op.name != 'call'
              ? cfg.SSA('typed:method${methodCounter++}', version: 0, type: 3)
              : null;
          if (method != null) {
            lowered.add(
              TypedOperation(
                _named(['rConstant', 'sConstant', 'cConstant']),
                method,
                [],
                immediate: _object((op as objects_ir.InvokeDynamic).name),
              ),
            );
          }
          lowered.add(
            TypedOperation(
              _named([method == null ? 'callHost' : 'callMethod']),
              value(op.writesTo!),
              [value(receiver), if (method != null) method],
              immediate: arguments.length,
              clobbers: {0, 1, 2, 3, 4, 5, 6, 7, 8},
            ),
          );
          continue;
        }
        if (op is flow.Call) {
          final callee = _resolveFunction(op.target);
          final callLayout = TypedCallLayout([
            for (final representation
                in context.functionSignatures[callee]!.parameters)
              TypedArgumentKind.values[representation.index],
          ]);
          final registerArguments = <cfg.SSA>[];
          final argumentRegisters = <int>[];
          for (var index = 0; index < op.arguments.length; index++) {
            var input = value(op.arguments[index]);
            final location = callLayout.arguments[index];
            if (location.bank == TypedRegisterBank.object && input.type != 3) {
              final native = temporary('native');
              lowered.add(
                TypedOperation(
                  _named([
                    for (final register in _banks[input.type])
                      'rFrom${_registerNames[register].toUpperCase()}',
                  ]),
                  native,
                  [input],
                ),
              );
              input = native;
            }
            if (location.overflowIndex == null) {
              registerArguments.add(input);
              argumentRegisters.add(
                _banks[location.bank.index][location.index],
              );
            } else {
              lowered.add(
                TypedOperation(
                  _named(['rOutgoing', 'sOutgoing', 'cOutgoing']),
                  null,
                  [input],
                  immediate: location.overflowIndex,
                ),
              );
            }
          }
          if (callLayout.overflowCount > 0) {
            final list = temporary('outgoing');
            lowered.add(TypedOperation(_named(['cLoadOutgoing']), list, []));
            registerArguments.add(list);
            argumentRegisters.add(8);
          }
          if (callLayout.overflowCount > outgoingCount) {
            outgoingCount = callLayout.overflowCount;
          }
          final result = value(op.writesTo!);
          lowered.add(
            TypedOperation(
              _named(['call']),
              result,
              registerArguments,
              fixedVariant: cfg.Variant(
                result: _banks[result.type].first,
                arguments: argumentRegisters,
              ),
              immediate: functionIndices[_resolveFunction(op.target)],
              clobbers: {0, 1, 2, 3, 4, 5, 6, 7, 8},
            ),
          );
          continue;
        }
        if (op is fn.Parameter) {
          final target = value(op.target);
          final location = layout.arguments[op.index];
          var input = parameterInputs[op.index];
          if (location.overflowIndex != null) {
            input = target.type == 3 ? target : temporary('parameter');
            lowered.add(
              TypedOperation(_named(['rOverflow']), input, [
                overflowInput!,
              ], immediate: location.overflowIndex),
            );
          }
          if (location.bank.index != target.type) {
            lowered.add(
              TypedOperation(
                _named([
                  ['aNativeFromR', 'fNativeFromR', 'eNativeFromR'][target.type],
                ]),
                target,
                [input!],
              ),
            );
          }
          continue;
        }
        TypedOperation make(
          List<String> names,
          List<cfg.SSA> inputs, {
          int? immediate,
          bool terminal = false,
          int? otherTarget,
        }) => TypedOperation(
          _named(names),
          op.writesTo == null || op.writesTo!.name == '@branch'
              ? null
              : value(op.writesTo!),
          inputs.map(value).toList(),
          immediate: immediate,
          terminal: terminal,
          otherTarget: otherTarget,
        );
        List<String> bankNames(cfg.SSA source, String suffix) => [
          for (final r in _banks[value(source).type])
            '${_registerNames[r]}$suffix',
        ];
        List<String> compareNames(String condition) => [
          for (final flag in ['e', 'x'])
            for (final order in ['AB']) '$flag$condition$order',
        ];
        lowered.add(switch (op) {
          NumericBinary(
            :final left,
            :final right,
            :final operandRepresentation,
            :final operator,
          ) =>
            make(_numericNames(operandRepresentation, operator), [left, right]),
          memory.LoadInt(:final value) when value >= -32768 && value <= 32767 =>
            make(['aImmediate', 'bImmediate'], [], immediate: value & 65535),
          memory.LoadInt(:final value) => make(
            ['aConstant', 'bConstant'],
            [],
            immediate: _integer(value),
          ),
          memory.LoadDouble(:final value) => make(
            ['fConstant', 'gConstant'],
            [],
            immediate: _double(value),
          ),
          memory.LoadBool(:final value) => make(
            value ? ['eTrue', 'xTrue'] : ['eFalse', 'xFalse'],
            [],
          ),
          memory.LoadString(:final value) => make(
            ['rConstant', 'sConstant', 'cConstant'],
            [],
            immediate: _object(value),
          ),
          memory.LoadNull() ||
          primitives.BoxNull() => make(['rNull', 'sNull', 'cNull'], []),
          primitives.BoxString(:final source) => make(['rBoxString'], [source]),
          primitives.MaybeBoxNull(:final target, :final source) => cfg.Assign(
            value(target),
            value(source),
          ),
          primitives.BoxInt(:final source) ||
          primitives.BoxDouble(:final source) ||
          primitives.BoxBool(:final source) ||
          primitives.BoxNum(:final source) => make(
            [
              for (final target in ['r'])
                for (final r in _banks[value(source).type])
                  '${target}Box${_registerNames[r].toUpperCase()}',
            ],
            [source],
          ),
          primitives.Unbox(:final target, :final source) =>
            representations[target] == MachineRepresentation.string
                ? make(['rUnboxString'], [source])
                : value(target).type == 3
                ? cfg.Assign(value(target), value(source))
                : make(
                    [
                      ['aFromR', 'fFromR', 'eFromR'][value(target).type],
                    ],
                    [source],
                  ),
          objects_ir.DynamicEquals(:final left, :final right) => make(
            [
              for (final flag in ['e', 'x'])
                for (final order in ['RS']) '${flag}Eq$order',
            ],
            [left, right],
          ),
          memory.IsNull(:final object) => make(
            [
              for (final flag in ['e', 'x'])
                for (final r in ['R', 'S', 'C']) '${flag}IsNull$r',
            ],
            [object],
          ),
          cfg.Assign(:final target, :final source) => cfg.Assign(
            value(target),
            value(source),
          ),
          memory.Assign(:final target, :final source) => cfg.Assign(
            value(target),
            value(source),
          ),
          alu.IntAdd(:final left, :final right) => make(
            ['aAddB', 'bAddA'],
            [left, right],
          ),
          alu.IntSub(:final left, :final right) => make(
            ['aSubB', 'bSubA'],
            [left, right],
          ),
          alu.IntLessThan(:final left, :final right) => make(
            compareNames('Lt'),
            [left, right],
          ),
          alu.IntLessThanOrEqual(:final left, :final right) => make(
            compareNames('Lte'),
            [left, right],
          ),
          alu.IntGreaterThan(:final left, :final right) => make(
            compareNames('Gt'),
            [left, right],
          ),
          alu.IntGreaterThanOrEqual(:final left, :final right) => make(
            compareNames('Gte'),
            [left, right],
          ),
          alu.IntEqual(:final left, :final right) => make(compareNames('Eq'), [
            left,
            right,
          ]),
          alu.IntNotEqual(:final left, :final right) => make(
            compareNames('Ne'),
            [left, right],
          ),
          alu.Increment(:final source) => make(
            ['aIncrement', 'bIncrement'],
            [source],
          ),
          logic.LogicalNot(:final source) => make(['eNot', 'xNot'], [source]),
          flow.Return(:final value) when value != null => make(
            bankNames(value, 'Return'),
            [value],
            terminal: true,
          ),
          flow.Jump(:final target) => make(
            ['jump'],
            [],
            immediate: graph[target]!.id!,
            terminal: true,
          ),
          flow.JumpIfFalse(:final condition, :final target) => make(
            ['jumpEFalse', 'jumpXFalse'],
            [condition],
            immediate: graph[target]!.id!,
            terminal: true,
            otherTarget: graph.graph
                .successorsOf(blockId)
                .singleWhere((s) => s != graph[target]!.id),
          ),
          _ => throw UnsupportedError(
            'Typed backend does not yet lower ${op.runtimeType}: $op',
          ),
        });
      }
      block.code
        ..clear()
        ..addAll(lowered);
    }
    for (var bank = 0; bank < 4; bank++) {
      graph.registerRegType(
        bank,
        cfg.RegType(bank, 'bank$bank', {
          cfg.RegisterGroup(_banks[bank].toSet()),
        }),
      );
    }
    graph.opCreators[TypedOperation] = cfg.Creator<TypedOperation, void>(
      variants: {},
      selectClobbers: (op) => op.clobbers,
      selectVariants: (op) => op.fixedVariant == null
          ? {
              for (final code in op.codes)
                cfg.Variant(
                  result: TypedOp.instructions[code].outputs.firstOrNull,
                  arguments: TypedOp.instructions[code].inputs,
                ),
            }
          : {op.fixedVariant!},
      create: (op, _) {
        if (op.fixedVariant != null) {
          return _Bytes(op.codes.single, op.immediate);
        }
        final code = op.codes.firstWhere((code) {
          final spec = TypedOp.instructions[code];
          return spec.outputs.firstOrNull == op.result?.alloc.register &&
              spec.inputs.length == op.inputs.length &&
              Iterable<int>.generate(
                op.inputs.length,
              ).every((i) => spec.inputs[i] == op.inputs[i].alloc.register);
        }, orElse: () => throw StateError('No opcode matches allocated $op'));
        return _Bytes(code, op.immediate, op.otherTarget);
      },
    );
    graph.refreshSSA();
    graph.removePhiNodes(
      cfg.Assign.new,
      onSplitEdge: (pred, old, replacement) {
        final code = graph[pred]!.code;
        for (var i = 0; i < code.length; i++) {
          final op = code[i];
          if (op is TypedOperation && op.terminal) {
            code[i] = TypedOperation(
              op.codes,
              op.result,
              op.inputs,
              immediate: op.immediate == old ? replacement : op.immediate,
              otherTarget: op.otherTarget == old ? replacement : op.otherTarget,
              terminal: true,
            );
          }
        }
      },
    );
    graph.performRegisterAllocation();
    _Bytes spill(cfg.AllocatedSSA variable, int slot, bool reload) {
      if (slot + 1 > spillCounts[variable.type])
        spillCounts[variable.type] = slot + 1;
      return _Bytes(
        _codes['${_registerNames[variable.register]}${reload ? 'Reload' : 'Spill'}']!,
        slot,
      );
    }

    final blocks = graph.assembleToInstructions(
      cfg.AssemblerConfig<void>(
        contextData: null,
        onSpill: (v, slot, _) => spill(v, slot, false),
        onReload: (v, slot, _) => spill(v, slot, true),
        onMove: (target, source, _) => target.register == source.register
            ? _Bytes(-1)
            : _Bytes(
                _codes['${_registerNames[target.register]}From${_registerNames[source.register].toUpperCase()}']!,
              ),
        onSwap: (a, b, _) {
          final regs = [a.register, b.register]..sort();
          return _Bytes(
            _codes['${_registerNames[regs[0]]}${_registerNames[regs[1]].toUpperCase()}Swap']!,
          );
        },
        onJump: (target, _) => _Bytes(TypedOp.jump, target),
      ),
    );
    // Expand the second edge before relaxation so both branch distances use
    // the final instruction positions. Every branch starts short and can only
    // widen, guaranteeing that this layout process terminates.
    final assembled = {
      for (final block in blocks.entries)
        block.key: <_Bytes>[
          for (final instruction in block.value.cast<_Bytes>()) ...[
            if (instruction.code >= 0)
              _Bytes(instruction.code, instruction.immediate),
            if (instruction.otherTarget != null)
              _Bytes(TypedOp.jump, instruction.otherTarget),
          ],
        ],
    };
    final shortToLong = <int, int>{};
    for (final block in assembled.values) {
      for (final instruction in block) {
        final spec = TypedOp.instructions[instruction.code];
        if (spec.immediate == TypedImmediate.branch) {
          final short = _codes['${spec.name}Short']!;
          shortToLong[short] = instruction.code;
          instruction.code = short;
        }
      }
    }
    final offsets = <int, int>{};
    bool widened;
    do {
      var offset = 0;
      for (final block in assembled.entries) {
        offsets[block.key] = offset;
        for (final instruction in block.value) {
          offset += instruction.length;
        }
      }
      widened = false;
      offset = 0;
      for (final block in assembled.values) {
        for (final instruction in block) {
          final length = instruction.length;
          final long = shortToLong[instruction.code];
          if (long != null) {
            final distance =
                offsets[instruction.immediate]! - (offset + length);
            if (distance < -32768 || distance > 32767) {
              instruction.code = long;
              widened = true;
            }
          }
          // All positions in this pass refer to the same layout. Widening is
          // reflected when offsets are recomputed on the next pass.
          offset += length;
        }
      }
    } while (widened);
    final bytes = BytesBuilder();
    for (final block in assembled.values) {
      for (final instruction in block) {
        final code = instruction.code;
        final spec = TypedOp.instructions[code];
        final end = bytes.length + spec.length;
        bytes.addByte(code);
        if (spec.immediate == TypedImmediate.none) continue;
        final number = switch (spec.immediate) {
          TypedImmediate.branch => offsets[instruction.immediate]!,
          TypedImmediate.shortBranch => offsets[instruction.immediate]! - end,
          _ => instruction.immediate!,
        };
        if (spec.immediate == TypedImmediate.shortBranch) {
          if (number < -32768 || number > 32767) {
            throw StateError('Short branch exceeds encoding: $number');
          }
        } else if (number < 0 || (spec.length == 3 && number > 65535)) {
          throw UnsupportedError('Typed immediate exceeds encoding: $number');
        }
        for (var byte = 0; byte < spec.length - 1; byte++) {
          bytes.addByte((number >> (byte * 8)) & 255);
        }
      }
    }
    return _FunctionCode(
      bytes.takeBytes(),
      spillCounts,
      argumentKinds,
      outgoingCount,
    );
  }

  int _object(Object? value) {
    final old = objects.indexOf(value);
    if (old >= 0) return old;
    objects.add(value);
    return objects.length - 1;
  }

  int _integer(int value) {
    final old = integers.indexOf(value);
    if (old >= 0) return old;
    integers.add(value);
    return integers.length - 1;
  }

  List<String> _numericNames(
    MachineRepresentation representation,
    NumericOperator operator,
  ) {
    final integer = representation == MachineRepresentation.integer;
    final comparison = switch (operator) {
      NumericOperator.lessThan => 'Lt',
      NumericOperator.lessThanOrEqual => 'Lte',
      NumericOperator.greaterThan => 'Gt',
      NumericOperator.greaterThanOrEqual => 'Gte',
      NumericOperator.equal => 'Eq',
      NumericOperator.notEqual => 'Ne',
      _ => null,
    };
    if (comparison != null) {
      return [
        for (final flag in ['e', 'x'])
          for (final order in integer ? ['AB'] : ['FG'])
            '$flag$comparison$order',
      ];
    }
    final name = switch (operator) {
      NumericOperator.add => 'Add',
      NumericOperator.subtract => 'Sub',
      NumericOperator.multiply => 'Mul',
      NumericOperator.divide when !integer => 'Div',
      NumericOperator.truncatingDivide when integer => 'Div',
      NumericOperator.modulo when integer => 'Mod',
      _ => throw UnsupportedError(
        'Typed numeric operation $representation $operator',
      ),
    };
    return integer ? ['a${name}B', 'b${name}A'] : ['f${name}G', 'g${name}F'];
  }

  int _double(double value) {
    // Keep bit-distinct constants such as -0.0 separate.
    doubles.add(value);
    return doubles.length - 1;
  }
}

class _FunctionCode {
  _FunctionCode(this.code, this.spills, this.argumentKinds, this.outgoing);
  final Uint8List code;
  final List<int> spills;
  final List<TypedArgumentKind> argumentKinds;
  final int outgoing;
}
