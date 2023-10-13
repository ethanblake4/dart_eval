import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

StatementInfo compileAssertStatement(AssertStatement s, CompilerContext ctx,
    AlwaysReturnType? expectedReturnType) {
  final cond = compileExpression(s.condition, ctx);
  final msg = s.message != null
      ? compileExpression(s.message!, ctx)
      : BuiltinValue().push(ctx);

  msg.pushArg(ctx);
  ctx.pushOp(
      InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
          ctx.libraryMap['dart:core']]!['AssertionError.']!),
      InvokeExternal.LEN);
  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final assertionErr = Variable.alloc(ctx,
      TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(CoreTypes.assertionError)));

  ctx.pushOp(Assert.make(cond.scopeFrameOffset, assertionErr.scopeFrameOffset),
      Assert.LEN);

  return StatementInfo(-1);
}
