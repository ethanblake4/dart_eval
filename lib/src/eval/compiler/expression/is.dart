import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import '../helpers/type_check.dart';

Variable compileIsExpression(IsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);
  final not = e.notOperator != null;
  final runtimeType = V.type.erasedExtensionType;
  final runtimeSlot = slot.erasedExtensionType;

  // `x is S` narrows only when `S` is a subtype of the operand's type.
  if (isPromotionSubtype(ctx, slot, V.type)) {
    V.inferType(ctx, slot);
  }

  /// If the type is definitely a subtype of the slot, we can just return true.
  if (runtimeSlot is! FunctionTypeRef &&
      runtimeSlot is! RecordTypeRef &&
      runtimeType.isAssignableTo(ctx, runtimeSlot, forceAllowDynamic: false)) {
    return BuiltinValue(boolval: !not).push(ctx);
  }

  /// `x is Never` can never hold — no runtime value has type Never — so
  /// both directions fold statically. That makes a guarded branch
  /// unreachable.
  if (runtimeSlot.isSpec(CoreTypes.never)) {
    return BuiltinValue(boolval: not).push(ctx);
  }

  /// Leaf-`Null` disjointness the analyzer folds statically: `x is Null`
  /// with a provably non-nullable `x`, and `x is T` where `x` is statically
  /// `Null` but `Null` isn't a `T`, are both statically `false` — flow
  /// analysis then treats that edge of a branch as unreachable.
  /// A bare type parameter can instantiate to a nullable type, so its
  /// null membership must be checked in the runtime type environment.
  final definitelyFalse = runtimeSlot.isSpec(CoreTypes.nullType)
      ? !runtimeType.hasNullableRepresentation && !runtimeType.isTypeParameter
      : runtimeType.isSpec(CoreTypes.nullType) &&
            !runtimeSlot.isTypeParameter &&
            !CoreTypes.nullType.ref(ctx).isAssignableTo(ctx, runtimeSlot);
  if (definitelyFalse) {
    return BuiltinValue(boolval: not).push(ctx);
  }

  V = V.boxIfNeeded(ctx);

  return compileTypeTest(ctx, V, slot, negated: not, source: e);
}
