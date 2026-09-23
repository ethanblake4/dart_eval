import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/numeric.dart';
import 'package:dart_eval/src/eval/ir/types.dart';
import '../values/abi.dart';

/// Converts a field/variable initializer value for a slot of type [target].
/// Rejects statically-invalid initializers and emits the `int → double`
/// widening when required. Runtime checks are emitted except against
/// function-typed targets, where an [AssertType] can't validate an
/// implicitly-instantiated generic tear-off.
Variable convertInitializer(
  CompilerContext ctx,
  Variable value,
  TypeRef target, {
  AstNode? source,
  String? description,
}) {
  final conversion = value.type
      
      .assignmentConversionTo(ctx, target);
  switch (conversion) {
    case AssignmentConversion.invalid:
      return _implicitCallTearOff(ctx, value, target, source) ??
          (throw CompileError(
            description ?? 'Cannot assign ${value.type} to $target',
            source,
          ));
    case AssignmentConversion.intToDouble:
      return convertForAssignment(
        ctx,
        value,
        target,
        representation: Abi.unboxedAcrossCalls(target).bank,
        source: source,
      );
    case AssignmentConversion.none:
      return value;
    case AssignmentConversion.runtimeCheck:
      return target.functionType != null
          ? value
          : convertForAssignment(
              ctx,
              value,
              target,
              representation: Abi.unboxedAcrossCalls(target).bank,
              source: source,
            );
  }
}

/// The implicit `.call` tear-off: assigning a value of a class that declares
/// `call` into a function-typed slot produces a bound `value.call` closure
/// rather than storing the object. `is`/`as` checks are unaffected — the
/// object itself is still not a `Function`.
Variable? _implicitCallTearOff(
  CompilerContext ctx,
  Variable value,
  TypeRef target,
  AstNode? source,
) {
  if (value.type.nullable) return null;
  // Type parameters coerce against their bound (`context<void Function()>(x)`
  // passes `T` as the target).
  final effectiveTarget = target.isTypeParameter
      ? (target.typeParameterBound ?? CoreTypes.dynamic.ref(ctx))
      : target;
  if (effectiveTarget.functionType == null &&
      !effectiveTarget.isSpec(CoreTypes.function)) {
    return null;
  }
  try {
    final tearOff = value.getProperty(ctx, 'call', source: source);
    if (tearOff.type.isAssignableTo(
      ctx,
      effectiveTarget,
      forceAllowDynamic: false,
    )) {
      return tearOff.copyWith(declaredType: target);
    }
  } on CompileError {
    return null;
  }
  return null;
}

/// Converts [value] for a write or call boundary with Dart assignment rules.
/// Runtime checks stay explicit in IR and therefore cannot disappear merely
/// because the destination is never read.
Variable convertForAssignment(
  CompilerContext ctx,
  Variable value,
  TypeRef target, {
  MachineRepresentation? representation,
  AstNode? source,
  String? description,
}) {
  final conversion = value.type
      
      .assignmentConversionTo(ctx, target);
  // int → double only applies to integer literals and compile-time constant
  // int expressions — never to an int-typed variable (which is a CE in Dart).
  if (conversion == AssignmentConversion.invalid ||
      (conversion == AssignmentConversion.intToDouble && !value.isConstInt)) {
    return _implicitCallTearOff(ctx, value, target, source) ??
        (throw CompileError(
          description ?? 'Cannot assign ${value.type} to $target',
          source,
        ));
  }

  var converted = value;
  // Bound method tear-offs (e.g. `x.m<T>` used as a value) have no SSA slot
  // until materialized as a closure value.
  if (converted.name == null && converted.methodOffset != null) {
    converted = converted.tearOff(ctx);
  }
  if (conversion == AssignmentConversion.intToDouble) {
    final intVar = converted.unboxIfNeeded(ctx, false);
    var widened = Variable.ssa(
      ctx,
      IntToDouble(ctx.svar('toDouble'), intVar.ssa),
      CoreTypes.double.ref(ctx),
      rep: ValueRep.double,
      declaredType: target,
    );
    if ((representation ?? representationForType(target)) ==
        MachineRepresentation.object) {
      widened = widened.boxIfNeeded(ctx, source);
    }
    return widened;
  }
  if (conversion == AssignmentConversion.runtimeCheck) {
    converted = converted.boxIfNeeded(ctx, source);
    final typeId = target.runtimeTypeId(ctx);
    if (target.nullable) {
      macroBranch(
        ctx,
        null,
        condition: (ctx) {
          final isNull = Variable.ssa(
            ctx,
            IsNull(ctx.svar('conversion_null'), converted.ssa),
            CoreTypes.bool.ref(ctx),
            rep: ValueRep.bool,
          );
          return Variable.ssa(
            ctx,
            LogicalNot(ctx.svar('conversion_nonnull'), isNull.ssa),
            isNull.type,
          );
        },
        thenBranch: (ctx, _) {
          ctx.pushOp(AssertType(converted.ssa, typeId));
          return StatementInfo();
        },
      );
    } else {
      ctx.pushOp(AssertType(converted.ssa, typeId));
    }
  }

  final targetRepresentation = representation ?? representationForType(target);
  if (conversion == AssignmentConversion.none) {
    converted = targetRepresentation == MachineRepresentation.object
        ? converted.boxIfNeeded(ctx, source)
        : converted.unboxIfNeeded(ctx, false);
    return converted.copyWith(
      declaredType: target,
      representation: targetRepresentation,
    );
  }
  converted = converted.copyWith(
    type: target,
    rep: ValueRep.boxed,
    declaredType: target,
    representation: MachineRepresentation.object,
  );
  if (targetRepresentation == MachineRepresentation.object) return converted;
  return converted.unboxIfNeeded(ctx, false);
}
