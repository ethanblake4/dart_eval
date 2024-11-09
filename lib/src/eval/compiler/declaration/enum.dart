import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/scope.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/globals.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/shared/registers.dart';

void compileEnumDeclaration(CompilerContext ctx, EnumDeclaration d,
    {bool statics = false}) {
  final type = TypeRef.lookupDeclaration(ctx, ctx.library, d);
  final $runtimeType = ctx.typeRefIndexMap[type];
  final clsName = d.name.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType
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
  final object =
      Variable.ssa(ctx, AssignRegister(ctx.svar('this'), regGPR3), type);
  final prop = Variable.ssa(
      ctx, LoadPropertyStatic(ctx.svar('index'), object.ssa, 0), type);
  ctx.pushOp(Return(prop.ssa));
  i++;
  i++;

  for (final m in <ClassMember>[...fields, ...methods, ...constructors]) {
    ctx.resetStack(
        position: m is ConstructorDeclaration ||
                (m is MethodDeclaration && m.isStatic)
            ? 0
            : 1);
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
    final cstrName = constant.arguments?.constructorSelector?.name.name ?? '';
    final method = IdentifierReference(null, d.name.lexeme).getValue(ctx);
    final offset = method.methodOffset ??
        (throw CompileError(
            'Cannot instantiate enum $clsName (no valid constructor $cstrName)'));

    final cstr =
        ctx.topLevelDeclarationsMap[offset.file]![offset.name ?? '$clsName.'];

    final vIndex =
        BuiltinValue(intval: idx).push(ctx, ctx.svar('vidx')).boxIfNeeded(ctx);
    final vName = BuiltinValue(stringval: cName).push(ctx, ctx.svar('vname'));

    final ssa = [vIndex.ssa, vName.ssa];
    final dec = cstr?.declaration;
    if (constant.arguments != null && dec != null) {
      final fpl = (dec as ConstructorDeclaration).parameters.parameters;
      ssa.addAll(compileArgumentList(
              ctx, constant.arguments!.argumentList, ctx.library, fpl, dec,
              source: constant)
          .ssa
          .map((name) => SSA(name)));
    }

    ctx.pushOp(Call(offset, ssa));
    final V = Variable.ssa(ctx, AssignRegister(ctx.svar(cName), regGPR1), type);
    final _name = '$clsName.$cName';
    final _index = ctx.topLevelGlobalIndices[ctx.library]![_name]!;
    ctx.pushOp(SetGlobal(_index, V.ssa));
    ctx.topLevelVariableInferredTypes[ctx.library]![_name] = type;
    ctx.pushOp(Return(V.ssa));
    idx++;
  }

  ctx.currentClass = null;
  ctx.resetStack();
}
