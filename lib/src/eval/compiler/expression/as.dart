import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compileAsExpression(AsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);

  /// If the type is the slot, we can just return
  if (V.type == slot) {
    return V;
  }

  // Special case: if casting null to a nullable type, allow it
  if (V.type == CoreTypes.nullType.ref(ctx) && slot.nullable) {
    return V.copyWithUpdate(ctx, type: slot);
  }

  // Otherwise type-test
  ctx.pushOp(IsType.make(V.scopeFrameOffset, ctx.typeRefIndexMap[slot]!, false),
      IsType.length);
  final vIs =
      Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));

  // And assert
  final errMsg =
      BuiltinValue(stringval: "TypeError: Not a subtype of type ${slot.name}")
          .push(ctx);
  ctx.pushOp(
      Assert.make(vIs.scopeFrameOffset, errMsg.scopeFrameOffset), Assert.LEN);

  // If the type changes between num and int/double, unbox/box
  if (slot == CoreTypes.num.ref(ctx)) {
    V = V.boxIfNeeded(ctx);
  } else if (slot == CoreTypes.int.ref(ctx) ||
      slot == CoreTypes.double.ref(ctx)) {
    V = V.unboxIfNeeded(ctx);
  }

  // For all other types, just inform the compiler
  // (todo) Mixins may need different behavior
  return V.copyWithUpdate(ctx, type: slot.copyWith(boxed: V.type.boxed));
}
