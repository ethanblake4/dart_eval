import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';

Variable compileAsExpression(AsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);

  /// If the type is the slot, we can just return
  if (V.type.isSameSemanticType(ctx, slot)) {
    return V;
  }

  // Special case: if casting null to a nullable type, allow it
  if (V.type == CoreTypes.nullType.ref(ctx) && slot.nullable) {
    return V.copyWithUpdate(ctx, type: slot);
  }

  V = V.boxIfNeeded(ctx);
  final typeId = slot.runtimeTypeId(ctx);
  if (slot.nullable) {
    macroBranch(
      ctx,
      null,
      condition: (ctx) {
        final isNull = Variable.ssa(
          ctx,
          IsNull(ctx.svar('cast_null'), V.ssa),
          CoreTypes.bool.ref(ctx).copyWith(boxed: false),
        );
        return Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('cast_nonnull'), isNull.ssa),
          isNull.type,
        );
      },
      thenBranch: (ctx, _) {
        ctx.pushOp(AssertType(V.ssa, typeId));
        return StatementInfo();
      },
    );
  } else {
    ctx.pushOp(AssertType(V.ssa, typeId));
  }
  V = V.copyWithUpdate(ctx, type: slot.copyWith(boxed: true));

  // If the type changes between num and int/double, unbox/box
  if (slot == CoreTypes.num.ref(ctx)) {
    V = V.boxIfNeeded(ctx);
  } else if (!slot.nullable &&
      (slot == CoreTypes.int.ref(ctx) || slot == CoreTypes.double.ref(ctx))) {
    V = V.unboxIfNeeded(ctx);
  }

  // For all other types, just inform the compiler
  // (todo) Mixins may need different behavior
  V = V.copyWithUpdate(ctx, type: slot.copyWith(boxed: V.type.boxed));

  // `this as T` promotes the receiver itself — store the promoted view on
  // the `#this` local so later `this` reads see it (anonymous-method
  // receivers, extension receivers, and class `this` all live there).
  if (e.expression is ThisExpression) {
    final localThis = ctx.lookupLocal('#this');
    final frame = localThis?.frameIndex;
    if (localThis != null && frame != null) {
      ctx.locals[frame]['#this'] = V
        ..localName = '#this'
        ..frameIndex = frame;
    }
  }
  return V;
}
