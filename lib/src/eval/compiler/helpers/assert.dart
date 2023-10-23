import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

void doAssert(CompilerContext ctx, Variable condition, Variable message) {
  message.boxIfNeeded(ctx).pushArg(ctx);
  ctx.pushOp(
      InvokeExternal.make(ctx.bridgeStaticFunctionIndices[
          ctx.libraryMap['dart:core']]!['AssertionError.']!),
      InvokeExternal.LEN);
  ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);
  final assertionErr = Variable.alloc(ctx,
      TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(CoreTypes.assertionError)));

  ctx.pushOp(
      Assert.make(condition.scopeFrameOffset, assertionErr.scopeFrameOffset),
      Assert.LEN);
}
