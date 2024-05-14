import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileThisExpression(ThisExpression e, CompilerContext ctx) {
  if (ctx.currentClass == null) {
    throw CompileError("Cannot use 'this' outside of a class context");
  }
  return ctx.lookupLocal('#this')!;
}

Variable compileSuperExpression(SuperExpression e, CompilerContext ctx) {
  if (ctx.currentClass == null || ctx.currentClass is! ClassDeclaration) {
    throw CompileError("Cannot use 'super' outside of a class context");
  }

  var type = CoreTypes.object.ref(ctx);
  final extendsClause = (ctx.currentClass as ClassDeclaration).extendsClause;
  if (extendsClause != null) {
    // ignore: deprecated_member_use
    type =
        ctx.visibleTypes[ctx.library]![extendsClause.superclass.name2.value()]!;
  }

  final $this = ctx.lookupLocal('#this')!;
  final v = Variable.ssa(ctx, LoadSuper(ctx.svar('super'), $this.ssa), type);
  return v;
}
