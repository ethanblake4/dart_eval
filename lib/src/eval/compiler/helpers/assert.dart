import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/macros/macro.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

/// Builds the `AssertionError` object [doAssert] raises — also usable as a
/// directly-thrown value in branches that must terminate unconditionally.
Variable compileAssertionError(CompilerContext ctx, Variable message) {
  // Box into a fresh slot: the message may share its SSA slot with a local
  // or parameter that must keep its current representation.
  final argument = message.boxIntoFreshSlot(ctx);
  return Variable.ssa(
    ctx,
    InvokeExternal(
      ctx.svar('assertion_error'),
      ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:core']]![
          'AssertionError.']!,
      [argument.ssa],
    ),
    TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(CoreTypes.assertionError)),
  );
}

/// `assert(condition, message)` — the message expression only evaluates when
/// the condition fails, so it is compiled inside the branch that throws.
void doAssert(
  CompilerContext ctx,
  Variable condition, {
  required MacroVariableClosure message,
}) {
  macroBranch(
    ctx,
    null,
    condition: (_) => condition,
    thenBranch: (_, _) => StatementInfo(),
    elseBranch: (ctx, _) {
      final error = compileAssertionError(ctx, message(ctx));
      ctx.pushOp(Throw(error.ssa));
      return StatementInfo(willAlwaysThrow: true);
    },
  );
}
