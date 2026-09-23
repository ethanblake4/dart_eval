import 'package:collection/collection.dart';

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
import '../../ir/exception.dart' as exceptions;
import '../../ir/async.dart' as async_ir;
import '../../ir/types.dart' as types_ir;
import '../../runtime/typed/typed_ops.g.dart';
import '../../runtime/typed/typed_program.dart';
import '../../runtime/typed/typed_function.dart';
import '../../runtime/typed/typed_class.dart';
import '../../runtime/typed/typed_call_site.dart';
import '../../runtime/typed/typed_external_call.dart';
import '../../runtime/typed/typed_closure_descriptor.dart';
import '../../runtime/typed/typed_export.dart';
import '../../runtime/typed/typed_global.dart';
import '../../runtime/typed/typed_exception.dart';
import 'package:analyzer/dart/ast/ast.dart';
import '../helpers/default_value.dart';
import '../helpers/fpl.dart';
import '../errors.dart';
import '../type.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import '../context.dart';
import '../model/function_type.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'representation.dart';
import 'primitive_optimization.dart';

bool _sameList<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

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
  bool get isConditionalBranch =>
      terminal &&
      otherTarget != null &&
      inputs.isNotEmpty &&
      codes.every(
        (code) =>
            TypedOp.instructions[code].immediate == TypedImmediate.branch ||
            TypedOp.instructions[code].immediate == TypedImmediate.shortBranch,
      );
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

/// Keep labels, including exception destinations, while choosing fallthroughs.
Map<int, List<_Bytes>> _layoutBlocks(Map<int, List<_Bytes>> blocks) {
  final originalOrder = blocks.keys.toList();
  // The CFG assembler omits jumps for its own layout. Restore those edges
  // before changing order, including fallthrough through an empty block.
  for (var i = 0; i + 1 < originalOrder.length; i++) {
    final code = blocks[originalOrder[i]]!;
    if (code.isEmpty || !TypedOp.instructions[code.last.code].terminates) {
      code.add(_Bytes(TypedOp.jump, originalOrder[i + 1]));
    }
  }
  final redirects = <int, int>{};
  int destination(int target) {
    final path = <int>{};
    while (!redirects.containsKey(target) && path.add(target)) {
      final code = blocks[target]!;
      if (code.length != 1 || code.single.code != TypedOp.jump) break;
      target = code.single.immediate!;
    }
    final result = redirects[target] ?? target;
    for (final id in path) {
      redirects[id] = result;
    }
    return result;
  }

  // Resolve against the original lists, before rewriting any of them.
  for (final id in originalOrder) {
    destination(id);
  }
  for (final code in blocks.values) {
    for (var i = 0; i < code.length; i++) {
      final instruction = code[i];
      if (TypedOp.instructions[instruction.code].immediate ==
          TypedImmediate.branch) {
        code[i] = _Bytes(instruction.code, redirects[instruction.immediate]!);
      }
    }
  }
  final aliases = <int, List<int>>{};
  for (final id in originalOrder) {
    final target = redirects[id]!;
    if (id != target) (aliases[target] ??= []).add(id);
  }
  final ordered = <int, List<_Bytes>>{};
  for (final start in originalOrder) {
    var id = redirects[start]!;
    while (!ordered.containsKey(id)) {
      final code = blocks[id]!;
      // Preserve forwarding labels at their destination without emitting
      // unreachable trampoline instructions. Cycles retain a real self-jump.
      for (final alias in aliases[id] ?? const <int>[]) {
        ordered[alias] = [];
      }
      ordered[id] = code;
      if (code.isEmpty || code.last.code != TypedOp.jump) break;
      id = code.last.immediate!;
    }
  }
  final order = ordered.keys.toList();
  for (var i = 0; i + 1 < order.length; i++) {
    final code = ordered[order[i]]!;
    if (code.isNotEmpty &&
        code.last.code == TypedOp.jump &&
        code.last.immediate == redirects[order[i + 1]]) {
      code.removeLast();
    }
  }
  return ordered;
}

/// Lowers an entrypoint to fixed typed registers and byte instructions.
/// Unsupported operations are rejected before a program can execute.
class TypedBackend {
  TypedBackend(this.context);
  final CompilerContext context;
  final integers = <int>[];
  final _integerIndices = <int, int>{};
  final doubles = <double>[];
  final objects = <Object?>[];
  final _objectIndices = <Object?, int>{};
  final _classIndices = <(int, String), int>{};
  final _callSites = <TypedCallSite>[];
  final _closures = <TypedClosureDescriptor>[];
  final _closureCalls = <TypedClosureCall>[];
  final _externalCalls = <TypedExternalCall>[];
  final _exceptionRegions = <TypedExceptionRegion>[];
  final _completionJumps = <TypedCompletionJump>[];
  Map<int, int> functionIndices = {};

