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
    late Variable result;
    macroBranch(
      ctx,
      null,
      condition: (ctx) {
        return L.getValue(ctx).invoke(ctx, '==', [
          BuiltinValue().push(ctx),
        ]).result;
      },
      thenBranch: (ctx, rt) {
        // The RHS is evaluated only inside the branch — `x ??= e` must not
        // evaluate `e` when `x` is non-null.
        final R = compileExpression(e.rightHandSide, ctx, setterType());
        final set = R.type != setterType() ? R.boxIfNeeded(ctx) : R;
        result = L.setValue(ctx, set);
        return StatementInfo();
      },
    );
    return result;
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
