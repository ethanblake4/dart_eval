import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compileAsExpression(AsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);

  /// If the type is the slot, we can just return
  if (V.type == slot) {
    return V;
  }

  // Otherwise type-test
  ctx.pushOp(AssertType(V.ssa, ctx.typeRefIndexMap[slot]!));

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
