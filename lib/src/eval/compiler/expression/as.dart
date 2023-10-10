import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/source_node_wrapper.dart';
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

  // Otherwise type-test
  ctx.pushOp(IsType.make(V.scopeFrameOffset, runtimeTypeMap[slot] ?? ctx.typeRefIndexMap[slot]!, false), IsType.LEN);
  final Vis = Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));

  // And assert
  final errMsg = BuiltinValue(stringval: "TypeError: Not a subtype of type TYPE").push(ctx);
  ctx.pushOp(Assert.make(Vis.scopeFrameOffset, errMsg.scopeFrameOffset), Assert.LEN);

  // If the type changes between num and int/double, unbox/box
  if (slot == EvalTypes.numType) {
    V = V.boxIfNeeded(ctx);
  } else if (slot == EvalTypes.intType || slot == EvalTypes.doubleType) {
    V = V.unboxIfNeeded(ctx);
  }

  // For all other types, just inform the compiler
  // TODO: mixins may need different behavior
  return V.copyWithUpdate(ctx, type: slot.copyWith(boxed: V.type.boxed));
}