  static final _codes = {
    for (var i = 0; i < TypedOp.instructions.length; i++)
      TypedOp.instructions[i].name: i,
  };
  // Register ID 5 is retired; preserve the remaining allocator IDs.
  static const _registerNames = ['a', 'b', 'f', 'g', 'e', '', 'r', 's', 'c'];
  static const _banks = [
    [0, 1],
    [2, 3],
    [4],
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
    final seen = <int>{};
    for (final (library, function) in roots) {
      final libraryId = context.libraryMap[library];
      final id = context.topLevelDeclarationPositions[libraryId]?[function];
      if (id == null) {
        throw ArgumentError('Unknown entrypoint $library::$function');
      }
      if (seen.add(id)) reachable.add(id);
    }
    if (reachable.isEmpty) {
      throw ArgumentError('No typed entrypoints were found');
    }
    final classAllocations = <objects_ir.CreateClass>[];
    final reachableGlobals = <int>{};
    for (var next = 0; next < reachable.length; next++) {
      final functionId = reachable[next];
      final graph = context.ssaFunctionGraphs[functionId]!;
      // Hidden default thunks are referenced by closure descriptors and
      // exports rather than call ops.
      for (final param
          in context.functionParameters[functionId] ??
              const <FormalParameter>[]) {
        final thunk = context.defaultThunkCache[param.defaultClause?.value];
        if (thunk != null && seen.add(thunk)) {
          reachable.add(thunk);
        }
      }
      for (final block in graph.graph.vertices) {
        for (final op in graph[block]!.code) {
          if (op is flow.Call || op is closures.CreateClosure) {
            final callee = _resolveFunction(switch (op) {
              flow.Call(:final target) => target,
              closures.CreateClosure(:final target) => target,
              _ => throw StateError('Unreachable callable'),
            });
            if (seen.add(callee)) reachable.add(callee);
            if (op is closures.CreateClosure) {
              for (final thunk in op.defaultThunks) {
                if (thunk >= 0 && seen.add(thunk)) {
                  reachable.add(thunk);
                }
              }
            }
          } else if (op is globals.LoadGlobal || op is globals.SetGlobal) {
            final index = switch (op) {
              globals.LoadGlobal(:final index) => index,
              globals.SetGlobal(:final index) => index,
              _ => throw StateError('Unreachable global operation'),
            };
            final initializer = context.runtimeGlobalInitializerMap[index];
            reachableGlobals.add(index);
            if (initializer != null && seen.add(initializer)) {
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
                if (target >= 0 && seen.add(target)) {
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
    // Function indices that already own a bound-receiver descriptor — a
    // member whose entry here would duplicate it is skipped once per set
    // rather than scanning `_closures` per member.
    final boundReceiverIds = <int>{
      for (final d in _closures)
        if (d.boundReceiver) d.functionId,
    };
    for (final allocation in classAllocations) {
      final memberGroups = context
          .instanceDeclarationPositions[allocation.library]![allocation.name]!;
      final memberIds = <int>{
        for (var kind = 0; kind < 3; kind++)
          ...(memberGroups[kind] as Map).values.cast<int>(),
      };
      final memberKinds = <int, (String, int)>{
        for (var kind = 1; kind < 3; kind++)
          for (final entry in (memberGroups[kind] as Map).entries)
            entry.value as int: (entry.key as String, kind),
      };
      for (final id in memberIds) {
        if (id < 0 || boundReceiverIds.contains(indices[id])) {
          continue;
        }
        final parameters =
            context.functionParameters[id] ?? const <FormalParameter>[];
        final positional = parameters.where((p) => p.isPositional).toList();
        final named = parameters.where((p) => p.isNamed).toList();
        final syntheticPositionalCount = parameters.isEmpty
            ? context.functionSignatures[id]!.parameters.length - 1
            : 0;
        final parameterTypes =
            context.functionParameterTypes[id] ??
            List.filled(
              positional.length + named.length + syntheticPositionalCount,
              CoreTypes.dynamic.ref(context),
            );
        (Object?, int) defaultValue(FormalParameter p) {
          final (value, thunk) = compileParameterDefault(
            context,
            allocation.library,
            p,
            // The declared type gives default expressions their context
            // type (`[C c = .zero]`); a type that references the callee's
            // own type parameters can't resolve here — leave it unbound.
            bound: p.type == null
                ? null
                : _tryAnnotationType(context, allocation.library, p.type!),
          );
          final annotation = p.type;
          return (
            value is int &&
                    annotation is NamedType &&
                    annotation.name.lexeme == 'double'
                ? value.toDouble()
                : value,
            thunk,
          );
        }

        final positionalDefaults = positional.map(defaultValue).toList();
        final namedDefaults = named.map(defaultValue).toList();

        boundReceiverIds.add(indices[id]!);
        _closures.add(
          TypedClosureDescriptor(
            indices[id]!,
            captureCount: 1,
            positionalCount: positional.length + syntheticPositionalCount,
            requiredPositional:
                positional.where((p) => p.isRequired).length +
                syntheticPositionalCount,
            namedNames: named.map((p) => p.name!.lexeme).toList(),
            requiredNamed: named
                .where((p) => p.isRequired)
                .map((p) => p.name!.lexeme)
                .toList(),
            positionalDefaults: [
              ...positionalDefaults.map((d) => d.$1),
              ...List<Object?>.filled(syntheticPositionalCount, null),
            ],
            namedDefaults: [for (final d in namedDefaults) d.$1],
            defaultThunks: [
              for (final d in positionalDefaults) d.$2,
              ...List<int>.filled(syntheticPositionalCount, -1),
              for (final d in namedDefaults) d.$2,
            ],
            parameterTypeIds: [
              for (final type in parameterTypes)
                type.isSpec(CoreTypes.dynamic) ||
                        type.isSpec(CoreTypes.voidType)
                    ? -1
                    : type.runtimeTypeId(context),
            ],
            parameterTypeParameterIndices: [
              for (final type in parameterTypes)
                type.typeParameterOwner?.startsWith('class:') == true
                    ? type.typeParameterIndex!
                    : -1,
            ],
            parameterNullable: [
              for (final type in parameterTypes) type.nullable,
            ],
            typeParameterBounds: [
              for (final bound
                  in context.functionTypeParameterBounds[id] ??
                      const <TypeRef>[])
                bound.runtimeTypeId(context),
            ],
            runtimeTypeId: switch (memberKinds[id]) {
              (final name, final kind) => _tearOffSignature(
                allocation,
                name,
                kind,
                context.functionRuntimeTypes[id] ??
                    CoreTypes.function.ref(context),
                parameters,
                parameterTypes,
              ),
              _ =>
                context.functionRuntimeTypes[id] ??
                    CoreTypes.function.ref(context),
            }.runtimeTypeId(context),
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
      exceptionRegions: [
        for (final region in _exceptionRegions)
          TypedExceptionRegion(
            region.functionId,
            catchTarget: region.catchTarget < 0
                ? -1
                : region.catchTarget + functions[region.functionId].entry,
            finallyTarget: region.finallyTarget < 0
                ? -1
                : region.finallyTarget + functions[region.functionId].entry,
          ),
      ],
      completionJumps: [
        for (final jump in _completionJumps)
          TypedCompletionJump(
            jump.functionId,
            jump.target + functions[jump.functionId].entry,
            jump.targetDepth,
          ),
      ],
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

  Declaration? _constructorOwner(String library, String name) {
    final declarations =
        context.topLevelDeclarationsMap[context.libraryMap[library]]!;
    final declaration = declarations[name]?.declaration;
    if (declaration is ConstructorDeclaration) {
      // The export name's prefix is the owning class — for a class type
      // alias's forwarding constructor `C.n` that's the alias `C`, not the
      // class declaring the target constructor `S.n`.
      final owner =
          declarations[name.substring(0, name.lastIndexOf('.'))]?.declaration ??
          declaration.parent?.parent;
      return owner is Declaration ? owner : null;
    }
    if (!name.endsWith('.')) return null;
    final owner = declarations[name.substring(0, name.length - 1)]?.declaration;
    return owner is ClassDeclaration ||
            owner is EnumDeclaration ||
            owner is ClassTypeAlias
        ? owner
        : null;
  }

  bool _isEnumConstructor(String library, String name) =>
      _constructorOwner(library, name) is EnumDeclaration;

  TypedExport _export(String library, String name, Map<int, int> indices) {
    final libraryId = context.libraryMap[library]!;
    final functionId = context.topLevelDeclarationPositions[libraryId]![name]!;
    final parameters =
        context.functionParameters[functionId] ?? const <FormalParameter>[];
    final declarations = context.topLevelDeclarationsMap[libraryId]!;
    var declaration = declarations[name]?.declaration;
    var parameterLibrary = libraryId;
    var parameterHost = declaration;
    if (declaration is ConstructorDeclaration &&
        declaration.redirectedConstructor != null) {
      // Redirecting factories bind and forward in the target's signature.
      final redirect = declaration.redirectedConstructor!;
      final (redirectTypeName, redirectCtorName) = splitConstructorTypeName(
        context,
        libraryId,
        redirect.type,
        redirect.name?.name,
      );
      final redirectRef = context.visibleTypes[libraryId]![redirectTypeName];
      final redirectDecl = redirectRef == null
          ? null
          : context
                .topLevelDeclarationsMap[redirectRef
                    .file]!['${redirectRef.name}.$redirectCtorName']
                ?.declaration;
      if (redirectDecl is ConstructorDeclaration) {
        parameterHost = redirectDecl;
        parameterLibrary = redirectRef!.file;
      }
    }
    final constructorOwner = _constructorOwner(library, name);
    final previousTypes = {...?context.temporaryTypes[libraryId]};
    final typeParameters = switch (constructorOwner) {
      null => switch (declaration) {
        FunctionDeclaration(:final functionExpression) =>
          functionExpression.typeParameters?.typeParameters,
        MethodDeclaration(:final typeParameters) =>
          typeParameters?.typeParameters,
        _ => null,
      },
      _ => classLikeClauses(constructorOwner).$4?.typeParameters,
    };
    TypeRef.loadTemporaryTypes(
      context,
      typeParameters,
      library: libraryId,
      owner: constructorOwner == null
          ? null
          : 'class:$libraryId:${declarationName(constructorOwner)}',
    );
    try {
      final isGenerativeConstructor =
          (constructorOwner is ClassDeclaration ||
              constructorOwner is ClassTypeAlias) &&
          (declaration is! ConstructorDeclaration ||
              declaration.factoryKeyword == null);
      return TypedExport(
        library,
        name,
        indices[functionId]!,
        generativeConstructorRuntimeTypeId: isGenerativeConstructor
            ? TypeRef.lookupDeclaration(
                context,
                libraryId,
                constructorOwner!,
              ).runtimeTypeId(context)
            : -1,
        parameters: [
          for (final parameter in parameters)
            _exportParameter(
              parameterLibrary,
              parameter,
              parameterHost,
              indices,
            ),
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
    Map<int, int> indices,
  ) {
    final (declared, _) = getFormalParameterType(
      context,
      parameter,
      library,
      host,
    );
    final type = declared ?? CoreTypes.dynamic.ref(context);
    var (defaultValue, defaultThunk) = compileParameterDefault(
      context,
      library,
      parameter,
    );
    if (defaultValue is int && type.isSpec(CoreTypes.double)) {
      defaultValue = defaultValue.toDouble();
    }
    return TypedExportParameter(
      parameter.name!.lexeme,
      isRequired: parameter.isRequired,
      nullable: type.nullable || type.name == 'dynamic' || type.name == 'Null',
      typeName: type.name,
      typeLibrary:
          context.libraryMap.entries
              .firstWhereOrNull((entry) => entry.value == type.file)
              ?.key ??
          // Structural types (records, function types) carry file: -1.
          '',
      runtimeTypeId: type.runtimeTypeId(context),
      defaultValue: defaultValue,
      defaultThunk: defaultThunk < 0 ? -1 : indices[defaultThunk]!,
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
    final session = _LoweringSession(this, id, functionIndices);
    session.lower();
    session.fuseComparisonBranches();
    return session.emit();
  }

  int _object(Object? value) {
    final cached = _objectIndices[value];
    if (cached != null) return cached;
    final index = objects.length;
    objects.add(value);
    _objectIndices[value] = index;
    return index;
  }

  int _integer(int value) {
    final cached = _integerIndices[value];
    if (cached != null) return cached;
    final index = integers.length;
    integers.add(value);
    _integerIndices[value] = index;
    return index;
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
      return ['e$comparison${integer ? 'AB' : 'FG'}'];
    }
    final name = switch (operator) {
      NumericOperator.add => 'Add',
      NumericOperator.subtract => 'Sub',
      NumericOperator.multiply => 'Mul',
      NumericOperator.divide when !integer => 'Div',
      NumericOperator.truncatingDivide when integer => 'Div',
      NumericOperator.modulo when integer => 'Mod',
      NumericOperator.bitAnd when integer => 'And',
      NumericOperator.bitOr when integer => 'Or',
      NumericOperator.bitXor when integer => 'Xor',
      NumericOperator.shiftLeft when integer => 'ShiftLeft',
      NumericOperator.shiftRight when integer => 'ShiftRight',
      NumericOperator.unsignedShiftRight when integer => 'UnsignedShiftRight',
      _ => throw UnsupportedError(
        'Typed numeric operation $representation $operator',
      ),
    };
    final commutative = {'Add', 'Mul', 'And', 'Or', 'Xor'}.contains(name);
    return integer
        ? ['a${name}B', if (!commutative) 'b${name}A']
        : ['f${name}G', if (!commutative) 'g${name}F'];
  }

  int _double(double value) {
    // Keep bit-distinct constants such as -0.0 separate.
    doubles.add(value);
    return doubles.length - 1;
  }

  /// The reified signature of a bound member tear-off: parameters covariant in
  /// the member's override closure — marked `covariant`, or declared with a
  /// type mentioning a class type parameter — reify as `Object?`, matching the
  /// VM (`C<int>().m` where `void m(T t)` is `(Object?) => void`).
  TypeRef _tearOffSignature(
    objects_ir.CreateClass allocation,
    String memberName,
    int kind,
    TypeRef signature,
    List<FormalParameter> parameters,
    List<TypeRef> parameterTypes,
  ) {
    final function = signature.functionType;
    if (function == null) return signature;
    final positional = <int>{};
    final named = <String>{};
    _markCovariantParameters(parameters, parameterTypes, positional, named);
    final declaringType =
        context.visibleTypes[allocation.library]?[allocation.name];
    if (declaringType != null) {
      try {
        _collectCovariantParameters(
          declaringType,
          memberName,
          kind,
          positional,
          named,
          {},
        );
      } on CompileError {
        // Unresolvable supertypes (e.g. bridges) contribute no covariance.
      }
    }
    if (positional.isEmpty && named.isEmpty) return signature;
    final object = CoreTypes.object.ref(context).copyWith(nullable: true);
    FunctionFormalParameter erased(FunctionFormalParameter p) =>
        FunctionFormalParameter(
          p.name,
          FunctionTypeAnnotation.type(object),
          p.isRequired,
        );
    var index = 0;
    final positionalParameters = [
      for (final p in function.normalParameters)
        positional.contains(index++) ? erased(p) : p,
      for (final p in function.optionalParameters)
        positional.contains(index++) ? erased(p) : p,
    ];
    return signature.copyWith(
      functionType: EvalFunctionType(
        positionalParameters.sublist(0, function.normalParameters.length),
        positionalParameters.sublist(function.normalParameters.length),
        {
          for (final entry in function.namedParameters.entries)
            entry.key: named.contains(entry.key)
                ? erased(entry.value)
                : entry.value,
        },
        function.returnType,
        function.generics,
      ),
    );
  }

  /// Marks [parameters]' covariant entries — positional indexes in
  /// [positional], names in [named]. [types] are the resolved parameter types
  /// aligned with [parameters] (positional then named) when available.
  void _markCovariantParameters(
    List<FormalParameter> parameters,
    List<TypeRef>? types,
    Set<int> positional,
    Set<String> named,
  ) {
    var index = 0;
    for (final parameter in parameters) {
      var covariant = parameter.covariantKeyword != null;
      if (!covariant &&
          types != null &&
          index < types.length &&
          _hasClassTypeParameter(types[index])) {
        covariant = true;
      }
      if (covariant) {
        if (parameter.isNamed) {
          named.add(parameter.name!.lexeme);
        } else {
          positional.add(index);
        }
      }
      index++;
    }
  }

  /// Unions [memberName]'s covariant parameters across [type]'s override
  /// closure: each supertype declaration's own marks plus its supertypes'.
  void _collectCovariantParameters(
    TypeRef type,
    String memberName,
    int kind,
    Set<int> positional,
    Set<String> named,
    Set<String> visited,
  ) {
    if (!visited.add('${type.file}:${type.name}')) return;
    final key = kind == 1 ? '$memberName*s' : memberName;
    final decl = context.instanceDeclarationsMap[type.file]?[type.name]?[key];
    if (decl is MethodDeclaration) {
      final id =
          context.instanceDeclarationPositions[type.file]?[type
              .name]?[kind]?[memberName];
      _markCovariantParameters(
        decl.parameters?.parameters ?? const <FormalParameter>[],
        id == null ? null : context.functionParameterTypes[id],
        positional,
        named,
      );
    }
    for (final supertype in context.typeSystem.directSupertypes(type)) {
      try {
        _collectCovariantParameters(
          supertype,
          memberName,
          kind,
          positional,
          named,
          visited,
        );
      } on CompileError {
        // Skip unresolvable supertypes.
      }
    }
  }

  /// Whether [type] mentions a class type parameter — a parameter declared
  /// with such a type is implicitly covariant.
  bool _hasClassTypeParameter(TypeRef type) {
    if (type.isClassTypeParameter) return true;
    if (type.specifiedTypeArgs.any(_hasClassTypeParameter) ||
        type.recordFields.any((field) => _hasClassTypeParameter(field.type))) {
      return true;
    }
    final function = type.functionType;
    if (function == null) return false;
    if ([
      ...function.normalParameters,
      ...function.optionalParameters,
      ...function.namedParameters.values,
    ].any((p) {
      final annotation = p.type.type;
      return annotation != null && _hasClassTypeParameter(annotation);
    })) {
      return true;
    }
    final returnType = function.returnType.type;
    return returnType != null && _hasClassTypeParameter(returnType);
  }
}

/// Per-function lowering state for [TypedBackend._compileFunction]. One
/// session lowers a single SSA function graph to typed ops: the constructor
/// analyzes the graph, [lower] translates every block, and [emit] runs register
/// allocation and byte emission.
class _LoweringSession {
  _LoweringSession(this.b, this.id, this.functionIndices) {
    firstRegion = b._exceptionRegions.length;
    firstCompletion = b._completionJumps.length;

    // Skip the clone's SSA reindex: optimizePrimitives and lower() mutate the
    // copy before emit() rebuilds SSA metadata itself.
    sourceGraph = b.context.ssaFunctionGraphs[id]!.clone(refresh: false);
    optimizePrimitives(sourceGraph);
    representations = analyzeRepresentations(
      sourceGraph,
      functions: b.context.functionSignatures,
      globalRepresentations: b.context.globalRepresentations,
      functionId: id,
      resolveFunction: b._resolveFunction,
    );
    // Native allocation provenance is independent of the public List type:
    // evaluated implementations can override getters and are not host Lists.

    final sourceOperations = [
      for (final blockId in sourceGraph.graph.vertices)
        ...sourceGraph[blockId]!.code,
    ];

    for (final operation in sourceOperations) {
      final slot = switch (operation) {
        exceptions.StoreExceptionSlot(:final slot) ||
        exceptions.LoadExceptionSlot(:final slot) => slot,
        _ => null,
      };
      if (slot == null || exceptionSlots.containsKey(slot)) continue;
      final bank = slot.representation.index < 3
          ? slot.representation.index
          : 3;
      exceptionSlots[slot] = exceptionSlotCounts[bank]++;
    }
    for (var bank = 0; bank < 4; bank++) {
      spillCounts[bank] = exceptionSlotCounts[bank];
    }
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
    // sourceGraph is not referenced after construction; adopt it as the
    // working graph instead of paying for a second deep copy.
    graph = sourceGraph;

    for (final blockId in graph.graph.vertices) {
      for (final op in graph[blockId]!.code.whereType<exceptions.EnterTry>()) {
        final index = b._exceptionRegions.length;
        regionIndices[op] = index;
        if (op.catchTarget != null) catchRegionIndices[op.catchTarget!] = index;
        b._exceptionRegions.add(
          TypedExceptionRegion(
            functionIndices[id]!,
            catchTarget: op.catchTarget == null
                ? -1
                : graph[op.catchTarget!]!.id!,
            finallyTarget: op.finallyTarget == null
                ? -1
                : graph[op.finallyTarget!]!.id!,
          ),
        );
      }
    }
    signature = b.context.functionSignatures[id]!;
    argumentKinds = [
      for (final representation in signature.parameters)
        TypedArgumentKind.values[representation.index],
    ];
    layout = TypedCallLayout(argumentKinds);
    overflowInput = layout.overflowCount == 0 ? null : temporary('overflow');
  }

  /// Owning backend — program-level tables (external calls, closures, exception
  /// regions, completion jumps) are appended onto it while lowering.
  final TypedBackend b;
  final int id;
  final Map<int, int> functionIndices;

  late final cfg.ControlFlowGraph sourceGraph;
  late final cfg.ControlFlowGraph graph;
  late final Map<cfg.SSA, MachineRepresentation> representations;
  late final TypedCallLayout layout;
  late final List<TypedArgumentKind> argumentKinds;
  cfg.SSA? overflowInput;
  final parameterInputs = <int, cfg.SSA>{};
  final spillCounts = [0, 0, 0, 0];
  var outgoingCount = 0;
  final exceptionSlotCounts = [0, 0, 0, 0];
  final exceptionSlots = <exceptions.ExceptionSlot, int>{};
  final nativeLists = <cfg.SSA>{};
  final regionIndices = <exceptions.EnterTry, int>{};
  final catchRegionIndices = <String, int>{};
  late var firstRegion = 0;
  late var firstCompletion = 0;
  var temporaryCounter = 0;
  late final MachineFunctionSignature signature;

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

  cfg.SSA temporary(String name) =>
      cfg.SSA('typed:$name${temporaryCounter++}', version: 0, type: 3);

  /// Copies a native-representation value into a fresh object-register
  /// temporary, emitting the `rFrom*` widening op.
  cfg.SSA _boxToObject(cfg.SSA input, List<cfg.Operation> out) {
    final native = temporary('native');
    out.add(
      TypedOperation(
        b._named([
          for (final register in TypedBackend._banks[input.type])
            'rFrom${TypedBackend._registerNames[register].toUpperCase()}',
        ]),
        native,
        [input],
      ),
    );
    return native;
  }

  /// Marshals [inputs] into callee argument registers according to [kinds],
  /// emitting overflow stores and the overflow-list load into [out].
  /// [requireBoxed] asserts every argument already carries the object
  /// representation (external bridge calls); [boxNatives] instead widens
  /// native values into object temporaries.
  (List<cfg.SSA>, List<int>) _marshalArguments(
    List<cfg.SSA> inputs,
    List<TypedArgumentKind> kinds,
    List<cfg.Operation> out, {
    required String temporaryPrefix,
    bool requireBoxed = false,
    bool boxNatives = false,
  }) {
    final callLayout = TypedCallLayout(kinds);
    final registerArguments = <cfg.SSA>[];
    final argumentRegisters = <int>[];
    for (var index = 0; index < inputs.length; index++) {
      var input = value(inputs[index]);
      if (requireBoxed &&
          representations[inputs[index]] != MachineRepresentation.object) {
        throw StateError('External call argument requires explicit boxing');
      }
      final location = callLayout.arguments[index];
      if (boxNatives &&
          location.bank == TypedRegisterBank.object &&
          input.type != 3) {
        input = _boxToObject(input, out);
      }
      if (location.overflowIndex == null) {
        registerArguments.add(input);
        argumentRegisters.add(
          TypedBackend._banks[location.bank.index][location.index],
        );
      } else {
        out.add(
          TypedOperation(
            b._named(['rOutgoing', 'sOutgoing', 'cOutgoing']),
            null,
            [input],
            immediate: location.overflowIndex,
          ),
        );
      }
    }
    if (callLayout.overflowCount > 0) {
      final overflow = temporary(temporaryPrefix);
      out.add(TypedOperation(b._named(['cLoadOutgoing']), overflow, []));
      registerArguments.add(overflow);
      argumentRegisters.add(8);
    }
    if (callLayout.overflowCount > outgoingCount) {
      outgoingCount = callLayout.overflowCount;
    }
    return (registerArguments, argumentRegisters);
  }

  /// Lowers [closures.CreateClosure]: writes captured cells to the outgoing
  /// overflow area, registers the closure descriptor, and emits `rCreateClosure`.
  void _lowerCreateClosure(closures.CreateClosure op, List<cfg.Operation> out) {
    final sourceFunctionId = b._resolveFunction(op.target);
    for (var i = 0; i < op.captures.length; i++) {
      out.add(
        TypedOperation(
          b._named(['rOutgoing', 'sOutgoing', 'cOutgoing']),
          null,
          [value(op.captures[i])],
          immediate: i,
        ),
      );
    }
    if (op.captures.length > outgoingCount) {
      outgoingCount = op.captures.length;
    }
    final index = b._closures.length;
    b._closures.add(
      TypedClosureDescriptor(
        functionIndices[sourceFunctionId]!,
        captureCount: op.captures.length,
        positionalCount: op.positionalCount,
        requiredPositional: op.requiredPositional,
        namedNames: op.namedNames,
        requiredNamed: op.requiredNamed,
        hasEnvironment: op.hasEnvironment,
        boundReceiver: op.boundReceiver,
        positionalDefaults: op.positionalDefaults.isEmpty
            ? List.filled(op.positionalCount, null)
            : op.positionalDefaults,
        namedDefaults: op.namedDefaults.isEmpty
            ? List.filled(op.namedNames.length, null)
            : op.namedDefaults,
        defaultThunks: op.defaultThunks.every((t) => t < 0)
            ? const []
            : [
                for (final t in op.defaultThunks)
                  t < 0 ? -1 : functionIndices[t]!,
              ],
        parameterTypeIds: [
          for (final type
              in b.context.functionParameterTypes[sourceFunctionId] ??
                  const <TypeRef>[])
            type.isSpec(CoreTypes.dynamic) || type.isSpec(CoreTypes.voidType)
                ? -1
                : type.runtimeTypeId(b.context),
        ],
        parameterTypeParameterIndices: [
          for (final type
              in b.context.functionParameterTypes[sourceFunctionId] ??
                  const <TypeRef>[])
            type.typeParameterOwner?.startsWith('class:') == true
                ? type.typeParameterIndex!
                : -1,
        ],
        parameterNullable: [
          for (final type
              in b.context.functionParameterTypes[sourceFunctionId] ??
                  const <TypeRef>[])
            type.nullable,
        ],
        typeParameterBounds: [
          for (final bound
              in b.context.functionTypeParameterBounds[sourceFunctionId] ??
                  const <TypeRef>[])
            bound.runtimeTypeId(b.context),
        ],
        runtimeTypeId: op.runtimeTypeId < 0
            ? CoreTypes.function.ref(b.context).runtimeTypeId(b.context)
            : op.runtimeTypeId,
      ),
    );
    out.add(
      TypedOperation(
        b._named(['rCreateClosure']),
        value(op.result),
        [],
        immediate: index,
      ),
    );
  }

  /// Lowers dynamic member operations (invoke, load, set) into a `callVirtual`
  /// op keyed by a deduplicated [TypedCallSite].
  void _lowerDynamicMember(cfg.Operation op, List<cfg.Operation> out) {
    final (
      receiver,
      name,
      arguments,
      positionalCount,
      namedNames,
      callerLibrary,
      typeArguments,
      kind,
    ) = switch (op) {
      objects_ir.InvokeDynamic(
        :final object,
        :final name,
        :final args,
        :final positionalCount,
        :final namedNames,
        :final callerLibrary,
        :final typeArguments,
      ) =>
        (
          object,
          name,
          args,
          positionalCount,
          namedNames,
          b.context.libraryMap.entries
              .singleWhere((entry) => entry.value == callerLibrary)
              .key,
          typeArguments,
          TypedMemberKind.method,
        ),
      objects_ir.LoadPropertyDynamic(
        :final object,
        :final name,
        :final callerLibrary,
      ) =>
        (
          object,
          name,
          <cfg.SSA>[],
          0,
          const <String>[],
          callerLibrary < 0
              ? ''
              : b.context.libraryMap.entries
                    .singleWhere((entry) => entry.value == callerLibrary)
                    .key,
          const <int>[],
          TypedMemberKind.getter,
        ),
      objects_ir.SetPropertyDynamic(
        :final object,
        :final name,
        :final variable,
        :final callerLibrary,
      ) =>
        (
          object,
          name,
          [variable],
          1,
          const <String>[],
          callerLibrary < 0
              ? ''
              : b.context.libraryMap.entries
                    .singleWhere((entry) => entry.value == callerLibrary)
                    .key,
          const <int>[],
          TypedMemberKind.setter,
        ),
      _ => throw StateError('Unreachable member operation'),
    };
    final (registerArguments, argumentRegisters) = _marshalArguments(
      [receiver, ...arguments],
      List.filled(arguments.length + 1, TypedArgumentKind.object),
      out,
      temporaryPrefix: 'virtualOutgoing',
    );
    var siteIndex = b._callSites.indexWhere(
      (site) =>
          site.name == name &&
          site.argumentCount == arguments.length &&
          site.positionalCount == positionalCount &&
          _sameList(site.namedNames, namedNames) &&
          site.callerLibrary == callerLibrary &&
          _sameList(site.typeArguments, typeArguments) &&
          site.kind == kind,
    );
    if (siteIndex < 0) {
      siteIndex = b._callSites.length;
      b._callSites.add(
        TypedCallSite(
          name,
          argumentCount: arguments.length,
          positionalCount: positionalCount,
          namedNames: namedNames,
          callerLibrary: callerLibrary,
          typeArguments: typeArguments,
          kind: kind,
        ),
      );
    }
    out.add(
      TypedOperation(
        b._named(['callVirtual']),
        op.writesTo == null ? null : value(op.writesTo!),
        registerArguments,
        fixedVariant: cfg.Variant(
          result: op.writesTo == null ? null : 6,
          arguments: argumentRegisters,
        ),
        immediate: siteIndex,
        clobbers: {0, 1, 2, 3, 4, 6, 7, 8},
      ),
    );
  }

  /// Lowers every block's ops from SSA form to [TypedOperation]s.
  void lower() {
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
          cfg.RegisterInput(
            input,
            TypedBackend._banks[location.bank.index][location.index],
          ),
        );
      }
      for (final op in block.code) {
        if (op is async_ir.Await) {
          lowered.add(
            TypedOperation(
              b._named(['rAwait']),
              value(op.result),
              [value(op.subject)],
              clobbers: {0, 1, 2, 3, 4, 6, 7, 8},
            ),
          );
          continue;
        }
        if (op is exceptions.EnterTry) {
          lowered.add(
            TypedOperation(
              b._named(['enterTry']),
              null,
              [],
              immediate: regionIndices[op],
            ),
          );
          continue;
        }
        if (op is exceptions.CompleteJump) {
          final index = b._completionJumps.length;
          b._completionJumps.add(
            TypedCompletionJump(
              functionIndices[id]!,
              graph[op.target]!.id!,
              op.targetDepth,
            ),
          );
          lowered.add(
            TypedOperation(
              b._named(['completeJump']),
              null,
              [],
              immediate: index,
              terminal: true,
            ),
          );
          continue;
        }
        if (op is types_ir.IsType) {
          final target = value(op.result);
          final test = op.not
              ? cfg.SSA(
                  'typed:isType${temporaryCounter++}',
                  version: 0,
                  type: 2,
                )
              : target;
          lowered.add(
            TypedOperation(b._named(['eIsTypeR']), test, [
              value(op.object),
            ], immediate: op.typeId),
          );
          if (op.not) {
            lowered.add(TypedOperation(b._named(['eNot']), target, [test]));
          }
          continue;
        }
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
            TypedOperation(b._named(['aListLengthR']), length, [
              value(op.object),
            ]),
          );
          if (target != length) {
            lowered.add(TypedOperation(b._named(['rBoxA']), target, [length]));
          }
          continue;
        }
        if (op is bridge.NewBridgeSuperShim) {
          lowered.add(
            TypedOperation(
              b._named(['rNewBridgeSuperShim']),
              value(op.target),
              [],
            ),
          );
          continue;
        }
        if (op is bridge.ParentBridgeSuperShim) {
          lowered.add(
            TypedOperation(b._named(['parentBridgeSuperShim']), null, [
              value(op.shim),
              value(op.parent),
            ]),
          );
          continue;
        }
        if (op is bridge.InvokeExternal || op is bridge.BridgeInstantiate) {
          final creation = op is bridge.BridgeInstantiate ? op : null;
          final external = op is bridge.InvokeExternal
              ? op
              : bridge.InvokeExternal(
                  creation!.target,
                  creation.externalFunctionId,
                  creation.args,
                );
          final (registerArguments, argumentRegisters) = _marshalArguments(
            external.args,
            List.filled(external.args.length, TypedArgumentKind.object),
            lowered,
            temporaryPrefix: 'externalOutgoing',
            requireBoxed: true,
          );
          var callIndex = b._externalCalls.indexWhere(
            (call) =>
                call.externalFunctionId == external.externalFunctionId &&
                call.argumentCount == external.args.length,
          );
          if (callIndex < 0) {
            callIndex = b._externalCalls.length;
            b._externalCalls.add(
              TypedExternalCall(
                external.externalFunctionId,
                external.args.length,
              ),
            );
          }
          lowered.add(
            TypedOperation(
              b._named(['callExternal']),
              creation == null
                  ? value(external.target)
                  : temporary('bridgeHost'),
              registerArguments,
              fixedVariant: cfg.Variant(
                result: 6,
                arguments: argumentRegisters,
              ),
              immediate: callIndex,
              clobbers: {0, 1, 2, 3, 4, 6, 7, 8},
            ),
          );
          if (creation != null) {
            final host = lowered.last.writesTo!;
            lowered.add(
              TypedOperation(
                b._named(['rAttachBridge']),
                value(creation.target),
                [host, value(creation.subclass)],
                immediate: creation.runtimeTypeId,
              ),
            );
          }
          continue;
        }
        if (op is objects_ir.InvokeDynamic ||
            op is objects_ir.LoadPropertyDynamic ||
            op is objects_ir.SetPropertyDynamic) {
          _lowerDynamicMember(op, lowered);
          continue;
        }
        if (op is closures.CreateClosure) {
          _lowerCreateClosure(op, lowered);
          continue;
        }
        if (op is closures.NewCaptureCell || op is closures.WriteCaptureCell) {
          var input = value(switch (op) {
            closures.NewCaptureCell(:final value) => value,
            closures.WriteCaptureCell(:final value) => value,
            _ => throw StateError('Unreachable cell write'),
          });
          if (input.type < 3) {
            input = _boxToObject(input, lowered);
          }
          lowered.add(switch (op) {
            closures.NewCaptureCell(:final result) => TypedOperation(
              b._named(['rNewCaptureCell']),
              value(result),
              [input],
            ),
            closures.WriteCaptureCell(:final cell) => TypedOperation(
              b._named(['writeCaptureCellRS']),
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
            TypedOperation(b._named(['rReadCaptureCell']), native, [
              value(op.cell),
            ]),
          );
          if (result.type < 3) {
            lowered.add(
              TypedOperation(
                b._named([
                  '${TypedBackend._registerNames[TypedBackend._banks[result.type].first]}NativeFromR',
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
              b._named([
                '${TypedBackend._registerNames[TypedBackend._banks[result.type].first]}LoadGlobal',
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
              b._named([
                '${TypedBackend._registerNames[TypedBackend._banks[source.type].first]}SetGlobal',
              ]),
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
          final (registerArguments, argumentRegisters) = _marshalArguments(
            inputs,
            List.filled(inputs.length, TypedArgumentKind.object),
            lowered,
            temporaryPrefix: 'closureOutgoing',
          );
          final site = b._closureCalls.length;
          b._closureCalls.add(
            TypedClosureCall(
              op.positional.length,
              namedNames: names,
              typeArguments: op.typeArguments,
              trusted: op.trusted,
            ),
          );
          lowered.add(
            TypedOperation(
              b._named(['callClosure']),
              value(op.result),
              registerArguments,
              fixedVariant: cfg.Variant(
                result: 6,
                arguments: argumentRegisters,
              ),
              immediate: site,
              clobbers: {0, 1, 2, 3, 4, 6, 7, 8},
            ),
          );
          continue;
        }
        if (op is flow.Call) {
          final callee = b._resolveFunction(op.target);
          if (op.typeEnvironmentReceiver != null) {
            lowered.add(
              TypedOperation(b._named(['rSetCallTypeReceiver']), null, [
                value(op.typeEnvironmentReceiver!),
              ]),
            );
          }
          if (op.typeArguments.isNotEmpty) {
            lowered.add(
              TypedOperation(
                b._named(['setCallTypeArguments']),
                null,
                const [],
                immediate: b.context.constantPool.addOrGet(op.typeArguments),
              ),
            );
          }
          final (registerArguments, argumentRegisters) = _marshalArguments(
            op.arguments,
            [
              for (final representation
                  in b.context.functionSignatures[callee]!.parameters)
                TypedArgumentKind.values[representation.index],
            ],
            lowered,
            temporaryPrefix: 'outgoing',
            boxNatives: true,
          );
          final result = value(op.writesTo!);
          lowered.add(
            TypedOperation(
              b._named(['call']),
              result,
              registerArguments,
              fixedVariant: cfg.Variant(
                result: TypedBackend._banks[result.type].first,
                arguments: argumentRegisters,
              ),
              immediate: functionIndices[b._resolveFunction(op.target)],
              clobbers: {0, 1, 2, 3, 4, 6, 7, 8},
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
              TypedOperation(b._named(['rOverflow']), input, [
                overflowInput!,
              ], immediate: location.overflowIndex),
            );
          }
          if (location.bank.index != target.type) {
            lowered.add(
              TypedOperation(
                b._named([
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
          b._named(names),
          op.writesTo == null || op.writesTo!.name == '@branch'
              ? null
              : value(op.writesTo!),
          inputs.map(value).toList(),
          immediate: immediate,
          terminal: terminal,
          otherTarget: otherTarget,
        );
        List<String> bankNames(cfg.SSA source, String suffix) => [
          for (final r in TypedBackend._banks[value(source).type])
            '${TypedBackend._registerNames[r]}$suffix',
        ];
        List<String> compareNames(String condition) => ['e${condition}AB'];
        lowered.add(switch (op) {
          async_ir.BeginAsync(:final runtimeTypeId) => make(
            ['rBeginAsync'],
            [],
            immediate: runtimeTypeId,
          ),
          flow.ReturnAsync(:final value) when value != null => make(
            ['rReturnAsync'],
            [value],
            terminal: true,
          ),
          flow.ReturnAsync(value: null) => make(
            ['returnAsyncNull'],
            [],
            terminal: true,
          ),
          exceptions.StoreExceptionSlot(:final slot, :final value) => make(
            bankNames(value, 'Spill'),
            [value],
            immediate: exceptionSlots[slot],
          ),
          exceptions.LoadExceptionSlot(:final slot, :final result) => make(
            bankNames(result, 'Reload'),
            [],
            immediate: exceptionSlots[slot],
          ),
          exceptions.LeaveTry() => make(['leaveTry'], []),
          exceptions.ResumeCompletion(:final terminal) => make(
            ['resumeCompletion'],
            [],
            terminal: terminal,
          ),
          exceptions.CaughtException() => make(['rCaughtException'], []),
          exceptions.CaughtStackTrace() => make(['rCaughtStackTrace'], []),
          flow.Throw(:final value) => make(['rThrow'], [value], terminal: true),
          flow.Rethrow(:final catchTarget) => make(
            ['rethrowCaught'],
            [],
            immediate: catchRegionIndices[catchTarget]!,
            terminal: true,
          ),
          flow.Assert(:final condition, :final errorMessage) => make(
            ['eAssertR'],
            [condition, errorMessage],
          ),
          NumericBinary(
            :final left,
            :final right,
            :final operandRepresentation,
            :final operator,
          ) =>
            make(b._numericNames(operandRepresentation, operator), [
              left,
              right,
            ]),
          IntToDouble(:final source) => make(
            ['fFromA', 'fFromB', 'gFromA', 'gFromB'],
            [source],
          ),
          memory.LoadInt(:final value) when value >= -32768 && value <= 32767 =>
            make(['aImmediate', 'bImmediate'], [], immediate: value & 65535),
          memory.LoadInt(:final value) => make(
            ['aConstant', 'bConstant'],
            [],
            immediate: b._integer(value),
          ),
          memory.LoadDouble(:final value) => make(
            ['fConstant', 'gConstant'],
            [],
            immediate: b._double(value),
          ),
          memory.LoadBool(:final value) => make(
            value ? ['eTrue'] : ['eFalse'],
            [],
          ),
          memory.LoadString(:final value) => make(
            ['rConstant', 'sConstant', 'cConstant'],
            [],
            immediate: b._object(value),
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
                for (final r in TypedBackend._banks[value(source).type])
                  '${target}Box${TypedBackend._registerNames[r].toUpperCase()}',
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
              [string, ?argument],
            ),
          collection.NewList() => make(['cNewList'], []),
          collection.NewRecord(
            :final fields,
            :final fieldIndices,
            :final typeId,
            :final reify,
          ) =>
            make(
              ['rCreateRecord'],
              [fields],
              immediate: b.context.constantPool.addOrGet([
                fieldIndices,
                typeId,
                if (reify) 1 else 0,
              ]),
            ),
          types_ir.LoadConstantType(:final typeId) => make(
            ['rLoadType'],
            [],
            immediate: typeId,
          ),
          types_ir.LoadTypeParameter(:final typeId) => make(
            ['rLoadTypeParameter'],
            [],
            immediate: typeId,
          ),
          types_ir.ResolveTypeId(:final typeId) => make(
            ['aResolveType'],
            [],
            immediate: typeId,
          ),
          types_ir.SetTypeEnvironment(:final typeId) => make(
            ['aSetTypeEnvironment'],
            [typeId],
          ),
          types_ir.LoadRuntimeType(:final object) => make(
            ['rRuntimeType'],
            [object],
          ),
          types_ir.AssertType(:final object, :final typeId) => make(
            ['rAssertType'],
            [object],
            immediate: typeId,
          ),
          collection.NewMap() => make(['cNewMap'], []),
          collection.NewSet() => make(['cNewSet'], []),
          collection.IndexMap(:final map, :final key) => make(
            ['rMapIndexCS'],
            [map, key],
          ),
          collection.MapSet(:final map, :final key, :final value) => make(
            ['mapSetCSR'],
            [map, key, value],
          ),
          collection.SetAdd(:final set, :final value) => make(
            ['setAddCR'],
            [set, value],
          ),
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
          primitives.BoxList(:final source, :final runtimeTypeId) =>
            runtimeTypeId == null
                ? make(['rBoxList'], [source])
                : make(['rBoxListTyped'], [source], immediate: runtimeTypeId),
          primitives.BoxMap(:final source, :final runtimeTypeId) => make(
            ['rBoxMap'],
            [source],
            immediate: runtimeTypeId,
          ),
          primitives.BoxSet(:final source, :final runtimeTypeId) => make(
            ['rBoxSet'],
            [source],
            immediate: runtimeTypeId,
          ),
          objects_ir.CreateClass(
            :final library,
            :final name,
            :final $super,
            :final runtimeTypeDescriptor,
          ) =>
            make(
              ['rCreateClassRA'],
              [$super, runtimeTypeDescriptor],
              immediate: b._classIndices[(library, name)],
            ),
          objects_ir.LoadUninitializedField() => make([
            'rUninitializedField',
          ], []),
          objects_ir.LoadPropertyStatic(
            :final object,
            :final index,
            :final isLate,
          ) =>
            make(
              [isLate ? 'rLoadLatePropertyR' : 'rLoadPropertyR'],
              [object],
              immediate: index,
            ),
          objects_ir.SetPropertyStatic(
            :final object,
            :final index,
            :final value,
            :final isLateFinal,
          ) =>
            make(
              [isLateFinal ? 'setLateFinalPropertyRS' : 'setPropertyRS'],
              [object, value],
              immediate: index,
            ),
          objects_ir.LoadSuper(:final object) => make(
            ['rLoadSuperR'],
            [object],
          ),
          objects_ir.LoadThis(:final object) => make(['rLoadThisR'], [object]),
          objects_ir.DynamicEquals(:final left, :final right) => make(
            ['eEqRS'],
            [left, right],
          ),
          memory.IsNull(:final object) => make(
            [
              for (final r in ['R', 'S', 'C']) 'eIsNull$r',
            ],
            [object],
          ),
          objects_ir.InternConst(:final value, :final typeId) => make(
            [
              for (final r in ['R', 'S', 'C']) 'eInternConst$r',
            ],
            [value],
            immediate: typeId,
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
          alu.Negate(:final source) => make(
            ['aNegate', 'bNegate', 'fNegate', 'gNegate'],
            [source],
          ),
          logic.LogicalNot(:final source) => make(['eNot'], [source]),
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
            ['jumpEFalse'],
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
  }

  /// Fuses comparison + conditional branch pairs into single fused branches.
  void fuseComparisonBranches() {
    // Fuse only adjacent pure comparisons whose entire SSA lifetime ends at
    // this branch. Count uses across all blocks, including phi edge inputs.
    final uses = <cfg.SSA, int>{};
    final definitions = <cfg.SSA, int>{};
    for (final blockId in graph.graph.vertices) {
      for (final op in graph[blockId]!.code) {
        final reads = {
          ...op.readsFrom,
          if (op is cfg.PhiNode) ...op.incoming.values,
        };
        for (final input in reads) {
          uses.update(input, (count) => count + 1, ifAbsent: () => 1);
        }
        final output = op.writesTo;
        if (output != null) {
          definitions.update(output, (count) => count + 1, ifAbsent: () => 1);
        }
      }
    }
    final comparisonName = RegExp(r'^e(Eq|Ne|Lt|Lte|Gt|Gte)(AB|FG)$');
    for (final blockId in graph.graph.vertices) {
      final code = graph[blockId]!.code;
      if (code.length < 2) continue;
      final branch = code.last;
      if (branch is! TypedOperation ||
          !branch.isConditionalBranch ||
          branch.inputs.length != 1 ||
          !branch.codes.every((opcode) => opcode == TypedOp.jumpEFalse)) {
        continue;
      }
      final successors = graph.graph.successorsOf(blockId).toSet();
      if (successors.length != 2 ||
          branch.immediate == branch.otherTarget ||
          !successors.contains(branch.immediate) ||
          !successors.contains(branch.otherTarget)) {
        continue;
      }
      var condition = branch.inputs.single;
      var comparisonIndex = code.length - 2;
      var comparison = code[comparisonIndex];
      var negated = false;
      if (comparison is TypedOperation &&
          comparison.codes.isNotEmpty &&
          comparison.codes.every((opcode) => opcode == TypedOp.eNot)) {
        if (comparisonIndex == 0 ||
            comparison.result != condition ||
            comparison.inputs.length != 1 ||
            comparison.terminal ||
            comparison.clobbers.isNotEmpty ||
            comparison.fixedVariant != null ||
            uses[condition] != 1 ||
            definitions[condition] != 1) {
          continue;
        }
        condition = comparison.inputs.single;
        comparison = code[--comparisonIndex];
        negated = true;
      }
      if (comparison is! TypedOperation ||
          comparison.result == null ||
          comparison.result != condition ||
          comparison.inputs.length != 2 ||
          comparison.terminal ||
          comparison.clobbers.isNotEmpty ||
          comparison.fixedVariant != null ||
          uses[condition] != 1 ||
          definitions[condition] != 1) {
        continue;
      }
      final fusedNames = <String>{};
      for (final opcode in comparison.codes) {
        final spec = TypedOp.instructions[opcode];
        final match = comparisonName.firstMatch(spec.name);
        if (match == null || spec.mayThrow || spec.terminates) {
          fusedNames.clear();
          break;
        }
        fusedNames.add('jumpNot${match[1]}${match[2]}');
      }
      if (fusedNames.isEmpty ||
          !fusedNames.every(TypedBackend._codes.containsKey)) {
        continue;
      }
      // Negation swaps the CFG edges, never the numerical predicate. In
      // particular, !(a < b) cannot become a >= b when either input is NaN.
      code.removeRange(comparisonIndex, code.length);
      code.add(
        TypedOperation(
          b._named(fusedNames.toList()),
          null,
          comparison.inputs,
          immediate: negated ? branch.otherTarget : branch.immediate,
          otherTarget: negated ? branch.immediate : branch.otherTarget,
          terminal: true,
        ),
      );
    }
  }

  /// Runs register allocation, block layout, branch relaxation, and byte
  /// emission. Returns the assembled function code.
  _FunctionCode emit() {
    for (var bank = 0; bank < 4; bank++) {
      graph.registerRegType(
        bank,
        cfg.RegType(bank, 'bank$bank', {
          cfg.RegisterGroup(TypedBackend._banks[bank].toSet()),
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
    graph.removePhiNodes(
      cfg.Assign.new,
      onSplitEdge: (pred, old, replacement) {
        final code = graph[pred]!.code;
        for (var i = 0; i < code.length; i++) {
          final op = code[i];
          if (op is TypedOperation && op.terminal) {
            if (op.codes.contains(TypedBackend._codes['completeJump'])) {
              final jump = b._completionJumps[op.immediate!];
              if (jump.target == old) {
                b._completionJumps[op.immediate!] = TypedCompletionJump(
                  jump.functionId,
                  replacement,
                  jump.targetDepth,
                );
              }
              continue;
            }
            if (!op.codes.any(
              (code) =>
                  TypedOp.instructions[code].immediate == TypedImmediate.branch,
            )) {
              continue;
            }
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
      slot += exceptionSlotCounts[variable.type];
      if (slot + 1 > spillCounts[variable.type]) {
        spillCounts[variable.type] = slot + 1;
      }
      return _Bytes(
        TypedBackend
            ._codes['${TypedBackend._registerNames[variable.register]}${reload ? 'Reload' : 'Spill'}']!,
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
                TypedBackend
                    ._codes['${TypedBackend._registerNames[target.register]}From${TypedBackend._registerNames[source.register].toUpperCase()}']!,
              ),
        onSwap: (a, b, _) {
          final regs = [a.register, b.register]..sort();
          return _Bytes(
            TypedBackend
                ._codes['${TypedBackend._registerNames[regs[0]]}${TypedBackend._registerNames[regs[1]].toUpperCase()}Swap']!,
          );
        },
        onJump: (target, _) => _Bytes(TypedOp.jump, target),
      ),
    );

    // Expand the second edge before relaxation so both branch distances use
    // the final instruction positions. Every branch starts short and can only
    // widen, guaranteeing that this layout process terminates.
    final assembled = _layoutBlocks({
      for (final block in blocks.entries)
        block.key: <_Bytes>[
          for (final instruction in block.value.cast<_Bytes>()) ...[
            if (instruction.code >= 0)
              _Bytes(instruction.code, instruction.immediate),
            if (instruction.otherTarget != null)
              _Bytes(TypedOp.jump, instruction.otherTarget),
          ],
        ],
    });
    final shortToLong = <int, int>{};
    for (final block in assembled.values) {
      for (final instruction in block) {
        final spec = TypedOp.instructions[instruction.code];
        if (spec.immediate == TypedImmediate.branch) {
          final short = TypedBackend._codes['${spec.name}Short']!;
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
    for (var index = firstRegion; index < b._exceptionRegions.length; index++) {
      final region = b._exceptionRegions[index];
      b._exceptionRegions[index] = TypedExceptionRegion(
        region.functionId,
        catchTarget: region.catchTarget < 0 ? -1 : offsets[region.catchTarget]!,
        finallyTarget: region.finallyTarget < 0
            ? -1
            : offsets[region.finallyTarget]!,
      );
    }
    for (
      var index = firstCompletion;
      index < b._completionJumps.length;
      index++
    ) {
      final jump = b._completionJumps[index];
      b._completionJumps[index] = TypedCompletionJump(
        jump.functionId,
        offsets[jump.target]!,
        jump.targetDepth,
      );
    }
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

/// [TypeRef.fromAnnotation] that tolerates annotations referencing the
/// callee's own type parameters, which aren't resolvable at emit time.
TypeRef? _tryAnnotationType(
  CompilerContext ctx,
  int library,
  TypeAnnotation annotation,
) {
  try {
    return TypeRef.fromAnnotation(ctx, library, annotation);
  } on CompileError {
    return null;
  }
}
