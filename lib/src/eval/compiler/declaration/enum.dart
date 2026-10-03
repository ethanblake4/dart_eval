import 'package:control_flow_graph/control_flow_graph.dart';
import 'class.dart' show collectMixinMembers;
import '../invocation/binder.dart';
import '../invocation/bound_call.dart';
import '../invocation/targets.dart';
import '../member/call_signature.dart';
import '../helpers/const.dart';
import '../helpers/global.dart';
import '../helpers/constructor_type.dart';
import '../helpers/default_value.dart';
import '../errors.dart';
import '../values/value_rep.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import '../invocation/deferred.dart';
import '../member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/ir/string.dart';

final _resolvingEnumValues = Expando<Set<int>>();

/// Resolves a constant's instantiation even when its enum follows the caller.
TypeRef resolveEnumValueType(CompilerContext ctx, TypeRef type, String name) {
  if (nominalDeclOf(type)!.typeParameters.isEmpty) return type;
  final index = ctx.enumValueIndices[type.file]![type.name]![name]!;
  if (!ctx.runtimeGlobalInitializerMap.containsKey(index)) {
    final declaration =
        ctx.topLevelDeclarationsMap[type.file]![type.name]!.declaration
            as EnumDeclaration;
    final constantIndex = declaration.body.constants.indexWhere(
      (constant) => constant.name.lexeme == name,
    );
    final constant = declaration.body.constants[constantIndex];
    final active = _resolvingEnumValues[ctx] ??= {};
    if (!active.add(index)) {
      throw CompileError('Cyclic enum constant ${type.name}.$name', constant);
    }
    final outer = NestedFunctionState(ctx);
    try {
      ctx.blockCode = [];
      ctx.labels.clear();
      ctx.caughtExceptionTargets.clear();
      ctx.exceptionDepth = 0;
      ctx.finishMethod();
      withDefaultExpressionScope(ctx, type.file, constant, () {
        ctx.withTypeParameters(
          type.file,
          TypeParameterOwner(
            TypeParameterOwnerKind.classLike,
            type.file,
            type.name,
          ),
          declaration.namePart.typeParameters?.typeParameters,
          () =>
              _compileEnumValue(ctx, type, type.name, constant, constantIndex),
        );
        ctx.finishMethod();
      });
    } finally {
      active.remove(index);
      outer.restore();
    }
  }
  return ctx.topLevelVariableInferredTypes[type.file]!['${type.name}.$name']!;
}

void compileEnumDeclaration(CompilerContext ctx, EnumDeclaration d) =>
    ctx.withTypeParameters(
      ctx.library,
      TypeParameterOwner(
        TypeParameterOwnerKind.classLike,
        ctx.library,
        d.namePart.typeName.lexeme,
      ),
      d.namePart.typeParameters?.typeParameters,
      () => _compileEnumDeclaration(ctx, d),
    );

void _compileEnumDeclaration(CompilerContext ctx, EnumDeclaration d) {
  final type = TypeRef.lookupDeclaration(ctx, ctx.library, d);
  final clsName = d.namePart.typeName.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = {
    MemberKind.getter: {},
    MemberKind.setter: {},
    MemberKind.method: {},
  };
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};
  final (constructors, fields, methods) = partitionClassMembers(d.body.members);
  final (mixinFields, mixinMethods, memberLibraries) = collectMixinMembers(
    ctx,
    d.withClause?.mixinTypes,
  );
  fields.insertAll(0, mixinFields);
  methods.insertAll(0, mixinMethods);
  final previousEnclosingLibrary = ctx.enclosingLibrary;
  ctx.enclosingLibrary = ctx.library;

  // Enum values materialize through the generative constructor, which is
  // implicit when the enum declares none (factories don't count).
  if (!constructors.any((c) => c.factoryKeyword == null)) {
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields, memberLibraries: memberLibraries);
  }

  _compileEnumFieldGetter(ctx, clsName, 'index', 0);
  _compileEnumFieldGetter(ctx, clsName, 'name', 1);
  _compileEnumFieldGetter(ctx, clsName, 'dart:core::_name', 1);
  ctx.enumBaseToStringOffsets[(ctx.library, clsName)] = _compileEnumToString(
    ctx,
    clsName,
    register: !methods.any((m) => m.name.lexeme == 'toString'),
  );

  // Every enum value carries two synthetic instance fields (`index` and
  // `name`) at slots 0 and 1; user-declared fields follow them.
  compileClassMembers(
    ctx,
    d,
    constructors: constructors,
    fields: fields,
    methods: methods,
    firstFieldIndex: 2,
    memberLibraries: memberLibraries,
  );

  var idx = 0;
  for (final constant in d.body.constants) {
    _compileEnumValue(ctx, type, clsName, constant, idx);
    idx++;
  }
  _compileEnumValues(ctx, type);

  ctx.enclosingLibrary = previousEnclosingLibrary;
  ctx.currentClass = null;
}

