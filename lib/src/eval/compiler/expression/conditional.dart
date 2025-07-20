import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../errors.dart';
import 'expression.dart';

/// Compile a [ConditionalExpression] to EVC bytecode
Variable compileConditionalExpression(
    CompilerContext ctx, ConditionalExpression e,
    [TypeRef? boundType]) {
  ctx.setLocal('#conditional', BuiltinValue().push(ctx));
  final vRef = IdentifierReference(null, '#conditional');
  final types = <TypeRef>{if (boundType != null) boundType};

  macroBranch(
      ctx, boundType == null ? null : AlwaysReturnType(boundType, false),
      condition: (ctx) {
    var c = compileExpression(e.condition, ctx);
    if (!c.type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx))) {
      throw CompileError('Condition must be a boolean');
    }

    return c;
  }, thenBranch: (ctx, rt) {
    final v = compileExpression(e.thenExpression, ctx, boundType);
    types.add(v.type);
    vRef.setValue(ctx, v);
    return StatementInfo(-1);
  }, elseBranch: (ctx, rt) {
    final v = compileExpression(e.elseExpression, ctx, boundType);
    types.add(v.type);
    vRef.setValue(ctx, v);
    return StatementInfo(-1);
  }, resolveStateToThen: true, source: e);

  final val = vRef.getValue(ctx).updated(ctx);
  return val.copyWith(
      type: TypeRef.commonBaseType(ctx, types).copyWith(boxed: val.boxed));
}
