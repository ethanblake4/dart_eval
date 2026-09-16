import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';

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
    ctx.resetStack(position: 0);
    ctx.currentClass = d;
    compileDefaultConstructor(ctx, d, fields);
  }

  ctx.resetStack(position: 0);
  final pos = beginMethod(ctx, d, d.offset, '$clsName.index (get)');
  ctx.functionSignatures[pos] = const MachineFunctionSignature([
    MachineRepresentation.object,
  ], MachineRepresentation.object);
  final receiver = SSA('arg_0');
  ctx.pushOp(Parameter(receiver, 0));
  final enumIndex = ctx.svar('enum_index');
  ctx.pushOp(LoadPropertyStatic(enumIndex, receiver, 0));
  ctx.pushOp(Return(enumIndex));
  ctx.instanceDeclarationPositions[ctx.library]![clsName]![0]['index'] = pos;
  i++;
  i++;

  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.resetStack(
      position:
          m is ConstructorDeclaration || (m is MethodDeclaration && m.isStatic)
          ? 0
          : 1,
    );
    ctx.currentClass = d;
    compileDeclaration(m, ctx, parent: d, fieldIndex: i, fields: fields);
    if (m is FieldDeclaration) {
      i += m.fields.variables.length;
    }
  }

  var idx = 0;
  for (final constant in d.constants) {
    final cName = constant.name.lexeme;
    ctx.resetStack(position: 0);
    final pos = beginMethod(ctx, constant, constant.offset, '$cName*i');
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
    ctx.topLevelGlobalInitializers[ctx.library]![name] = pos;
    ctx.runtimeGlobalInitializerMap[index] = pos;
    ctx.pushOp(Return(V.ssa));
    idx++;
  }

  ctx.currentClass = null;
  ctx.resetStack();
}
