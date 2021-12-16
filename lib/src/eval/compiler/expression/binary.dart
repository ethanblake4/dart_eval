import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../../../../dart_eval.dart';
import '../errors.dart';
import 'expression.dart';

/// Compile a [BinaryExpression] to DBC bytecode
Variable compileBinaryExpression(CompilerContext ctx, BinaryExpression e) {
  var L = compileExpression(e.leftOperand, ctx);
  var R = compileExpression(e.rightOperand, ctx);

  // Unboxing justification:
  // We could choose to only unbox if at least one of the values is already unboxed,
  // but opportunistically unboxing now means we won't have to unbox in the future.
  // For performance sensitive code (with a lot of math) this is probably a better choice.

  // Fast path for basic int ops
  final supportedIntIntrinsicOps = {TokenType.PLUS};

  if (L.type == intType && supportedIntIntrinsicOps.contains(e.operator.type)) {
    L = L.unboxIfNeeded(ctx);
    R = R.unboxIfNeeded(ctx);

    if (e.operator.type == TokenType.PLUS) {
      // Integer intrinsic add
      ctx.pushOp(AddInts.make(L.scopeFrameOffset, R.scopeFrameOffset), AddInts.LEN);
      return Variable.alloc(ctx, intType, boxed: false);
    }
    throw CompileError('Internal error: Invalid intrinsic int op ${e.operator.type}');
  }

  // Slow path (universal)
  L = L.boxIfNeeded(ctx);
  R = R.boxIfNeeded(ctx);

  final opMap = {
    TokenType.PLUS: '+',
    TokenType.MINUS: '-',
    TokenType.SLASH: '/',
    TokenType.STAR: '*',
    TokenType.LT: '<'
  };

  var method = opMap[e.operator.type] ?? (throw CompileError('Unknown binary operator ${e.operator.type}'));

  final addendOp = PushArg.make(R.scopeFrameOffset);
  ctx.pushOp(addendOp, PushArg.LEN);

  final invokeOp = InvokeDynamic.make(L.scopeFrameOffset, method);
  ctx.pushOp(invokeOp, InvokeDynamic.len(invokeOp));

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final returnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(ctx, L.type, method, [R.type], {});

  return Variable.alloc(ctx, returnType?.type ?? dynamicType)..frameIndex = ctx.locals.length - 1;
}
