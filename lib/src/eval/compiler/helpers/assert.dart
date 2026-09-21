import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/expression/condition.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

void doAssert(CompilerContext ctx, Variable condition, Variable message) {
  // Box/unbox into fresh slots: the arguments may share their SSA slot with
  // a local or parameter that must keep its current representation.
  final argument = message.boxIntoFreshSlot(ctx);
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
  enforceConditionType(ctx, condition, null);
  final conditionValue = convertForAssignment(
    ctx,
    condition,
    CoreTypes.bool.ref(ctx),
    representation: MachineRepresentation.boolean,
    description: "Assert conditions must have a static type of 'bool'",
  );
  ctx.pushOp(Assert(conditionValue.ssa, assertionErr.ssa));
}
