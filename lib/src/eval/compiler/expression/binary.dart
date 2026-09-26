import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';

import '../errors.dart';
import 'expression.dart';
import '../values/value_rep.dart';
import '../invocation/resolver.dart';

final binaryOpMap = {
  TokenType.PLUS: '+',
  TokenType.MINUS: '-',
  TokenType.SLASH: '/',
  TokenType.STAR: '*',
  TokenType.LT: '<',
  TokenType.GT: '>',
  TokenType.LT_EQ: '<=',
  TokenType.GT_EQ: '>=',
  TokenType.PERCENT: '%',
  TokenType.EQ_EQ: '==',
  TokenType.AMPERSAND_AMPERSAND: '&&',
  TokenType.QUESTION_QUESTION: '??',
  TokenType.BAR_BAR: '||',
  TokenType.BAR: '|',
  TokenType.AMPERSAND: '&',
  TokenType.LT_LT: '<<',
  TokenType.GT_GT: '>>',
  TokenType.GT_GT_GT: '>>>',
  TokenType.BANG_EQ: '!=',
  TokenType.CARET: '^',
  TokenType.TILDE_SLASH: '~/',
};

/// Compile a [BinaryExpression] to EVC bytecode
Variable compileBinaryExpression(
  CompilerContext ctx,
  BinaryExpression e, [
  TypeRef? boundType,
]) {
  if ((e.operator.type == TokenType.AMPERSAND_AMPERSAND ||
          e.operator.type == TokenType.BAR_BAR) &&
      _hasOnlyBooleanLocals(e, ctx)) {
    final output = ctx.svar('boolean_result');
    macroBranch(
      ctx,
      null,
      conditionExpression: e,
      thenBranch: (ctx, _) {
        ctx.pushOp(LoadBool(output, true));
        return StatementInfo();
      },
      elseBranch: (ctx, _) {
        ctx.pushOp(LoadBool(output, false));
        return StatementInfo();
      },
    );
    return Variable.of(
      ctx,
      output,
      CoreTypes.bool.ref(ctx),
      rep: ValueRep.bool,
    );
  }
  final method =
      binaryOpMap[e.operator.type] ??
      (throw CompileError('Unknown binary operator ${e.operator.type}'));
  var L = compileExpression(
    e.leftOperand,
    ctx,
    // `&&`/`||` operands have `bool` as their context type on both sides.
    switch (e.operator.type) {
      TokenType.AMPERSAND_AMPERSAND ||
      TokenType.BAR_BAR => CoreTypes.bool.ref(ctx),
      _ => boundType,
    },
  );

  switch (e.operator.type) {
    case TokenType.AMPERSAND_AMPERSAND:
    case TokenType.BAR_BAR:
    case TokenType.QUESTION_QUESTION:
      return _compileShortCircuit(
        ctx,
        L,
        e.leftOperand,
        e.rightOperand,
        method,
        boundType: boundType,
      );
  }

  // Evaluating the right operand can assign or change the representation of a
  // local used by the left operand. Preserve its already evaluated value.
  final leftConst = L.isConst;
  L = L.copyIntoFreshSlot(ctx, 'binary_left');
  // For `==`/`!=` the right operand's context type is the left operand's
  // static type (e.g. `.foo` shorthands resolve against it).
  final rightBound = switch (e.operator.type) {
    TokenType.EQ_EQ || TokenType.BANG_EQ => L.type,
    _ => boundType,
  };
  var R = compileExpression(e.rightOperand, ctx, rightBound);
  if ((method == '==' || method == '!=') &&
      (L.type.isSpec(CoreTypes.nullType) ||
          R.type.isSpec(CoreTypes.nullType))) {
    final value = L.type.isSpec(CoreTypes.nullType) ? R : L;
    final test = compileNullCondition(ctx, value);
    return method == '=='
        ? test
        : Variable.ssa(
            ctx,
            LogicalNot(ctx.svar('not_null'), test.ssa),
            CoreTypes.bool.ref(ctx),
            rep: ValueRep.bool,
          );
  }
  final result = CallResolver(ctx).invokeOperator(L, method, [R]).result;
  if (!e.inConstantContext && !(leftConst && R.isConst)) return result;
  // Operators on const operands produce compile-time constants that must
  // canonicalize: `identical("ab", "a" + "b")` holds in the host VM.
  final boxed = result.boxIfNeeded(ctx);
  return internConst(ctx, boxed, boxed.type);
}

