import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show Assign;
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes, AsyncTypes;
import 'package:dart_eval/src/eval/ir/types.dart';

import '../builtins.dart';
import '../context.dart';
import '../macros/branch.dart';
import '../statement/statement.dart';
import '../type.dart';
import '../variable.dart';
import '../values/value_rep.dart';

/// Tests a boxed operand. FutureOr is a union, not a nominal runtime type.
Variable compileTypeTest(
  CompilerContext ctx,
  Variable value,
  TypeRef type, {
  bool negated = false,
  AstNode? source,
}) {
  if (type is! InterfaceTypeRef || !type.decl.isSpec(AsyncTypes.futureOr)) {
    return Variable.ssa(
      ctx,
      IsType(
        ctx.svar('is_type'),
        value.ssa,
        ctx.runtimeTypes.idOf(type),
        negated,
      ),
      CoreTypes.bool.ref(ctx),
      rep: ValueRep.bool,
    );
  }
  final arguments = interfaceArgumentsOf(type);
  final member = arguments.isEmpty
      ? CoreTypes.dynamic.ref(ctx)
      : arguments.first;
  final result = ctx.svar('is_futureor');
  macroBranch(
    ctx,
    null,
    condition: (ctx) => compileTypeTest(
      ctx,
      value,
      ctx.types.bySpec(CoreTypes.future).instantiate([
        member,
      ], nullable: type.nullable),
      source: source,
    ),
    thenBranch: (ctx, _) {
      BuiltinValue(boolval: !negated).push(ctx, result);
      return StatementInfo();
    },
    elseBranch: (ctx, _) {
      final checked = compileTypeTest(
        ctx,
        value,
        member.withNullable(type.nullable || member.nullable),
        negated: negated,
        source: source,
      );
      ctx.pushOp(Assign(result, checked.ssa));
      return StatementInfo();
    },
    source: source,
  );
  return Variable.of(ctx, result, CoreTypes.bool.ref(ctx), rep: ValueRep.bool);
}

/// Preserves the ordinary assertion opcode; unions need both membership tests.
void compileTypeAssertion(
  CompilerContext ctx,
  Variable value,
  TypeRef type, {
  AstNode? source,
}) {
  if (type is! InterfaceTypeRef || !type.decl.isSpec(AsyncTypes.futureOr)) {
    ctx.pushOp(AssertType(value.ssa, ctx.runtimeTypes.idOf(type)));
    return;
  }
  macroBranch(
    ctx,
    null,
    condition: (ctx) => compileTypeTest(ctx, value, type, source: source),
    thenBranch: (ctx, _) => StatementInfo(),
    elseBranch: (ctx, _) {
      // No value satisfies Never, so the existing assertion throws TypeError.
      ctx.pushOp(
        AssertType(value.ssa, ctx.runtimeTypes.idOf(CoreTypes.never.ref(ctx))),
      );
      return StatementInfo();
    },
    source: source,
  );
}
