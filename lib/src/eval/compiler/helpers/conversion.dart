import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/types.dart';

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
      .resolveTypeChain(ctx)
      .assignmentConversionTo(ctx, target);
  if (conversion == AssignmentConversion.invalid) {
    throw CompileError(
      description ?? 'Cannot assign ${value.type} to $target',
      source,
    );
  }

  var converted = value;
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
            CoreTypes.bool.ref(ctx).copyWith(boxed: false),
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
    type: target.copyWith(boxed: true),
    declaredType: target,
    representation: MachineRepresentation.object,
  );
  if (targetRepresentation == MachineRepresentation.object) return converted;
  return converted.unboxIfNeeded(ctx, false);
}