// A chain of boolean locals has no promotions or terminating operands to
// preserve. Branch directly and materialize only the final result, instead
// of a separate boolean join for each &&/|| in the chain.
bool _hasOnlyBooleanLocals(Expression expression, CompilerContext ctx) {
  if (expression is ParenthesizedExpression) {
    return _hasOnlyBooleanLocals(expression.expression, ctx);
  }
  if (expression is PrefixExpression && expression.operator.lexeme == '!') {
    return _hasOnlyBooleanLocals(expression.operand, ctx);
  }
  if (expression is BinaryExpression &&
      (expression.operator.lexeme == '&&' ||
          expression.operator.lexeme == '||')) {
    return _hasOnlyBooleanLocals(expression.leftOperand, ctx) &&
        _hasOnlyBooleanLocals(expression.rightOperand, ctx);
  }
  if (expression is SimpleIdentifier) {
    final type = ctx.lookupLocal(expression.name)?.type;
    return type != null && !type.nullable && type.isSpec(CoreTypes.bool);
  }
  return expression is BooleanLiteral;
}

Variable _compileShortCircuit(
  CompilerContext ctx,
  Variable L,
  Expression left,
  Expression right,
  String operator, {
  TypeRef? boundType,
}) {
  late TypeRef rightType;
  final boolType = CoreTypes.bool.ref(ctx);
  L = operator == '??'
      ? L.boxIfNeeded(ctx)
      : convertForAssignment(
          ctx,
          L,
          boolType,
          representation: MachineRepresentation.boolean,
          source: left,
          description: 'Operands of $operator must be boolean',
        );
  final outVar = Variable.ssa(
    ctx,
    Assign(ctx.svar('short_circuit'), L.ssa),
    L.type,
    rep: L.rep,
  );

  macroBranch(
    ctx,
    null,
    condition: (ctx) {
      if (operator == '??') {
        return Variable.ssa(
          ctx,
          IsNull(ctx.svar('short_circuit_test'), L.ssa),
          CoreTypes.bool.ref(ctx),
          rep: ValueRep.bool,
        );
      }
      if (operator == '&&') return L;
      return Variable.ssa(
        ctx,
        LogicalNot(ctx.svar('short_circuit_test'), L.ssa),
        boolType,
      );
    },
    thenBranch: (ctx, rt) {
      // Short-circuit: we only execute the RHS if the LHS is null
      if (operator == '&&' || operator == '||') {
        applyConditionPromotions(ctx, left, operator == '&&');
      }
      // `x ?? .y` gives the RHS the join context (outer bound, else the
      // non-nullable LHS type); `x && .y`/`||` give it `bool`.
      final rightBound = operator == '??'
          ? boundType ?? L.type.withNullable(false)
          : CoreTypes.bool.ref(ctx);
      var R = compileExpression(right, ctx, rightBound);
      rightType = R.type;
      if (rightType.isSpec(CoreTypes.never) && !rightType.nullable) {
        return markNeverTerminates(ctx);
      }
      if (operator != '??') {
        R = convertForAssignment(
          ctx,
          R,
          boolType,
          representation: MachineRepresentation.boolean,
          source: right,
          description: 'Operands of $operator must be boolean',
        );
      } else {
        // Fresh slot: an unboxed local must keep its primitive
        // representation on the path where this branch doesn't run.
        R = R.boxIntoFreshSlot(ctx);
      }
      rightType = R.type;
      ctx.pushOp(Assign(outVar.ssa, R.ssa));
      return StatementInfo();
    },
  );

  if (rightType.isSpec(CoreTypes.never) &&
      !rightType.nullable &&
      operator != '??') {
    // The RHS cannot reach the join. Continuing therefore proves the LHS
    // short-circuited, including any type test or null check it contains.
    applyConditionPromotions(ctx, left, operator == '||');
  }

  // For `??` the result is the join of the non-null LHS type and the RHS —
  // a `Null`-typed LHS contributes nothing (`Null ?? C` is `C`, not `C?`).
  final lhsType = L.type.isSpec(CoreTypes.nullType)
      ? null
      : L.type.withNullable(false);
  final outType = operator == '??'
      ? lhsType == null
            ? rightType
            : TypeRef.commonBaseType(ctx, {lhsType, rightType})
      : CoreTypes.bool.ref(ctx);

  return outVar.copyWith(type: outType);
}
