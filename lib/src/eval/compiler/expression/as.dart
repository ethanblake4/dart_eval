import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/return.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart'
    show SsaStorage;
import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import '../values/value_rep.dart';
import '../helpers/type_check.dart';

Variable compileAsExpression(AsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);
  final runtimeType = V.type.erasedExtensionType;
  final runtimeSlot = slot.erasedExtensionType;

  /// If the type is the slot, we can just return
  if (V.type == slot) {
    return V;
  }

  // Special case: if casting null to a nullable type, allow it
  if (V.type.isSpec(CoreTypes.nullType) && slot.nullable) {
    final result = V.withType(slot);
    if (result.binding?.writeCaptured != true) {
      result.binding?.rebind(result);
    }
    return result;
  }

  V = V.boxIfNeeded(ctx);
  // `x as T` promotes x's flow type to T only when T refines x's current
  // type — casting to a wider or unrelated type (dynamic, Object) leaves
  // the variable's type unchanged. The operand must be a local/`this`
  // itself — `(o..f()) as T` evaluates to `o`'s bound variable but must
  // never rebind `o`.
  Expression operand = e.expression;
  while (operand is ParenthesizedExpression) {
    operand = operand.expression;
  }
  final promotesLocal =
      operand is SimpleIdentifier || operand is ThisExpression;
  final localBinding = switch (operand) {
    SimpleIdentifier(:final name) => ctx.lookupBinding(name),
    ThisExpression() => ctx.lookupBinding('#this'),
    _ => null,
  };
  final promotes = canPromoteTo(ctx, slot, V.type, e);
  // A cast whose operand can never be `slot` throws unconditionally. Only
  // the leaf-`Null` cases are provable: a statically-`Null` operand against
  // a type `Null` isn't assignable to, or `as Null` on a provably
  // non-nullable operand. The assert still runs (it produces the TypeError);
  // the code after it is compiled but unreachable.
  final guaranteedThrow =
      runtimeSlot.isSpec(CoreTypes.never) ||
      ctx.soundFlowAnalysis(e) &&
          (runtimeType.isSpec(CoreTypes.nullType)
              ? !CoreTypes.nullType.ref(ctx).isAssignableTo(ctx, runtimeSlot)
              : runtimeSlot.isSpec(CoreTypes.nullType) &&
                    !runtimeType.hasNullableRepresentation);
  Variable update(Variable v, TypeRef type) {
    final result = v.withType(type);
    if (promotes && promotesLocal) {
      localBinding?.typesOfInterest.add(type);
      localBinding?.typesOfInterest.add(type.withNullable(false));
      // A write-captured local can be clobbered by a closure at any
      // time — `x as T` can't promote it.
      if (localBinding != null && !localBinding.writeCaptured) {
        // Cell and handler slots retain their physical bank after a cast.
        // The cast result can be unboxed without changing storage reads.
        localBinding.rebind(
          localBinding.storage is SsaStorage
              ? result
              : localBinding.current.withType(type),
        );
      }
    }
    return result;
  }

  if (slot.nullable) {
    macroBranch(
      ctx,
      null,
      condition: (ctx) {
        final isNull = Variable.ssa(
          ctx,
          IsNull(ctx.svar('cast_null'), V.ssa),
          CoreTypes.bool.ref(ctx),
          rep: ValueRep.bool,
        );
        return Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('cast_nonnull'), isNull.ssa),
          isNull.type,
        );
      },
      thenBranch: (ctx, _) {
        compileTypeAssertion(ctx, V, slot, source: e);
        return StatementInfo();
      },
    );
  } else {
    compileTypeAssertion(ctx, V, slot, source: e);
    if (guaranteedThrow) markNeverTerminates(ctx);
  }
  V = update(V, slot);

  // `c._f as T` also records a member promotion on `c`'s binding —
  // later `c._f` reads then see the narrowed type.
  if (promotes) {
    final memberSlot = promotableMemberSlot(ctx, e.expression);
    if (memberSlot != null && memberSlot.member != null) {
      promoteMember(
        ctx,
        memberSlot.local,
        memberSlot.viaSuper ? 'super:${memberSlot.member}' : memberSlot.member!,
        slot,
      );
    }
  }

  // If the type changes between num and int/double, unbox/box
  if (slot.isSpec(CoreTypes.num)) {
    V = V.boxIfNeeded(ctx);
  } else if (!slot.nullable &&
      (slot.isSpec(CoreTypes.int) || slot.isSpec(CoreTypes.double))) {
    V = V.unboxIfNeeded(ctx);
  }

  // For all other types, just inform the compiler
  // (todo) Mixins may need different behavior
  V = update(V, slot);

  return V;
}