/// Registers the synthesized const list before its initializer is compiled.
/// Generic enums use their bounds, independently of the accessing type literal.
int ensureEnumValuesRegistered(CompilerContext ctx, TypeRef type) {
  final name = '${type.name}.values';
  ensureGlobalRegistered(ctx, type.file, name);
  final index = ctx.topLevelGlobalIndices[type.file]![name]!;
  final declaration = ctx.types.find(type.file, type.name)!;
  ctx.topLevelVariableInferredTypes[type.file]![name] = CoreTypes.list
      .ref(ctx)
      .copyWith(
        arguments: [declaration.instantiate(declaration.defaultTypeArguments)],
      );
  ctx.globalRepresentations[index] = MachineRepresentation.object;
  ctx.globalsFinal.add(index);
  ctx.globalsConst.add(index);
  ctx.globalNames[index] = name;
  return index;
}

void _compileEnumValues(CompilerContext ctx, TypeRef type) {
  final index = ensureEnumValuesRegistered(ctx, type);
  final pos = ctx.beginFunction('${type.name}.values*i');
  ctx.functionSignatures[pos] = const MachineFunctionSignature(
    [],
    MachineRepresentation.object,
  );
  final listType =
      ctx.topLevelVariableInferredTypes[type.file]!['${type.name}.values']!;
  final values = Variable.ssa(
    ctx,
    NewList(ctx.svar('enum_values')),
    listType,
    rep: ValueRep.nativeList,
  );
  for (final entry in ctx.enumValueIndices[type.file]![type.name]!.entries) {
    final value = ctx.svar(entry.key);
    ctx.pushOp(LoadGlobal(value, entry.value));
    ctx.pushOp(ListAppend(values.ssa, value));
  }
  final list = internConst(ctx, values, listType).boxIfNeeded(ctx);
  ctx.runtimeGlobalInitializerMap[index] = pos;
  ctx.pushOp(Return(list.ssa));
}

/// Generates the trivial `index`/`name` getter: `return this.<field>`.
void _compileEnumFieldGetter(
  CompilerContext ctx,
  String clsName,
  String fieldName,
  int fieldIndex,
) {
  final pos = ctx.beginFunction('$clsName.$fieldName (get)');
  ctx.functionSignatures[pos] = const MachineFunctionSignature([
    MachineRepresentation.object,
  ], MachineRepresentation.object);
  final receiver = SSA('arg_0');
  ctx.pushOp(Parameter(receiver, 0));
  final value = ctx.svar('enum_$fieldName');
  ctx.pushOp(LoadPropertyStatic(value, receiver, fieldIndex));
  ctx.pushOp(Return(value));
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![MemberKind
          .getter]![fieldName] =
      pos;
  ctx.instanceGetterIndices[ctx.library]![clsName]![fieldName] = fieldIndex;
}

/// Generates a synthetic `toString` returning `'EnumClass.valueName'`, used
/// when the enum does not declare its own.
int _compileEnumToString(
  CompilerContext ctx,
  String clsName, {
  required bool register,
}) {
  final pos = ctx.beginFunction('$clsName.toString');
  ctx.functionSignatures[pos] = const MachineFunctionSignature([
    MachineRepresentation.object,
  ], MachineRepresentation.object);
  final receiver = SSA('arg_0');
  ctx.pushOp(Parameter(receiver, 0));
  final name = ctx.svar('enum_name');
  ctx.pushOp(LoadPropertyStatic(name, receiver, 1));
  final nameUnboxed = ctx.svar('enum_name_unboxed');
  ctx.pushOp(Unbox(nameUnboxed, name, MachineRepresentation.string));
  final prefix = BuiltinValue(stringval: '$clsName.').push(ctx);
  final result = ctx.svar('enum_toString');
  ctx.pushOp(
    StringOperation(
      result,
      StringOperator.concatenate,
      prefix.ssa,
      nameUnboxed,
    ),
  );
  final boxed = ctx.svar('enum_toString_boxed');
  ctx.pushOp(BoxString(boxed, result));
  ctx.pushOp(Return(boxed));
  if (register) {
    ctx.instanceDeclarationPositions[ctx.library]![clsName]![MemberKind
            .method]!['toString'] =
        pos;
  }
  return pos;
}

