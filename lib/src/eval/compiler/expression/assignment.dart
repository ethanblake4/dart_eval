import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import '../invocation/resolver.dart';
import '../invocation/numeric_types.dart';
import 'index.dart';

Variable compileAssignmentExpression(
  AssignmentExpression e,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  // `e1?[e2] op= e3`, `a?.b op= e3`, and writes whose receiver sits on a
  // null-shorted chain (`a?.b.c = e`): a null target nulls the whole
  // expression and skips evaluating the index, the RHS, and the store.
  final lhs = e.leftHandSide;
  if (lhs is IndexExpression && isNullShortedSelector(lhs)) {
    final target = lhs.isCascaded
        ? ctx.cascadeTarget!
        : compileExpression(lhs.realTarget, ctx);
    return emitNullGuard(
      ctx,
      target,
      (t) => _assignWithReference(
        e,
        ctx,
        compileIndexReference(lhs, ctx, t),
        bound,
      ),
      source: e,
    );
  }
  if (lhs is PropertyAccess && isNullShortedSelector(lhs)) {
    final target = compileExpression(lhs.realTarget, ctx);
    return emitNullGuard(
      ctx,
      target,
      (t) => _assignWithReference(
        e,
        ctx,
        IdentifierReference(t, lhs.propertyName.name),
        bound,
      ),
      source: e,
    );
  }
  final L = compileExpressionAsReference(e.leftHandSide, ctx);
  return _assignWithReference(e, ctx, L, bound);
}

Variable _assignWithReference(
  AssignmentExpression e,
  CompilerContext ctx,
  Reference L,
  TypeRef? bound,
) {
  TypeRef? setterType() => L.resolveType(ctx, forSet: true);

  /// The RHS's inference context: for a local variable target the
  /// variable's *current* (possibly promoted) type — `o` promoted to
  /// `String` infers `o = e` with context `String` — while properties and
  /// indexes take the setter's write type.
  TypeRef? rhsContext() {
    if (L case IdentifierReference(:final name, receiver: null)) {
      final binding = ctx.lookupBinding(name);
      if (binding != null) return binding.current.type;
    }
    return setterType();
  }

  if (e.operator.type == TokenType.EQ) {
    final R = compileExpression(e.rightHandSide, ctx, rhsContext());
    final set = R.type != setterType() ? R.boxIfNeeded(ctx) : R;
    final stored = L.setValue(ctx, set, e);
    // `b = cond` records the condition's promotions on `b` — `if (b)`
    // applies them (promotion through bool locals; matching the record
    // made at `bool b = cond` declarations).
    if (L case IdentifierReference(
      :final name,
      receiver: null,
    ) when set.type.isSpec(CoreTypes.bool)) {
      final binding = ctx.lookupBinding(name);
      if (binding != null && !binding.writeCaptured) {
        final (whenTrue, whenFalse) = conditionPromotions(ctx, e.rightHandSide);
        binding.rebind(
          binding.current.withFacts(
            binding.current.facts.copyWith(
              truePromotions: whenTrue,
              falsePromotions: whenFalse,
            ),
          ),
        );
      }
    }
    return stored;
  } else if (e.operator.type.binaryOperatorOfCompoundAssignment ==
      TokenType.QUESTION_QUESTION) {
    // The expression's value merges the stored value (then) with the
    // already-read value (else); both must be assigned into a shared slot so
    // the phi sees one representation, and the getter must be read exactly
    // once (in the condition).
    var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
    Variable? readValue;
    TypeRef? storedType;
    macroBranch(
      ctx,
      null,
      // A provably non-null LHS never runs the write branch; its state must
      // not join (the writes in it would spuriously demote locals).
      thenEdgeUnreachable: () =>
          ctx.soundFlowAnalysis(e) &&
          !readValue!.type.hasNullableRepresentation,
      condition: (ctx) {
        readValue = L.getValue(ctx);
        return CallResolver(
          ctx,
        ).invokeOperator(readValue!, '==', [BuiltinValue().push(ctx)]).result;
      },
      thenBranch: (ctx, rt) {
        // The RHS is evaluated only inside the branch — `x ??= e` must not
        // evaluate `e` when `x` is non-null.
        final R = compileExpression(e.rightHandSide, ctx, rhsContext());
        final set = R.type != setterType() ? R.boxIntoFreshSlot(ctx) : R;
        final V = L.setValue(ctx, set, e).boxIntoFreshSlot(ctx);
        // T2' is the RHS expression's type after coercion to the write
        // context: R's own type when it already conforms, else the type the
        // conversion produced (e.g. a `.call` tear-off coerced to Function).
        final writeType = setterType();
        storedType =
            writeType != null &&
                !R.type.isAssignableTo(ctx, writeType, forceAllowDynamic: false)
            ? V.type
            : R.type;
        ctx.pushOp(Assign(out.ssa, V.ssa));
        return StatementInfo();
      },
      elseBranch: (ctx, rt) {
        // This edge observes a non-null lvalue. Join that promotion with the
        // write edge so a non-null RHS leaves a nullable local promoted.
        if (ctx.soundFlowAnalysis(e)) promoteNonNull(ctx, e.leftHandSide);
        final V = readValue!.boxIntoFreshSlot(ctx);
        ctx.pushOp(Assign(out.ssa, V.ssa));
        return StatementInfo();
      },
    );
    // Per spec, `e1 ??= e2` has type UP(NonNull(T1), T2'): the join of the
    // non-null read type and the stored type — `int? ??= double` is `num`.
    var joined = TypeRef.commonBaseType(ctx, {
      readValue!.type.withNullable(false),
      storedType ?? readValue!.type,
    });
    // Same greatest-closure rule as `?:`: when the join doesn't fit the
    // context's greatest closure S but both contributing types do, the
    // expression's type is S.
    if (bound != null && ctx.inferenceUpdate3(e)) {
      final s = ctx.typeSystem.greatestClosure(bound);
      if (!joined.isAssignableTo(ctx, s, forceAllowDynamic: false) &&
          readValue!.type
              .withNullable(false)
              .isAssignableTo(ctx, s, forceAllowDynamic: false) &&
          (storedType ?? readValue!.type).isAssignableTo(
            ctx,
            s,
            forceAllowDynamic: false,
          )) {
        joined = s;
      }
    }
    return out.copyWith(
      type: joined.withNullable(
        storedType?.nullable ?? readValue!.type.nullable,
      ),
    );
  } else {
    final method = e.operator.type.binaryOperatorOfCompoundAssignment!.lexeme;
    // Dart evaluates the read of L (the getter / index call) before the RHS.
    final V = L.getValue(ctx).copyIntoFreshSlot(ctx, 'compound_left');
    final operandContext = contextualNumericOperators.contains(method)
        ? numericArgumentContext(ctx, V.type, setterType()) ?? setterType()
        : setterType();
    final R = compileExpression(e.rightHandSide, ctx, operandContext);
    final res = CallResolver(ctx).invokeOperator(V, method, [R]).result;
    final set = res.type != L.resolveType(ctx, forSet: true)
        ? res.boxIfNeeded(ctx)
        : res;
    final stored = L.setValue(ctx, set, e);
    // The store conversion checks the lvalue's type; the expression keeps the
    // operator's result type, including a genuinely dynamic return type.
    return Variable.of(
      ctx,
      stored.ssa,
      res.type,
      rep: stored.rep,
      facts: stored.facts,
    );
  }
}
