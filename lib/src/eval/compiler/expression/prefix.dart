import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../errors.dart';
import 'expression.dart';

const _opMap = {
  TokenType.MINUS: '-',
  TokenType.BANG: '!',
  TokenType.PLUS_PLUS: '+',
  TokenType.MINUS_MINUS: '-',
};

/// Compile a [PrefixExpression] to EVC bytecode
Variable compilePrefixExpression(CompilerContext ctx, PrefixExpression e) {
  final method = _opMap[e.operator.type] ??
      (throw CompileError('Unknown unary operator ${e.operator.type}'));

  if ([TokenType.PLUS_PLUS, TokenType.MINUS_MINUS].contains(e.operator.type)) {
    final V = compileExpressionAsReference(e.operand, ctx);
    final L = V.getValue(ctx);
    return _handleDoubleOperands(e, ctx, V, L);
  }

  final V = compileExpression(e.operand, ctx);

  if (method == '-' &&
      V.type != CoreTypes.int.ref(ctx) &&
      V.type != CoreTypes.double.ref(ctx)) {
    throw CompileError(
        'Unary prefix "-" is currently only supported for ints and doubles (type: ${V.type})',
        e);
  } else if (method == '!' && V.type != CoreTypes.bool.ref(ctx)) {
    throw CompileError(
        'Unary prefix "!" is currently only supported for bools (type: ${V.type})',
        e);
  }

  if (method == "!") {
    return V.invoke(ctx, method, []).result;
  }

  return _zeroForType(V.type, ctx).push(ctx).invoke(ctx, method, [V]).result;
}

BuiltinValue _zeroForType(TypeRef type, CompilerContext ctx) =>
    type == CoreTypes.int.ref(ctx)
        ? BuiltinValue(intval: 0)
        : BuiltinValue(doubleval: 0.0);

BuiltinValue _oneForType(TypeRef type, CompilerContext ctx) =>
    type == CoreTypes.int.ref(ctx)
        ? BuiltinValue(intval: 1)
        : BuiltinValue(doubleval: 1.0);

Variable _handleDoubleOperands(
  PrefixExpression e,
  CompilerContext ctx,
  Reference V,
  Variable L,
) {
  var l = L;

  l = Variable.alloc(ctx, L.type);
  ctx.pushOp(PushNull.make(), PushNull.LEN);
  ctx.pushOp(
    CopyValue.make(l.scopeFrameOffset, L.scopeFrameOffset),
    CopyValue.LEN,
  );

  final result = l.invoke(
    ctx,
    _opMap[e.operator.type]!,
    [_oneForType(l.type, ctx).push(ctx)],
  ).result;

  return V.setValue(ctx, result);
}
