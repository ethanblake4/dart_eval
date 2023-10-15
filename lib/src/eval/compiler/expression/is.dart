import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compileIsExpression(IsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);
  final not = e.notOperator != null;

  /// If the type is definitely a subtype of the slot, we can just return true.
  if (V.type.isAssignableTo(ctx, slot, forceAllowDynamic: false)) {
    return BuiltinValue(boolval: !not).push(ctx);
  }

  V = V.boxIfNeeded(ctx);

  /// Otherwise do a runtime test
  ctx.pushOp(IsType.make(V.scopeFrameOffset, ctx.typeRefIndexMap[slot]!, not),
      IsType.LEN);
  return Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
}
