import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compilePostfixExpression(PostfixExpression e, CompilerContext ctx) {
  final V = compileExpressionAsReference(e.operand, ctx);
  final L = V.getValue(ctx);
  var out = L;

  if (L.name != null) {
    out = Variable.alloc(ctx, L.type);
    ctx.pushOp(PushNull.make(), PushNull.LEN);
    ctx.pushOp(CopyValue.make(out.scopeFrameOffset, L.scopeFrameOffset),
        CopyValue.LEN);
  }

  const opMap = {TokenType.PLUS_PLUS: '+', TokenType.MINUS_MINUS: '-'};

  V.setValue(
    ctx,
    L.invoke(
      ctx,
      opMap[e.operator.type]!,
      [BuiltinValue(intval: 1).push(ctx)],
    ).result,
  );

  return out;
}
