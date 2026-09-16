import '../../ir/string.dart';
import '../../ir/collection.dart' as collection;
import 'dart:typed_data';
import 'package:control_flow_graph/control_flow_graph.dart' as cfg;
import '../../ir/alu.dart' as alu;
import '../../ir/bridge.dart' as bridge;
import '../../ir/flow.dart' as flow;
import '../../ir/function.dart' as fn;
import '../../ir/logic.dart' as logic;
import '../../ir/memory.dart' as memory;
import '../../ir/operands.dart';
import '../../ir/numeric.dart';
import '../../ir/objects.dart' as objects_ir;
import '../../ir/primitives.dart' as primitives;
import '../../ir/closures.dart' as closures;
import '../../ir/globals.dart' as globals;
import '../../runtime/typed/typed_ops.g.dart';
import '../../runtime/typed/typed_program.dart';
import '../../runtime/typed/typed_function.dart';
import '../../runtime/typed/typed_class.dart';
import '../../runtime/typed/typed_call_site.dart';
import '../../runtime/typed/typed_external_call.dart';
import '../../runtime/typed/typed_closure_descriptor.dart';
import '../../runtime/typed/typed_export.dart';
import '../../runtime/typed/typed_global.dart';
import 'package:analyzer/dart/ast/ast.dart';
import '../helpers/default_value.dart';
import '../helpers/fpl.dart';
import '../type.dart';
import '../builtins.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
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
  final _classIndices = <(int, String), int>{};
  final _callSites = <TypedCallSite>[];
  final _closures = <TypedClosureDescriptor>[];
  final _closureCalls = <TypedClosureCall>[];
  final _externalCalls = <TypedExternalCall>[];
  Map<int, int> functionIndices = {};

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
    return compileEntrypoints([(library, function)]);
  }

  TypedProgram compileEntrypoints(Iterable<(String, String)> entrypoints) {
    final roots = entrypoints.toList();
    final reachable = <int>[];
    for (final (library, function) in roots) {
      final libraryId = context.libraryMap[library];
      final id = context.topLevelDeclarationPositions[libraryId]?[function];
      if (id == null) {
        throw ArgumentError('Unknown entrypoint $library::$function');
      }
      if (!reachable.contains(id)) reachable.add(id);
    }
    if (reachable.isEmpty) {
      throw ArgumentError('No typed entrypoints were found');
    }
    final classAllocations = <objects_ir.CreateClass>[];
    final reachableGlobals = <int>{};
    for (var next = 0; next < reachable.length; next++) {
      final graph = context.ssaFunctionGraphs[reachable[next]]!;
      for (final block in graph.graph.vertices) {
        for (final op in graph[block]!.code) {
          if (op is flow.Call || op is closures.CreateClosure) {
            final callee = _resolveFunction(switch (op) {
              flow.Call(:final target) => target,
              closures.CreateClosure(:final target) => target,
              _ => throw StateError('Unreachable callable'),
            });
            if (!reachable.contains(callee)) reachable.add(callee);
          } else if (op is globals.LoadGlobal || op is globals.SetGlobal) {
            final index = switch (op) {
              globals.LoadGlobal(:final index) => index,
              globals.SetGlobal(:final index) => index,
              _ => throw StateError('Unreachable global operation'),
            };
            final initializer = context.runtimeGlobalInitializerMap[index];
            reachableGlobals.add(index);
            if (initializer != null && !reachable.contains(initializer)) {
              reachable.add(initializer);
            }
          } else if (op is objects_ir.CreateClass) {
            final key = (op.library, op.name);
            if (_classIndices.containsKey(key)) continue;
            _classIndices[key] = classAllocations.length;
            classAllocations.add(op);
            final members =
                context.instanceDeclarationPositions[op.library]![op.name]!;
            for (var kind = 0; kind < 3; kind++) {
              for (final target in (members[kind] as Map).values.cast<int>()) {
                if (target >= 0 && !reachable.contains(target)) {
                  reachable.add(target);
                }
              }
            }
          }
        }
      }
    }
    final indices = {
      for (var i = 0; i < reachable.length; i++) reachable[i]: i,
    };
    functionIndices = indices;
    final libraries = {
      for (final entry in context.libraryMap.entries) entry.value: entry.key,
    };
    final classes = <TypedClass>[
      for (final allocation in classAllocations)
        TypedClass(
          allocation.name,
          library: libraries[allocation.library]!,
          valueCount: allocation.valuesLength,
          getters: _classMembers(allocation, 0, indices),
          setters: _classMembers(allocation, 1, indices),
          methods: _classMembers(allocation, 2, indices),
        ),
    ];
    final compiled = [
      for (final functionId in reachable) _compileFunction(functionId, indices),
    ];
    for (final allocation in classAllocations) {
      final members =
          context.instanceDeclarationPositions[allocation.library]![allocation
                  .name]![2]
              as Map;
      for (final id in members.values.cast<int>()) {
        if (id < 0 ||
            _closures.any(
              (d) => d.functionId == indices[id] && d.boundReceiver,
            ))
          continue;
        final parameters =
            context.functionParameters[id] ?? const <FormalParameter>[];
        final positional = parameters.where((p) => p.isPositional).toList();
        final named = parameters.where((p) => p.isNamed).toList();
        Object? defaultValue(FormalParameter p) {
          final value = evaluateDefaultValue(
            context,
            allocation.library,
            p is DefaultFormalParameter ? p.defaultValue : null,
          );
          final normal = p is DefaultFormalParameter ? p.parameter : p;
          final annotation = normal is SimpleFormalParameter
              ? normal.type
              : null;
          return value is int &&
                  annotation is NamedType &&
                  annotation.name.lexeme == 'double'
              ? value.toDouble()
              : value;
        }

        _closures.add(
          TypedClosureDescriptor(
            indices[id]!,
            captureCount: 1,
            positionalCount: positional.length,
            requiredPositional: positional.where((p) => p.isRequired).length,
            namedNames: named.map((p) => p.name!.lexeme).toList(),
            requiredNamed: named
                .where((p) => p.isRequired)
                .map((p) => p.name!.lexeme)
                .toList(),
            positionalDefaults: positional.map(defaultValue).toList(),
            namedDefaults: named.map(defaultValue).toList(),
            hasEnvironment: false,
            boundReceiver: true,
          ),
        );
      }
    }
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
          resultKind: function.resultKind,
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
      classes: classes,
      callSites: _callSites,
      externalCalls: _externalCalls,
      closures: _closures,
      closureCalls: _closureCalls,
      globals: [
        for (var index = 0; index < context.globalIndex; index++)
          TypedGlobal(
            initializerFunction:
                indices[context.runtimeGlobalInitializerMap[index]] ?? -1,
            kind: reachableGlobals.contains(index)
                ? TypedArgumentKind.values[(context
                              .globalRepresentations[index] ??
                          MachineRepresentation.object)
                      .index]
                : TypedArgumentKind.object,
            isLate: context.globalsLate.contains(index),
            isFinal: context.globalsFinal.contains(index),
            name: context.globalNames[index] ?? '$index',
          ),
      ],
      exports: [
        for (final (library, name) in roots)
          if (!_isEnumConstructor(library, name))
            _export(library, name, indices),
      ],
    );
  }

  bool _isEnumConstructor(String library, String name) {
    final declarations =
        context.topLevelDeclarationsMap[context.libraryMap[library]]!;
    final declaration = declarations[name]?.declaration;
    if (declaration is ConstructorDeclaration &&
        declaration.parent is EnumDeclaration) {
      return true;
    }
    if (!name.endsWith('.')) return false;
    return declarations[name.substring(0, name.length - 1)]?.declaration
        is EnumDeclaration;
  }

  TypedExport _export(String library, String name, Map<int, int> indices) {
    final libraryId = context.libraryMap[library]!;
    final functionId = context.topLevelDeclarationPositions[libraryId]![name]!;
    final parameters =
        context.functionParameters[functionId] ?? const <FormalParameter>[];
    final declarations = context.topLevelDeclarationsMap[libraryId]!;
    final declaration = declarations[name]?.declaration;
    final previousTypes = {...?context.temporaryTypes[libraryId]};
    TypeRef.loadTemporaryTypes(context, switch (declaration) {
      FunctionDeclaration(:final functionExpression) =>
        functionExpression.typeParameters?.typeParameters,
      MethodDeclaration(:final typeParameters) =>
        typeParameters?.typeParameters,
      _ => null,
    }, libraryId);
    try {
      return TypedExport(
        library,
        name,
        indices[functionId]!,
        parameters: [
          for (final parameter in parameters)
            _exportParameter(libraryId, parameter, declaration),
        ],
      );
    } finally {
      context.temporaryTypes[libraryId] = previousTypes;
    }
  }

  TypedExportParameter _exportParameter(
    int library,
    FormalParameter parameter,
    Declaration? host,
  ) {
    final (declared, _) = getFormalParameterType(
      context,
      parameter,
      library,
      host,
    );
    final type = declared ?? CoreTypes.dynamic.ref(context);
    var defaultValue = evaluateDefaultValue(
      context,
      library,
      parameter is DefaultFormalParameter ? parameter.defaultValue : null,
    );
    if (defaultValue is int &&
        type.file == dartCoreFile &&
        type.name == 'double') {
      defaultValue = defaultValue.toDouble();
    }
    return TypedExportParameter(
      parameter.name!.lexeme,
      isRequired: parameter.isRequired,
      nullable: type.nullable || type.name == 'dynamic' || type.name == 'Null',
      typeName: type.name,
      typeLibrary: context.libraryMap.entries
          .firstWhere((entry) => entry.value == type.file)
          .key,
      defaultValue: defaultValue,
    );
  }

  Map<String, int> _classMembers(
    objects_ir.CreateClass allocation,
    int kind,
    Map<int, int> indices,
  ) {
    final members =
        context.instanceDeclarationPositions[allocation.library]![allocation
                .name]![kind]
            as Map;
    return {
      for (final entry in members.entries)
        if (entry.value as int >= 0) entry.key as String: indices[entry.value]!,
    };
  }

  int _resolveFunction(DeferredOrOffset target) {
    var id = target.offset;
    if (id == null && target.className != null) {
      final members =
          context.instanceDeclarationPositions[target.file]?[target.className];
      if (members != null) {
        final kind = target.methodType;
        if (kind != null) {
          id = (members[kind] as Map)[target.name] as int?;
        } else {
          for (var kind = 0; kind < 3; kind++) {
            id ??= (members[kind] as Map)[target.name] as int?;
          }
        }
      }
    }
    id ??= context.topLevelDeclarationPositions[target.file]?[target.name];
    if (id == null || !context.ssaFunctionGraphs.containsKey(id)) {
      throw UnsupportedError('Typed direct-call target $target');
    }
    return id;
  }

  _FunctionCode _compileFunction(int id, Map<int, int> functionIndices) {
    final spillCounts = [0, 0, 0, 0];
    var outgoingCount = 0;
    final sourceGraph = context.ssaFunctionGraphs[id]!;
    final representations = analyzeRepresentations(
      sourceGraph,
      functions: context.functionSignatures,
      globalRepresentations: context.globalRepresentations,
      functionId: id,
      resolveFunction: _resolveFunction,
    );
    // Native allocation provenance is independent of the public List type:
    // evaluated implementations can override getters and are not host Lists.
    final nativeLists = <cfg.SSA>{};
    final sourceOperations = [
      for (final blockId in sourceGraph.graph.vertices)
        ...sourceGraph[blockId]!.code,
    ];
    var addedNativeList = true;
    while (addedNativeList) {
      addedNativeList = false;
      for (final operation in sourceOperations) {
        final target = operation.writesTo;
        if (target == null || nativeLists.contains(target)) continue;
        final proven = switch (operation) {
          collection.NewList() => true,
          primitives.BoxList(:final source) ||
          primitives.Unbox(:final source) ||
          memory.Assign(:final source) ||
          cfg.Assign(:final source) => nativeLists.contains(source),
          cfg.PhiNode(:final sources) =>
            sources.isNotEmpty && sources.every(nativeLists.contains),
          _ => false,
        };
        if (proven) addedNativeList |= nativeLists.add(target);
      }
    }
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
        if (op is objects_ir.LoadPropertyDynamic &&
            op.name == 'length' &&
            nativeLists.contains(op.object)) {
          final target = value(op.target);
          final length = target.type == 0
              ? target
              : cfg.SSA(
                  'typed:listLength${temporaryCounter++}',
                  version: 0,
                  type: 0,
                );
          lowered.add(
            TypedOperation(_named(['aListLengthR']), length, [
              value(op.object),
            ]),
          );
          if (target != length) {
            lowered.add(TypedOperation(_named(['rBoxA']), target, [length]));
          }
          continue;
        }
        if (op is bridge.InvokeExternal) {
          final callLayout = TypedCallLayout(
            List.filled(op.args.length, TypedArgumentKind.object),
          );
          final registerArguments = <cfg.SSA>[];
          final argumentRegisters = <int>[];
          for (var index = 0; index < op.args.length; index++) {
            final input = value(op.args[index]);
            if (representations[op.args[index]] !=
                MachineRepresentation.object) {
              throw StateError(
                'External call argument requires explicit boxing',
              );
            }
            final location = callLayout.arguments[index];
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
            final overflow = temporary('externalOutgoing');
            lowered.add(
              TypedOperation(_named(['cLoadOutgoing']), overflow, []),
            );
            registerArguments.add(overflow);
            argumentRegisters.add(8);
            if (callLayout.overflowCount > outgoingCount) {
              outgoingCount = callLayout.overflowCount;
            }
          }
          var callIndex = _externalCalls.indexWhere(
            (call) =>
                call.externalFunctionId == op.externalFunctionId &&
                call.argumentCount == op.args.length,
          );
          if (callIndex < 0) {
            callIndex = _externalCalls.length;
            _externalCalls.add(
              TypedExternalCall(op.externalFunctionId, op.args.length),
            );
          }
          lowered.add(
            TypedOperation(
              _named(['callExternal']),
              value(op.target),
              registerArguments,
              fixedVariant: cfg.Variant(
                result: 6,
                arguments: argumentRegisters,
              ),
              immediate: callIndex,
              clobbers: {0, 1, 2, 3, 4, 5, 6, 7, 8},
            ),
          );
          continue;
        }
        if (op is objects_ir.InvokeDynamic ||
            op is objects_ir.LoadPropertyDynamic ||
            op is objects_ir.SetPropertyDynamic) {
          final (receiver, name, arguments, kind) = switch (op) {
            objects_ir.InvokeDynamic(:final object, :final name, :final args) =>
              (object, name, args, TypedMemberKind.method),
            objects_ir.LoadPropertyDynamic(:final object, :final name) => (
              object,
              name,
              <cfg.SSA>[],
              TypedMemberKind.getter,
            ),
            objects_ir.SetPropertyDynamic(
              :final object,
              :final name,
              :final variable,
            ) =>
              (object, name, [variable], TypedMemberKind.setter),
            _ => throw StateError('Unreachable member operation'),
          };
          final callLayout = TypedCallLayout(
            List.filled(arguments.length + 1, TypedArgumentKind.object),
          );
          final registerArguments = <cfg.SSA>[];
          final argumentRegisters = <int>[];
          final inputs = [receiver, ...arguments];
          for (var index = 0; index < inputs.length; index++) {
            final input = value(inputs[index]);
            final location = callLayout.arguments[index];
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
            final overflow = temporary('virtualOutgoing');
            lowered.add(
              TypedOperation(_named(['cLoadOutgoing']), overflow, []),
            );
            registerArguments.add(overflow);
            argumentRegisters.add(8);
            if (callLayout.overflowCount > outgoingCount) {
              outgoingCount = callLayout.overflowCount;
            }
          }
          var siteIndex = _callSites.indexWhere(
            (site) =>
                site.name == name &&
                site.argumentCount == arguments.length &&
                site.kind == kind,
          );
          if (siteIndex < 0) {
            siteIndex = _callSites.length;
            _callSites.add(
              TypedCallSite(name, argumentCount: arguments.length, kind: kind),
            );
          }
          lowered.add(
            TypedOperation(
              _named(['callVirtual']),
              op.writesTo == null ? null : value(op.writesTo!),
              registerArguments,
              fixedVariant: cfg.Variant(
                result: op.writesTo == null ? null : 6,
                arguments: argumentRegisters,
              ),
              immediate: siteIndex,
              clobbers: {0, 1, 2, 3, 4, 5, 6, 7, 8},
            ),
          );
          continue;
        }
        if (op is closures.CreateClosure) {
          for (var i = 0; i < op.captures.length; i++) {
            lowered.add(
              TypedOperation(
                _named(['rOutgoing', 'sOutgoing', 'cOutgoing']),
                null,
                [value(op.captures[i])],
                immediate: i,
              ),
            );
          }
          if (op.captures.length > outgoingCount) {
            outgoingCount = op.captures.length;
          }
          final index = _closures.length;
          _closures.add(
            TypedClosureDescriptor(
              functionIndices[_resolveFunction(op.target)]!,
              captureCount: op.captures.length,
              positionalCount: op.positionalTypes.length,
              requiredPositional: op.requiredPositional,
              namedNames: op.namedNames,
              requiredNamed: op.requiredNamed,
              hasEnvironment: op.hasEnvironment,
              boundReceiver: op.boundReceiver,
              positionalDefaults: op.positionalDefaults.isEmpty
                  ? List.filled(op.positionalTypes.length, null)
                  : op.positionalDefaults,
              namedDefaults: op.namedDefaults.isEmpty
                  ? List.filled(op.namedNames.length, null)
                  : op.namedDefaults,
            ),
          );
          lowered.add(
            TypedOperation(
              _named(['rCreateClosure']),
              value(op.result),
              [],
              immediate: index,
            ),
          );
          continue;
        }
        if (op is closures.NewCaptureCell || op is closures.WriteCaptureCell) {
          var input = value(switch (op) {
            closures.NewCaptureCell(:final value) => value,
            closures.WriteCaptureCell(:final value) => value,
            _ => throw StateError('Unreachable cell write'),
          });
          if (input.type < 3) {
            final native = temporary('cellValue');
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
          lowered.add(switch (op) {
            closures.NewCaptureCell(:final result) => TypedOperation(
              _named(['rNewCaptureCell']),
              value(result),
              [input],
            ),
            closures.WriteCaptureCell(:final cell) => TypedOperation(
              _named(['writeCaptureCellRS']),
              null,
              [value(cell), input],
            ),
            _ => throw StateError('Unreachable cell write'),
          });
          continue;
        }
        if (op is closures.ReadCaptureCell) {
          final result = value(op.result);
          final native = result.type < 3 ? temporary('cellRead') : result;
          lowered.add(
            TypedOperation(_named(['rReadCaptureCell']), native, [
              value(op.cell),
            ]),
          );
          if (result.type < 3) {
            lowered.add(
              TypedOperation(
                _named([
                  '${_registerNames[_banks[result.type].first]}NativeFromR',
                ]),
                result,
                [native],
              ),
            );
          }
          continue;
        }
        if (op is globals.LoadGlobal) {
          final result = value(op.target);
          lowered.add(
            TypedOperation(
              _named([
                '${_registerNames[_banks[result.type].first]}LoadGlobal',
              ]),
              result,
              [],
              immediate: op.index,
            ),
          );
          continue;
        }
        if (op is globals.SetGlobal) {
          final source = value(op.source);
          lowered.add(
            TypedOperation(
              _named(['${_registerNames[_banks[source.type].first]}SetGlobal']),
              null,
              [source],
              immediate: op.index,
            ),
          );
          continue;
        }
        if (op is closures.InvokeClosure) {
          // The frontend has already evaluated and snapshotted arguments in
          // source order. Canonical names allow exact named calls to stay in VM.
          final names = op.named.keys.toList()..sort();
          final inputs = [
            op.closure,
            ...op.positional,
            for (final name in names) op.named[name]!,
          ];
          final callLayout = TypedCallLayout(
            List.filled(inputs.length, TypedArgumentKind.object),
          );
          final registerArguments = <cfg.SSA>[];
          final argumentRegisters = <int>[];
          for (var i = 0; i < inputs.length; i++) {
            final location = callLayout.arguments[i];
            if (location.overflowIndex == null) {
              registerArguments.add(value(inputs[i]));
              argumentRegisters.add(
                _banks[location.bank.index][location.index],
              );
            } else {
              lowered.add(
                TypedOperation(
                  _named(['rOutgoing', 'sOutgoing', 'cOutgoing']),
                  null,
                  [value(inputs[i])],
                  immediate: location.overflowIndex,
                ),
              );
            }
          }
          if (callLayout.overflowCount > 0) {
            final overflow = temporary('closureOutgoing');
            lowered.add(
              TypedOperation(_named(['cLoadOutgoing']), overflow, []),
            );
            registerArguments.add(overflow);
            argumentRegisters.add(8);
            if (callLayout.overflowCount > outgoingCount) {
              outgoingCount = callLayout.overflowCount;
            }
          }
          final site = _closureCalls.length;
          _closureCalls.add(
            TypedClosureCall(op.positional.length, namedNames: names),
          );
          lowered.add(
            TypedOperation(
              _named(['callClosure']),
              value(op.result),
              registerArguments,
              fixedVariant: cfg.Variant(
                result: 6,
                arguments: argumentRegisters,
              ),
              immediate: site,
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
          closures.LoadCapture(:final index) => make(
            ['rLoadCapture'],
            [],
            immediate: index,
          ),
          bridge.PrepareBridgeArgument(:final source) => make(
            ['rBridgeArgument'],
            [source],
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
          StringOperation(:final string, :final argument, :final operator) =>
            make(
              [
                switch (operator) {
                  StringOperator.length => 'aStringLengthR',
                  StringOperator.concatenate => 'rStringConcatS',
                  StringOperator.codeUnitAt => 'aStringCodeUnitR',
                  StringOperator.indexAt => 'rStringIndexA',
                },
              ],
              [string, if (argument != null) argument],
            ),
          collection.NewList() => make(['cNewList'], []),
          collection.IndexList(:final list, :final index) => make(
            ['rListIndexCA'],
            [list, index],
          ),
          collection.ListSet(:final list, :final index, :final value) => make(
            ['listSetCAR'],
            [list, index, value],
          ),
          collection.ListAppend(:final list, :final value) => make(
            ['listAppendCR'],
            [list, value],
          ),
          collection.ListLength(:final list) => make(['aListLengthR'], [list]),
          primitives.BoxList(:final source) => make(['rBoxList'], [source]),
          objects_ir.CreateClass(:final library, :final name, :final $super) =>
            make(
              ['rCreateClassR'],
              [$super],
              immediate: _classIndices[(library, name)],
            ),
          objects_ir.LoadPropertyStatic(:final object, :final index) => make(
            ['rLoadPropertyR'],
            [object],
            immediate: index,
          ),
          objects_ir.SetPropertyStatic(
            :final object,
            :final index,
            :final value,
          ) =>
            make(['setPropertyRS'], [object, value], immediate: index),
          objects_ir.LoadSuper(:final object) => make(
            ['rLoadSuperR'],
            [object],
          ),
          objects_ir.LoadThis(:final object) => make(['rLoadThisR'], [object]),
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
            ['aAddB'],
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
          flow.Return(value: null) => make(['returnNull'], [], terminal: true),
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
              for (final code in op.codes) ...[
                cfg.Variant(
                  result: TypedOp.instructions[code].outputs.firstOrNull,
                  arguments: TypedOp.instructions[code].inputs,
                ),
                if (TypedOp.instructions[code].commutative)
                  cfg.Variant(
                    result: TypedOp.instructions[code].outputs.firstOrNull,
                    arguments: TypedOp.instructions[code].inputs.reversed
                        .toList(),
                  ),
              ],
            }
          : {op.fixedVariant!},
      create: (op, _) {
        if (op.fixedVariant != null) {
          return _Bytes(op.codes.single, op.immediate);
        }
        final code = op.codes.firstWhere((code) {
          final spec = TypedOp.instructions[code];
          if (spec.inputs.length != op.inputs.length) return false;
          bool matches(Iterable<int> registers) => registers.indexed.every(
            (entry) => entry.$2 == op.inputs[entry.$1].alloc.register,
          );
          return spec.outputs.firstOrNull == op.result?.alloc.register &&
              (matches(spec.inputs) ||
                  spec.commutative && matches(spec.inputs.reversed));
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
      if (slot + 1 > spillCounts[variable.type]) {
        spillCounts[variable.type] = slot + 1;
      }
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
      signature.result == null
          ? null
          : TypedArgumentKind.values[signature.result!.index],
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
    final commutative = name == 'Add' || name == 'Mul';
    return integer
        ? ['a${name}B', if (!commutative) 'b${name}A']
        : ['f${name}G', if (!commutative) 'g${name}F'];
  }

  int _double(double value) {
    // Keep bit-distinct constants such as -0.0 separate.
    doubles.add(value);
    return doubles.length - 1;
  }
}

class _FunctionCode {
  _FunctionCode(
    this.code,
    this.spills,
    this.argumentKinds,
    this.outgoing,
    this.resultKind,
  );
  final Uint8List code;
  final List<int> spills;
  final List<TypedArgumentKind> argumentKinds;
  final int outgoing;
  final TypedArgumentKind? resultKind;
}
