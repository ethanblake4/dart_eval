import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

/// Emits an [InternConst] for the SSA [value] — canonicalizing a
/// `const`-context instance at runtime — and returns the canonical SSA.
/// [type] supplies the compile-time runtime type id used as the intern
/// key's type component.
SSA pushInternConst(CompilerContext ctx, SSA value, TypeRef type) {
  final target = ctx.svar('interned');
  ctx.pushOp(InternConst(target, value, typeId: type.runtimeTypeId(ctx)));
  return target;
}

/// [pushInternConst] for a [Variable], preserving its binding metadata.
/// Interning canonicalizes the runtime object in place — the interned slot
/// keeps whatever physical representation the input already has.
Variable internConst(CompilerContext ctx, Variable value, TypeRef type) =>
    Variable.of(
      ctx,
      pushInternConst(ctx, value.ssa, type),
      value.type,
      rep: value.rep,
      declaredType: value.declaredType,
      concreteTypes: value.concreteTypes,
      exactType: value.exactType,
      isConst: true,
    );
