import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

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

  // Fast path for basic num ops
  final supportedNumIntrinsicOps = {TokenType.PLUS, TokenType.LT, TokenType.GT};

  var LeqR = false;
  if (R.scopeFrameOffset == L.scopeFrameOffset) {
    LeqR = true;
  }

  if (L.type.isAssignableTo(EvalTypes.numType) && supportedNumIntrinsicOps.contains(e.operator.type)) {
    L = L.unboxIfNeeded(ctx);
    if (LeqR) {
      R = L;
    } else {
      R = R.unboxIfNeeded(ctx);
    }

    if (e.operator.type == TokenType.PLUS) {
      // Num intrinsic add
      ctx.pushOp(NumAdd.make(L.scopeFrameOffset, R.scopeFrameOffset), NumAdd.LEN);
      return Variable.alloc(ctx, EvalTypes.intType, boxed: false);
    } else if (e.operator.type == TokenType.LT) {
      // Num intrinsic less than
      ctx.pushOp(NumLt.make(L.scopeFrameOffset, R.scopeFrameOffset), NumLt.LEN);
      return Variable.alloc(ctx, EvalTypes.boolType, boxed: false);
    } else if (e.operator.type == TokenType.GT) {
      // Num intrinsic greater than
      ctx.pushOp(NumGt.make(L.scopeFrameOffset, R.scopeFrameOffset), NumGt.LEN);
      return Variable.alloc(ctx, EvalTypes.boolType, boxed: false);
    }
    throw CompileError('Internal error: Invalid intrinsic int op ${e.operator.type}');
  }

  // Slow path (universal)
  L = L.boxIfNeeded(ctx);

  if (LeqR) {
    R = L;
  } else {
    R = R.boxIfNeeded(ctx);
  }


  final opMap = {
    TokenType.PLUS: '+',
    TokenType.MINUS: '-',
    TokenType.SLASH: '/',
    TokenType.STAR: '*',
    TokenType.LT: '<',
    TokenType.GT: '>'
  };

  var method = opMap[e.operator.type] ?? (throw CompileError('Unknown binary operator ${e.operator.type}'));

  final addendOp = PushArg.make(R.scopeFrameOffset);
  ctx.pushOp(addendOp, PushArg.LEN);

  final invokeOp = InvokeDynamic.make(L.scopeFrameOffset, method);
  ctx.pushOp(invokeOp, InvokeDynamic.len(invokeOp));

  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final returnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(ctx, L.type, method, [R.type], {});

  return Variable.alloc(ctx, returnType?.type ?? EvalTypes.dynamicType)..frameIndex = ctx.locals.length - 1;
}
