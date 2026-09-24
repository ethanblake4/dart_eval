import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// Records the local promotions that hold when [expression] has [value].
///
/// This intentionally covers only the promotion forms the compiler can prove
/// from one branch edge. Other expressions leave the local type unchanged.
void recordConditionPromotions(
  CompilerContext ctx,
  Expression expression,
  bool value,
) {
  _visitPromotions(ctx, expression, value, (local, type) {
    local.inferType(ctx, type);
  });
}

/// Applies branch-local promotions while compiling a short-circuit operand.
void applyConditionPromotions(
  CompilerContext ctx,
  Expression expression,
  bool value,
) {
  _visitPromotions(ctx, expression, value, (local, type) {
    final promoted = local.withType(type);
    promoted.binding?.rebind(promoted);
  });
}

void _visitPromotions(
  CompilerContext ctx,
  Expression expression,
  bool value,
  void Function(Variable local, TypeRef type) promote,
) {
  if (expression is ParenthesizedExpression) {
    _visitPromotions(ctx, expression.expression, value, promote);
    return;
  }
  if (expression is PrefixExpression && expression.operator.lexeme == '!') {
    _visitPromotions(ctx, expression.operand, !value, promote);
    return;
  }
  if (expression is BinaryExpression) {
    final operator = expression.operator.lexeme;
    if ((operator == '&&' && value) || (operator == '||' && !value)) {
      _visitPromotions(ctx, expression.leftOperand, value, promote);
      _visitPromotions(ctx, expression.rightOperand, value, promote);
      return;
    }
    final identifier = switch ((
      expression.leftOperand,
      expression.rightOperand,
    )) {
      (final SimpleIdentifier identifier, NullLiteral()) => identifier,
      (NullLiteral(), final SimpleIdentifier identifier) => identifier,
      _ => null,
    };
    if (identifier != null &&
        ((operator == '!=' && value) || (operator == '==' && !value))) {
      final local = ctx.lookupLocal(identifier.name);
      if (local != null && local.type.nullable) {
        promote(local, local.type.withNullable(false));
      }
    }
    return;
  }
  if (expression is IsExpression) {
    final target = expression.expression;
    if (target is! SimpleIdentifier) return;
    final matches = expression.notOperator == null ? value : !value;
    if (!matches) return;
    final local = ctx.lookupLocal(target.name);
    if (local != null) {
      promote(local, TypeRef.fromAnnotation(ctx, ctx.library, expression.type));
    }
  }
}
