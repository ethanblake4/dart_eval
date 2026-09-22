import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/null_aware.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compileAssignmentExpression(
  AssignmentExpression e,
  CompilerContext ctx,
) {
  // `e1?[e2] op= e3`, `a?.b op= e3`, and writes whose receiver sits on a
  // null-shorted chain (`a?.b.c = e`): a null target nulls the whole
  // expression and skips evaluating the index, the RHS, and the store.
  final lhs = e.leftHandSide;
  if (lhs is IndexExpression &&
      (lhs.question != null || isNullShorted(lhs.target))) {
    final target = lhs.isCascaded
        ? ctx.cascadeTarget!
        : compileExpression(lhs.realTarget, ctx);
    return emitNullGuard(
      ctx,
      target,
      (t) => _assignWithReference(
        e,
        ctx,
        IndexedReference(t, compileExpression(lhs.index, ctx)),
      ),
      source: e,
    );
  }
  if (lhs is PropertyAccess &&
      (lhs.operator.type == TokenType.QUESTION_PERIOD ||
          isNullShorted(lhs.target))) {
    final target = compileExpression(lhs.realTarget, ctx);
    return emitNullGuard(
      ctx,
      target,
      (t) => _assignWithReference(
        e,
        ctx,
        IdentifierReference(t, lhs.propertyName.name),
      ),
      source: e,
    );
  }
  final L = compileExpressionAsReference(e.leftHandSide, ctx);
  return _assignWithReference(e, ctx, L);
}

Variable _assignWithReference(
  AssignmentExpression e,
  CompilerContext ctx,
  Reference L,
) {
  TypeRef? setterType() => L.resolveType(ctx, forSet: true);

  if (e.operator.type == TokenType.EQ) {
    final R = compileExpression(e.rightHandSide, ctx, setterType());
    final set = R.type != setterType() ? R.boxIfNeeded(ctx) : R;
    return L.setValue(ctx, set);
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
      condition: (ctx) {
        readValue = L.getValue(ctx);
        return readValue!.invoke(ctx, '==', [
          BuiltinValue().push(ctx),
        ]).result;
      },
      thenBranch: (ctx, rt) {
        // The RHS is evaluated only inside the branch — `x ??= e` must not
        // evaluate `e` when `x` is non-null.
        final R = compileExpression(e.rightHandSide, ctx, setterType());
        final set = R.type != setterType() ? R.boxIntoFreshSlot(ctx) : R;
        final V = L.setValue(ctx, set).boxIntoFreshSlot(ctx);
        // T2' is the RHS expression's type after coercion to the write
        // context: R's own type when it already conforms, else the type the
        // conversion produced (e.g. a `.call` tear-off coerced to Function).
        final writeType = setterType();
        storedType = writeType != null &&
                !R.type.isAssignableTo(
                  ctx,
                  writeType,
                  forceAllowDynamic: false,
                )
            ? V.type
            : R.type;
        ctx.pushOp(Assign(out.ssa, V.ssa));
        return StatementInfo();
      },
      elseBranch: (ctx, rt) {
        final V = readValue!.boxIntoFreshSlot(ctx);
        ctx.pushOp(Assign(out.ssa, V.ssa));
        return StatementInfo();
      },
    );
    // Per spec, `e1 ??= e2` has type UP(NonNull(T1), T2'): the join of the
    // non-null read type and the stored type — `int? ??= double` is `num`.
    final joined = TypeRef.commonBaseType(ctx, {
      readValue!.type.copyWith(nullable: false),
      storedType ?? readValue!.type,
    });
    return out.copyWith(
      type: joined.copyWith(
        nullable: storedType?.nullable ?? readValue!.type.nullable,
      ),
    );
  } else {
    final method = e.operator.type.binaryOperatorOfCompoundAssignment!.lexeme;
    // Dart evaluates the read of L (the getter / index call) before the RHS.
    final V = L.getValue(ctx);
    final R = compileExpression(e.rightHandSide, ctx, setterType());
    var res = V.invoke(ctx, method, [R]).result;
    // Dart's compound-assignment rules retain the implicit downcast when the
    // right operand is dynamic. The operator's declared return type alone
    // (for example num from int.+) must not turn that valid runtime check into
    // a static rejection.
    if (R.type.resolveTypeChain(ctx) == CoreTypes.dynamic.ref(ctx)) {
      res = res.copyWith(
        type: CoreTypes.dynamic.ref(ctx).copyWith(boxed: true),
      );
    }
    final set = res.type != L.resolveType(ctx, forSet: true)
        ? res.boxIfNeeded(ctx)
        : res;
    return L.setValue(ctx, set);
  }
}
