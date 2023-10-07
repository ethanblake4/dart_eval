import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/method_invocation.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileCascadeExpression(CascadeExpression e, CompilerContext ctx) {
  final target = compileExpression(e.target, ctx);
  for (final s in e.cascadeSections) {
    if (s is MethodInvocation) {
      compileMethodInvocation(ctx, s, cascadeTarget: target);
    } else {
      compileExpressionAndDiscardResult(s, ctx, cascadeTarget: target);
    }
  }
  return target;
}
