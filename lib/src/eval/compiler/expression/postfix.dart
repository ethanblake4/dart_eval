import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

Variable compilePostfixExpression(PostfixExpression e, CompilerContext ctx) {
  if (e.operator.type == TokenType.BANG) {
    // Null assertion (!)
    final L = compileExpression(e.operand, ctx);
    if (L.type.nullable ||
        L.type.resolveTypeChain(ctx) == CoreTypes.dynamic.ref(ctx)) {
      final boxed = L.boxIfNeeded(ctx, e.operand);
      ctx.pushOp(
        AssertType(boxed.ssa, CoreTypes.object.ref(ctx).runtimeTypeId(ctx)),
      );
    }
    return L.copyWith(type: L.type.copyWith(nullable: false));
  }

  final V = compileExpressionAsReference(e.operand, ctx);
  final L = V.getValue(ctx);
  final out = Variable.ssa(ctx, Assign(ctx.svar('operand'), L.ssa), L.type);

  const opMap = {TokenType.PLUS_PLUS: '+', TokenType.MINUS_MINUS: '-'};

  if (!opMap.containsKey(e.operator.type)) {
    throw UnsupportedError('Unsupported postfix operator ${e.operator}');
  }

  V.setValue(
    ctx,
    L.invoke(ctx, opMap[e.operator.type]!, [
      BuiltinValue(intval: 1).push(ctx),
    ]).result,
  );

  return out;
}
