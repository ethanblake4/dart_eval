import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import '../values/value_rep.dart';

Variable compileIsExpression(IsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);
  final not = e.notOperator != null;

  // `x is S` narrows only when `S` is a subtype of the operand's type.
  if (isPromotionSubtype(ctx, slot, V.type)) {
    V.inferType(ctx, slot);
  }

  /// If the type is definitely a subtype of the slot, we can just return true.
  if (slot is! FunctionTypeRef &&
      slot is! RecordTypeRef &&
      V.type.isAssignableTo(ctx, slot, forceAllowDynamic: false)) {
    return BuiltinValue(boolval: !not).push(ctx);
  }

  /// `x is Never` can never hold — no runtime value has type Never — so
  /// both directions fold statically. That makes a guarded branch
  /// unreachable.
  if (slot.isSpec(CoreTypes.never)) {
    return BuiltinValue(boolval: not).push(ctx);
  }

  /// Leaf-`Null` disjointness the analyzer folds statically: `x is Null`
  /// with a provably non-nullable `x`, and `x is T` where `x` is statically
  /// `Null` but `Null` isn't a `T`, are both statically `false` — flow
  /// analysis then treats that edge of a branch as unreachable.
  /// A bare type parameter can instantiate to a nullable type, so its
  /// null membership must be checked in the runtime type environment.
  final definitelyFalse = slot.isSpec(CoreTypes.nullType)
      ? !V.type.nullable &&
            !V.type.isSpec(CoreTypes.dynamic) &&
            !V.type.isTypeParameter
      : V.type.isSpec(CoreTypes.nullType) &&
            !slot.isTypeParameter &&
            !CoreTypes.nullType.ref(ctx).isAssignableTo(ctx, slot);
  if (definitelyFalse) {
    return BuiltinValue(boolval: not).push(ctx);
  }

  V = V.boxIfNeeded(ctx);

  /// Otherwise do a runtime test
  return Variable.ssa(
    ctx,
    IsType(ctx.svar('is_type'), V.ssa, ctx.runtimeTypes.idOf(slot), not),
    CoreTypes.bool.ref(ctx),
    rep: ValueRep.bool,
  );
}
