import 'package:dart_eval/src/eval/ir/types.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import '../values/value_rep.dart';

Variable compileIsExpression(IsExpression e, CompilerContext ctx) {
  var V = compileExpression(e.expression, ctx);
  final slot = TypeRef.fromAnnotation(ctx, ctx.library, e.type);
  final not = e.notOperator != null;

  V.inferType(ctx, slot);

  /// If the type is definitely a subtype of the slot, we can just return true.
  if (slot.functionType == null &&
      slot.recordFields.isEmpty &&
      V.type.isAssignableTo(ctx, slot, forceAllowDynamic: false)) {
    return BuiltinValue(boolval: !not).push(ctx);
  }

  V = V.boxIfNeeded(ctx);

  /// Otherwise do a runtime test
  return Variable.ssa(
    ctx,
    IsType(ctx.svar('is_type'), V.ssa, slot.runtimeTypeId(ctx), not),
    CoreTypes.bool.ref(ctx),
    rep: ValueRep.bool,
  );
}
