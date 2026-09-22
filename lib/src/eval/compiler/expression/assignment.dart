import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compileAssignmentExpression(
  AssignmentExpression e,
  CompilerContext ctx, {
  Variable? cascadeTarget,
}) {
  final L = compileExpressionAsReference(
    e.leftHandSide,
    ctx,
    cascadeTarget: cascadeTarget,
  );
  final R = compileExpression(
    e.rightHandSide,
    ctx,
    L.resolveType(ctx, forSet: true),
  );

  if (e.operator.type == TokenType.EQ) {
    final set = R.type != L.resolveType(ctx, forSet: true)
        ? R.boxIfNeeded(ctx)
        : R;
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
        final set = R.type != L.resolveType(ctx, forSet: true)
            ? R.boxIfNeeded(ctx)
            : R;
        result = L.setValue(ctx, set);
        return StatementInfo();
      },
    );
    return result;
  } else {
    final method = e.operator.type.binaryOperatorOfCompoundAssignment!.lexeme;
    final V = L.getValue(ctx);
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
