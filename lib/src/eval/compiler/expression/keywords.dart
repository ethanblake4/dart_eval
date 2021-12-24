import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileThisExpression(ThisExpression e, CompilerContext ctx) {
  if (ctx.currentClass == null) {
    throw CompileError("Cannot use 'this' outside of a class context");
  }
  return Variable(0, ctx.visibleTypes[ctx.library]![ctx.currentClass!.name.name]!);
}

Variable compileSuperExpression(SuperExpression e, CompilerContext ctx) {
  if (ctx.currentClass == null) {
    throw CompileError("Cannot use 'super' outside of a class context");
  }

  var type = EvalTypes.objectType;
  final extendsClause = ctx.currentClass!.extendsClause;
  if (extendsClause != null) {
    type = ctx.visibleTypes[ctx.library]![extendsClause.superclass2.name.name]!;
  }

  ctx.pushOp(PushSuper.make(0), PushSuper.LEN);
  return Variable.alloc(ctx, type);
}