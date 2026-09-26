import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'assigned_locals.dart';

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
  bool value, {
  Set<String> excluded = const {},
}) {
  _visitPromotions(ctx, expression, value, (local, type) {
    final promoted = local.withType(type);
    promoted.binding?.rebind(promoted);
  }, excluded: excluded);
}

void _visitPromotions(
  CompilerContext ctx,
  Expression expression,
  bool value,
  void Function(Variable local, TypeRef type) promote, {
  Set<String> excluded = const {},
}) {
  if (expression is ParenthesizedExpression) {
    _visitPromotions(
      ctx,
      expression.expression,
      value,
      promote,
      excluded: excluded,
    );
    return;
  }
  if (expression is PrefixExpression && expression.operator.lexeme == '!') {
    _visitPromotions(
      ctx,
      expression.operand,
      !value,
      promote,
      excluded: excluded,
    );
    return;
  }
  if (expression is BinaryExpression) {
    final operator = expression.operator.lexeme;
    if ((operator == '&&' && value) || (operator == '||' && !value)) {
      _visitPromotions(
        ctx,
        expression.leftOperand,
        value,
        promote,
        excluded: {
          ...excluded,
          ...assignedLocalNames([expression.rightOperand]),
        },
      );
      _visitPromotions(
        ctx,
        expression.rightOperand,
        value,
        promote,
        excluded: excluded,
      );
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
        !excluded.contains(identifier.name) &&
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
    if (target is! SimpleIdentifier || excluded.contains(target.name)) return;
    final matches = expression.notOperator == null ? value : !value;
    if (!matches) return;
    final local = ctx.lookupLocal(target.name);
    if (local == null) return;
    final tested = TypeRef.fromAnnotation(ctx, ctx.library, expression.type);
    // `x is S` narrows only when `S` is a subtype of the declared type —
    // an `is` check never widens a local to a type it can't represent.
    if (isPromotionSubtype(ctx, tested, local.type)) {
      promote(local, tested);
    }
  }
}

/// Whether [tested] narrows [current] for `is`-promotion — a subtype
/// check strict about function variance (the looser assignability used
/// for argument coercion treats all function types as compatible).
bool isPromotionSubtype(CompilerContext ctx, TypeRef tested, TypeRef current) {
  // `x is C` where x is a type parameter produces the intersection `T&C`:
  // model it as the tested type — the value genuinely is a C afterwards.
  // `dynamic` narrows to whatever the test proves.
  if (current.isTypeParameter || current.isSpec(CoreTypes.dynamic)) {
    return true;
  }
  if (tested is! FunctionTypeRef || current is! FunctionTypeRef) {
    return tested.isAssignableTo(ctx, current, forceAllowDynamic: false);
  }
  final ts = tested.signature;
  final cs = current.signature;
  if (ts.typeParameters.isNotEmpty || cs.typeParameters.isNotEmpty) {
    return true;
  }
  // The tested signature must accept at least the calls [current]
  // accepts: no more required positionals, no fewer positionals, every
  // named parameter [current] declares, and contravariant parameter
  // types (covariant return).
  if (ts.requiredPositional > cs.requiredPositional ||
      ts.positional.length < cs.positional.length) {
    return false;
  }
  for (var i = 0; i < cs.positional.length; i++) {
    if (!cs.positional[i].isAssignableTo(
      ctx,
      ts.positional[i],
      forceAllowDynamic: false,
    )) {
      return false;
    }
  }
  for (final entry in cs.named.entries) {
    final param = ts.named[entry.key];
    if (param == null ||
        !entry.value.type.isAssignableTo(
          ctx,
          param.type,
          forceAllowDynamic: false,
        )) {
      return false;
    }
  }
  for (final entry in ts.named.entries) {
    if (entry.value.required && !cs.named.containsKey(entry.key)) {
      return false;
    }
  }
  return ts.returnType.isAssignableTo(ctx, cs.returnType);
}
