import 'package:control_flow_graph/control_flow_graph.dart'
    show Assign, Operation;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart' show Unbox;

import '../values/abi.dart';

import 'expression.dart';

/// Compile a [ConditionalExpression] to EVC bytecode
Variable compileConditionalExpression(
  CompilerContext ctx,
  ConditionalExpression e, [
  TypeRef? boundType,
]) {
  final output = ctx.svar('conditional');
  // The bound constrains the branches but never joins the result type:
  // `t ? c : c` under `Function` is still `C` (the branches' join).
  final types = <TypeRef>{};
  final arms = <({Variable value, List<Operation> code, int start, int end})>[];

  StatementInfo compileArm(Expression expression) {
    final value = compileExpression(expression, ctx, boundType);
    types.add(value.type);
    final code = ctx.blockCode;
    final start = code.length;
    ctx.pushOp(Assign(output, value.boxIntoFreshSlot(ctx).ssa));
    arms.add((value: value, code: code, start: start, end: code.length));
    return StatementInfo();
  }

  macroBranch(
    ctx,
    boundType,
    conditionExpression: e.condition,
    thenBranch: (ctx, rt) => compileArm(e.thenExpression),
    elseBranch: (ctx, rt) => compileArm(e.elseExpression),
    resolveStateToThen: true,
    source: e,
  );

  final joined = TypeRef.commonBaseType(ctx, types);
  // TypeRef equality ignores nullability, so the set can discard a nullable
  // arm when the other arm has the same nominal type.
  final type = joined.withNullable(
    joined.nullable || arms.any((arm) => arm.value.type.nullable),
  );
  final rep = Abi.storageSlot(type);
  // Both arms have now been typed. Replace their result conversions in place
  // so scalar joins stay in scalar registers without changing local bindings
  // or moving evaluation across a branch or an exception handler.
  final scalar =
      rep != ValueRep.boxed &&
      rep != ValueRep.nativeNull &&
      arms.every((arm) => arm.value.rep == rep || arm.value.boxed);
  if (scalar) {
    for (final arm in arms) {
      arm.code.replaceRange(arm.start, arm.end, [
        arm.value.rep == rep
            ? Assign(output, arm.value.ssa)
            : Unbox(output, arm.value.ssa, rep.bank),
      ]);
    }
  }
  return Variable.of(ctx, output, type, rep: scalar ? rep : ValueRep.boxed);
}
