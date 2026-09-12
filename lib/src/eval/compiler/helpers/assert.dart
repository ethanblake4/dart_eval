import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

void doAssert(CompilerContext ctx, Variable condition, Variable message) {
  final argument = message.boxIfNeeded(ctx);
  final assertionErr = Variable.ssa(
    ctx,
    InvokeExternal(
      ctx.svar('assertion_error'),
      ctx.bridgeStaticFunctionIndices[ctx
          .libraryMap['dart:core']]!['AssertionError.']!,
      [argument.ssa],
    ),
    TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(CoreTypes.assertionError)),
  );
  ctx.pushOp(Assert(condition.unboxIfNeeded(ctx).ssa, assertionErr.ssa));
}