/// Generates the initializer function for one enum constant: invokes the
/// selected constructor with the synthetic `index`/`name` arguments followed
/// by any source-level arguments, and registers the result as a final global.
void _compileEnumValue(
  CompilerContext ctx,
  TypeRef type,
  String clsName,
  EnumConstantDeclaration constant,
  int valueIndex,
) {
  final cName = constant.name.lexeme;
  final name = '$clsName.$cName';
  final index = ctx.topLevelGlobalIndices[ctx.library]![name]!;
  if (ctx.runtimeGlobalInitializerMap.containsKey(index)) return;

  final pos = ctx.beginFunction('$cName*i');
  ctx.functionSignatures[pos] = const MachineFunctionSignature(
    [],
    MachineRepresentation.object,
  );
  final selector = constant.arguments?.constructorSelector?.name.name;
  final cstrName = selector == 'new' ? '' : selector ?? '';
  final offset = DeferredOrOffset.lookupStatic(
    ctx,
    ctx.library,
    clsName,
    cstrName,
  );

  final cstr =
      ctx.topLevelDeclarationsMap[offset.file]![offset.name ?? '$clsName.'];

  final vIndex = BuiltinValue(intval: valueIndex).push(ctx).boxIfNeeded(ctx);
  final vName = BuiltinValue(stringval: cName).push(ctx).boxIfNeeded(ctx);

  final dec = cstr?.declaration;
  final constructor = dec is ConstructorDeclaration ? dec : null;
  final explicitArguments = constant.arguments?.typeArguments;
  final instantiatedType = explicitArguments == null
      ? null
      : (type as InterfaceTypeRef).copyWith(
          arguments: [
            for (final argument in explicitArguments.arguments)
              TypeRef.fromAnnotation(ctx, ctx.library, argument),
          ],
        );
  final target = ConstructorCall(
    staticType: type,
    instantiatedType: instantiatedType,
    offset: offset,
    constructor: constructor,
    implicitDefault: constructor == null,
    leadingArguments: [vIndex.ssa, vName.ssa],
    signature: constructor == null
        ? null
        : CallSignature.forDeclaration(ctx, ctx.library, constructor),
  );
  final BoundCall? bound;
  if (constructor == null) {
    bound = null;
  } else if (constant.arguments case final arguments?) {
    bound = ArgumentBinder(ctx).bindSourceTarget(
      target,
      arguments.argumentList,
      typeArguments: explicitArguments,
      source: constant,
    );
  } else {
    // `a` uses the selected constructor's optional defaults just as `a()`
    // does, although it has no ArgumentList node to pass to bindSourceTarget.
    bound = ArgumentBinder(ctx).bindDeclaration(
      ctx.library,
      constructor,
      null,
      targetSignature: target.signature,
      source: constant,
      fillOmitted: target.policy == BindingPolicy.callerFillsDefaults,
    );
  }
  final V = target.emit(
    ctx,
    BoundCall(
      positional: bound?.positional ?? const [],
      named: bound?.named ?? const [],
      vectorOverride: bound?.vector(),
      returnType: bound == null
          ? type
          : inferredConstructorType(
              ctx,
              instantiatedType ?? type,
              nominalDeclOf(type)!.typeParameters,
              bound.typeArguments,
            ),
    ),
  );
  ctx.globalRepresentations[index] = MachineRepresentation.object;
  ctx.globalsFinal.add(index);
  ctx.globalNames[index] = name;
  ctx.topLevelVariableInferredTypes[ctx.library]![name] = V.type;
  ctx.runtimeGlobalInitializerMap[index] = pos;
  ctx.pushOp(Return(V.ssa));
}
