import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/ir/string.dart';

void compileEnumDeclaration(
  CompilerContext ctx,
  EnumDeclaration d, {
  bool statics = false,
}) {
  final type = TypeRef.lookupDeclaration(ctx, ctx.library, d);
  final $runtimeType = ctx.typeRefIndexMap[type];
  final clsName = d.name.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType,
  ];
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};
  final constructors = <ConstructorDeclaration>[];
  final fields = <FieldDeclaration>[];
  final methods = <MethodDeclaration>[];
  for (final m in d.members) {
    if (m is ConstructorDeclaration) {
      constructors.add(m);
    } else if (m is FieldDeclaration) {
      if (!m.isStatic) {
        fields.add(m);
      }
    } else {
      m as MethodDeclaration;
      methods.add(m);
    }
  }
  var i = 0;
  if (constructors.isEmpty) {
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }

  final pos = ctx.beginFunction('$clsName.index (get)');
  ctx.functionSignatures[pos] = const MachineFunctionSignature([
    MachineRepresentation.object,
  ], MachineRepresentation.object);
  final receiver = SSA('arg_0');
  ctx.pushOp(Parameter(receiver, 0));
  final enumIndex = ctx.svar('enum_index');
  ctx.pushOp(LoadPropertyStatic(enumIndex, receiver, 0));
  ctx.pushOp(Return(enumIndex));
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![0]['index'] = pos;
  ctx.instanceGetterIndices[ctx.library]![clsName]!['index'] = 0;

  final namePos = ctx.beginFunction('$clsName.name (get)');
  ctx.functionSignatures[namePos] = const MachineFunctionSignature([
    MachineRepresentation.object,
  ], MachineRepresentation.object);
  final nameReceiver = SSA('arg_0');
  ctx.pushOp(Parameter(nameReceiver, 0));
  final enumName = ctx.svar('enum_name');
  ctx.pushOp(LoadPropertyStatic(enumName, nameReceiver, 1));
  ctx.pushOp(Return(enumName));
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![0]['name'] = namePos;
  ctx.instanceGetterIndices[ctx.library]![clsName]!['name'] = 1;

  if (!methods.any((m) => m.name.lexeme == 'toString')) {
    final toStringPos = ctx.beginFunction('$clsName.toString');
    ctx.functionSignatures[toStringPos] = const MachineFunctionSignature(
      [MachineRepresentation.object],
      MachineRepresentation.object,
    );
    final tsReceiver = SSA('arg_0');
    ctx.pushOp(Parameter(tsReceiver, 0));
    final tsName = ctx.svar('enum_name');
    ctx.pushOp(LoadPropertyStatic(tsName, tsReceiver, 1));
    final tsNameUnboxed = ctx.svar('enum_name_unboxed');
    ctx.pushOp(Unbox(tsNameUnboxed, tsName, MachineRepresentation.string));
    final tsPrefix = BuiltinValue(stringval: '$clsName.').push(ctx);
    final tsResult = ctx.svar('enum_toString');
    ctx.pushOp(
      StringOperation(
        tsResult,
        StringOperator.concatenate,
        tsPrefix.ssa,
        tsNameUnboxed,
      ),
    );
    final tsBoxed = ctx.svar('enum_toString_boxed');
    ctx.pushOp(BoxString(tsBoxed, tsResult));
    ctx.pushOp(Return(tsBoxed));
    ctx.instanceDeclarationPositions[ctx.library]![clsName]![2]['toString'] =
        toStringPos;
  }
  i++;
  i++;

  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.currentClass = d;
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.variables.length;
    }
  }

  var idx = 0;
  for (final constant in d.constants) {
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

    final vIndex = BuiltinValue(intval: idx).push(ctx).boxIfNeeded(ctx);
    final vName = BuiltinValue(stringval: cName).push(ctx).boxIfNeeded(ctx);

    final arguments = <SSA>[vIndex.ssa, vName.ssa];

    final dec = cstr?.declaration;
    if (constant.arguments != null && dec != null) {
      final fpl = (dec as ConstructorDeclaration).parameters.parameters;
      final result = compileArgumentList(
        ctx,
        constant.arguments!.argumentList,
        ctx.library,
        fpl,
        dec,
        source: constant,
      );
      arguments.addAll(result.ssa);
    }
    arguments.add(BuiltinValue(intval: type.runtimeTypeId(ctx)).push(ctx).ssa);

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
    idx++;
  }

  ctx.currentClass = null;
}
