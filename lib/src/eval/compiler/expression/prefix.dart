import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../errors.dart';
import 'expression.dart';

const _opMap = {
  TokenType.MINUS: '-',
  TokenType.BANG: '!',
  TokenType.TILDE: '~',
  TokenType.PLUS_PLUS: '+',
  TokenType.MINUS_MINUS: '-',
};

/// Compile a [PrefixExpression] to EVC bytecode
Variable compilePrefixExpression(
  CompilerContext ctx,
  PrefixExpression e, [
  TypeRef? bound,
]) {
  final method =
      _opMap[e.operator.type] ??
      (throw CompileError('Unknown unary operator ${e.operator.type}'));

  if ([TokenType.PLUS_PLUS, TokenType.MINUS_MINUS].contains(e.operator.type)) {
    // `++a?.b`, `++a?[i]`: a null target nulls the whole expression.
    final operand = e.operand;
    if (operand is IndexExpression && isNullShortedSelector(operand)) {
      final target = operand.isCascaded
          ? ctx.cascadeTarget!
          : compileExpression(operand.realTarget, ctx);
      return emitNullGuard(
        ctx,
        target,
        (t) => _handleDoubleOperands(
          e,
          ctx,
          IndexedReference(t, compileExpression(operand.index, ctx)),
        ),
        source: e,
      );
    }
    if (operand is PropertyAccess && isNullShortedSelector(operand)) {
      final target = operand.isCascaded
          ? ctx.cascadeTarget!
          : compileExpression(operand.realTarget, ctx);
      return emitNullGuard(
        ctx,
        target,
        (t) => _handleDoubleOperands(
          e,
          ctx,
          IdentifierReference(t, operand.propertyName.name),
        ),
        source: e,
      );
    }
    final V = compileExpressionAsReference(e.operand, ctx);
    return _handleDoubleOperands(e, ctx, V);
  }

  // `!e`'s operand has context type bool regardless of the outer bound.
  final V = compileExpression(
    e.operand,
    ctx,
    method == '!' ? CoreTypes.bool.ref(ctx) : bound,
  );
  final isDynamic = V.type.resolveTypeChain(ctx) == CoreTypes.dynamic.ref(ctx);

  if (method == '!' && !isDynamic && V.type != CoreTypes.bool.ref(ctx)) {
    throw CompileError(
      'Unary prefix "!" is currently only supported for bools (type: ${V.type})',
      e,
    );
  }

  if (method == "!") {
    final boolean = convertForAssignment(
      ctx,
      V,
      CoreTypes.bool.ref(ctx),
      representation: MachineRepresentation.boolean,
      source: e.operand,
      description: 'Operand of ! must be boolean',
    );
    return boolean.invoke(ctx, method, []).result;
  }

  // Nullary `operator -` is keyed `unary-` in member tables, matching the
  // analyzer's element name.
  final member = method == '-' ? 'unary-' : method;

  if (isDynamic) return V.invoke(ctx, member, []).result;

  // `~x` and `-x` on user types call the nullary operators `~` and `-`
  // directly; native ints/doubles negate in place (`-(0.0)` is `-0.0`,
  // which a `0 - x` rewrite would lose).
  if (method == '-' &&
      (V.type == CoreTypes.int.ref(ctx) ||
          V.type == CoreTypes.double.ref(ctx))) {
    final operand = V.unboxIfNeeded(ctx, false);
    return Variable.ssa(
      ctx,
      Negate(ctx.svar('numeric_result'), operand.ssa),
      operand.type,
      representation: operand.representation,
    );
  }
  if (method == '~' || method == '-') {
    return V.invoke(ctx, member, []).result;
  }

  return _zeroForType(V.type, ctx).push(ctx).invoke(ctx, method, [V]).result;
}

BuiltinValue _zeroForType(TypeRef type, CompilerContext ctx) =>
    type == CoreTypes.int.ref(ctx)
    ? BuiltinValue(intval: 0)
    : BuiltinValue(doubleval: 0.0);

BuiltinValue _incrementValue() => BuiltinValue(intval: 1);

Variable _handleDoubleOperands(
  PrefixExpression e,
  CompilerContext ctx,
  Reference V,
) {
  final L = V.getValue(ctx);
  final l = Variable.ssa(ctx, Assign(ctx.svar('operand'), L.ssa), L.type);

  final result = l.invoke(ctx, _opMap[e.operator.type]!, [
    _incrementValue().push(ctx),
  ]).result;

  return V.setValue(ctx, result);
}
