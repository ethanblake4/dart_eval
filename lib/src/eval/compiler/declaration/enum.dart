import 'package:control_flow_graph/control_flow_graph.dart';
import '../invocation/binder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import '../invocation/bound_call.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/ir/string.dart';

void compileEnumDeclaration(CompilerContext ctx, EnumDeclaration d) {
  final type = TypeRef.lookupDeclaration(ctx, ctx.library, d);
  final $runtimeType = ctx.runtimeTypes.indexMap[type.decl!];
  final clsName = d.namePart.typeName.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType,
  ];
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};
  final (constructors, fields, methods) = partitionClassMembers(d.body.members);
  // Enum values materialize through the generative constructor, which is
  // implicit when the enum declares none (factories don't count).
  if (!constructors.any((c) => c.factoryKeyword == null)) {
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }

  _compileEnumFieldGetter(ctx, clsName, 'index', 0);
  _compileEnumFieldGetter(ctx, clsName, 'name', 1);
  if (!methods.any((m) => m.name.lexeme == 'toString')) {
    _compileEnumToString(ctx, clsName);
  }

  // Every enum value carries two synthetic instance fields (`index` and
  // `name`) at slots 0 and 1; user-declared fields follow them.
  compileClassMembers(
    ctx,
    d,
    constructors: constructors,
    fields: fields,
    methods: methods,
    firstFieldIndex: 2,
  );

  var idx = 0;
  for (final constant in d.body.constants) {
    _compileEnumValue(ctx, type, clsName, constant, idx);
    idx++;
  }

  ctx.currentClass = null;
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
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![0][fieldName] = pos;
  ctx.instanceGetterIndices[ctx.library]![clsName]![fieldName] = fieldIndex;
}

/// Generates a synthetic `toString` returning `'EnumClass.valueName'`, used
/// when the enum does not declare its own.
void _compileEnumToString(CompilerContext ctx, String clsName) {
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
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![2]['toString'] = pos;
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

  final pos = ctx.beginFunction('$cName*i');
  ctx.functionSignatures[pos] = const MachineFunctionSignature(
    [],
    MachineRepresentation.object,
  );
  final cstrName = constant.arguments?.constructorSelector?.name.name ?? '';
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

  final arguments = <SSA>[vIndex.ssa, vName.ssa];

  final dec = cstr?.declaration;
  if (constant.arguments != null && dec != null) {
    final fpl = (dec as ConstructorDeclaration).parameters.parameters;
    final result = ArgumentBinder(ctx).bindParameterList(
      constant.arguments!.argumentList,
      ctx.library,
      fpl,
      dec,
      source: constant,
    options: BindingOptions.source,
);






    arguments.addAll(result.vector());
  }
  arguments.add(pushRuntimeTypeId(ctx, type));

  final V = Variable.ssa(
    ctx,
    Call(offset, arguments, result: ctx.svar('enum_value')),
    type,
  );
  final name = '$clsName.$cName';
  final index = ctx.topLevelGlobalIndices[ctx.library]![name]!;
  ctx.globalRepresentations[index] = MachineRepresentation.object;
  ctx.globalsFinal.add(index);
  ctx.globalNames[index] = name;
  ctx.topLevelVariableInferredTypes[ctx.library]![name] = type;
  ctx.runtimeGlobalInitializerMap[index] = pos;
  ctx.pushOp(Return(V.ssa));
}
