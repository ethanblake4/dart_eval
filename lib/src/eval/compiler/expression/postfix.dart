import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/assert.dart';
import 'package:dart_eval/src/eval/compiler/helpers/equality.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

Variable compilePostfixExpression(PostfixExpression e, CompilerContext ctx) {
  if (e.operator.type == TokenType.BANG) {
    // Null assertion (!)
    final L = compileExpression(e.operand, ctx);
    final result = checkNotNull(ctx, L);
    final msg =
        BuiltinValue(stringval: 'Null check operator used on a null value')
            .push(ctx);
    doAssert(ctx, result, msg);
    return L.copyWith(type: L.type.copyWith(nullable: false));
  }

  final V = compileExpressionAsReference(e.operand, ctx);
  final L = V.getValue(ctx);
  var out = L;

  out = Variable.alloc(ctx, L.type);
  ctx.pushOp(PushNull.make(), PushNull.LEN);
  ctx.pushOp(
      CopyValue.make(out.scopeFrameOffset, L.scopeFrameOffset), CopyValue.LEN);

  const opMap = {TokenType.PLUS_PLUS: '+', TokenType.MINUS_MINUS: '-'};

  if (!opMap.containsKey(e.operator.type)) {
    throw UnsupportedError('Unsupported postfix operator ${e.operator}');
  }

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
