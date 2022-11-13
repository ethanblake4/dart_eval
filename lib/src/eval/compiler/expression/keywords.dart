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
  return ctx.lookupLocal('#this')!;
}

Variable compileSuperExpression(SuperExpression e, CompilerContext ctx) {
  if (ctx.currentClass == null) {
    throw CompileError("Cannot use 'super' outside of a class context");
  }

  var type = EvalTypes.objectType;
  final extendsClause = ctx.currentClass!.extendsClause;
  if (extendsClause != null) {
    // ignore: deprecated_member_use
    type = ctx.visibleTypes[ctx.library]![extendsClause.superclass.name.name]!;
  }

  final $this = ctx.lookupLocal('#this')!;
  ctx.pushOp(PushSuper.make($this.scopeFrameOffset), PushSuper.LEN);
  final v = Variable.alloc(ctx, type);
  return v;
}
