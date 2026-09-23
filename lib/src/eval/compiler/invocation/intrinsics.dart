import '../../ir/string.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/numeric.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
import '../values/abi.dart';
import '../values/value_rep.dart';

/// Fast paths consulted before member resolution on the operator and index
/// paths — a hit emits a dedicated ALU/string op instead of a call, and the
/// returned [InvokeResult] carries the unboxed operand values compound
/// assignments write back.
final class Intrinsics {
  const Intrinsics(this.ctx);

  final CompilerContext ctx;

  InvokeResult? tryEmit(Variable receiver, String method, List<Variable> args) {
    final type = receiver.type;
    final boolType = CoreTypes.bool.ref(ctx);
    if (args.length == 1 &&
        type.isAssignableTo(
          ctx,
          CoreTypes.string.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        ((method == '+' &&
                args.single.type.isAssignableTo(
                  ctx,
                  CoreTypes.string.ref(ctx),
                  forceAllowDynamic: false,
                )) ||
            ((method == 'codeUnitAt' || method == '[]') &&
                args.single.type.isAssignableTo(
                  ctx,
                  CoreTypes.int.ref(ctx),
                  forceAllowDynamic: false,
                )))) {
      final receiverUnboxed = receiver.unboxIfNeeded(ctx, false);
      final argument = args.single.ssa == receiver.ssa
          ? receiverUnboxed
          : args.single.unboxIfNeeded(ctx, false);
      final operator = switch (method) {
        '+' => StringOperator.concatenate,
        'codeUnitAt' => StringOperator.codeUnitAt,
        _ => StringOperator.indexAt,
      };
      return InvokeResult(
        receiverUnboxed,
        Variable.ssa(
          ctx,
          StringOperation(
            ctx.svar('string_result'),
            operator,
            receiverUnboxed.ssa,
            argument.ssa,
          ),
          (operator == StringOperator.codeUnitAt
                  ? CoreTypes.int
                  : CoreTypes.string)
              .ref(ctx),
          rep: operator == StringOperator.codeUnitAt
              ? ValueRep.int
              : ValueRep.string,
        ),
        [argument],
      );
    }

    if (method == '!' &&
        type.isAssignableTo(
          ctx,
          CoreTypes.bool.ref(ctx),
          forceAllowDynamic: false,
        )) {
      final receiverUnboxed = receiver.unboxIfNeeded(ctx);
      return InvokeResult(
        receiverUnboxed,
        Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('not_result'), receiverUnboxed.ssa),
          boolType,
          rep: ValueRep.bool,
        ),
        [],
      );
    }
    if (args.length == 1 &&
        type.isAssignableTo(
          ctx,
          CoreTypes.int.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        args.single.type.isAssignableTo(
          ctx,
          CoreTypes.int.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        {'+', '-', '<', '>', '<=', '>='}.contains(method)) {
      final receiverUnboxed = receiver.unboxIfNeeded(ctx);
      final right = args.single.ssa == receiver.ssa
          ? receiverUnboxed
          : args.single.unboxIfNeeded(ctx);
      final target = ctx.svar('numeric_result');
      final Operation operation = switch (method) {
        '+' => IntAdd(target, receiverUnboxed.ssa, right.ssa),
        '-' => IntSub(target, receiverUnboxed.ssa, right.ssa),
        '<' => IntLessThan(target, receiverUnboxed.ssa, right.ssa),
        '>' => IntGreaterThan(target, receiverUnboxed.ssa, right.ssa),
        '<=' => IntLessThanOrEqual(target, receiverUnboxed.ssa, right.ssa),
        '>=' => IntGreaterThanOrEqual(target, receiverUnboxed.ssa, right.ssa),
        _ => throw StateError('Unknown numeric intrinsic $method'),
      };
      return InvokeResult(
        receiverUnboxed,
        Variable.ssa(
          ctx,
          operation,
          method == '+' || method == '-' ? CoreTypes.int.ref(ctx) : boolType,
          rep: method == '+' || method == '-' ? ValueRep.int : ValueRep.bool,
        ),
        [right],
      );
    }
    const numericOperators = {
      '+': NumericOperator.add,
      '-': NumericOperator.subtract,
      '*': NumericOperator.multiply,
      '/': NumericOperator.divide,
      '~/': NumericOperator.truncatingDivide,
      '%': NumericOperator.modulo,
      '&': NumericOperator.bitAnd,
      '|': NumericOperator.bitOr,
      '^': NumericOperator.bitXor,
      '<<': NumericOperator.shiftLeft,
      '>>': NumericOperator.shiftRight,
      '>>>': NumericOperator.unsignedShiftRight,
      '<': NumericOperator.lessThan,
      '<=': NumericOperator.lessThanOrEqual,
      '>': NumericOperator.greaterThan,
      '>=': NumericOperator.greaterThanOrEqual,
      '==': NumericOperator.equal,
      '!=': NumericOperator.notEqual,
    };
    final numericOperator = numericOperators[method];
    if (args.length == 1 && numericOperator != null) {
      final integerOperands =
          type.isAssignableTo(
            ctx,
            CoreTypes.int.ref(ctx),
            forceAllowDynamic: false,
          ) &&
          args.single.type.isAssignableTo(
            ctx,
            CoreTypes.int.ref(ctx),
            forceAllowDynamic: false,
          );
      // `int` counts as a double operand through the implicit int → double
      // conversion; [widen] emits the IntToDouble op below. TypeRef equality
      // ignores nullability, so `int?` must be excluded explicitly — a nullable
      // value has object representation and may hold null.
      bool isDoubleOperand(TypeRef t) =>
          !t.nullable &&
          (t.isAssignableTo(
                ctx,
                CoreTypes.double.ref(ctx),
                forceAllowDynamic: false,
              ) ||
              t.isSpec(CoreTypes.int));
      final doubleOperands =
          isDoubleOperand(type) && isDoubleOperand(args.single.type);
      final integerOperation = integerOperands && method != '/';
      if (integerOperation ||
          (doubleOperands &&
              !numericOperator.isIntegerOnly &&
              method != '~/' &&
              method != '%')) {
        final operandRepresentation = integerOperation
            ? MachineRepresentation.integer
            : MachineRepresentation.doublePrecision;
        Variable widen(Variable v) =>
            operandRepresentation == MachineRepresentation.doublePrecision &&
                v.type.isSpec(CoreTypes.int)
            ? Variable.ssa(
                ctx,
                IntToDouble(ctx.svar('widen'), v.ssa),
                CoreTypes.double.ref(ctx),
                rep: ValueRep.double,
              )
            : v;
        final receiverUnboxed = widen(receiver.unboxIfNeeded(ctx));
        final right = args.single.ssa == receiver.ssa
            ? receiverUnboxed
            : widen(args.single.unboxIfNeeded(ctx));
        final operation = NumericBinary(
          ctx.svar('numeric_result'),
          receiverUnboxed.ssa,
          right.ssa,
          operandRepresentation,
          numericOperator,
        );
        final resultType = numericOperator.isComparison
            ? CoreTypes.bool.ref(ctx)
            : operandRepresentation == MachineRepresentation.integer
            ? CoreTypes.int.ref(ctx)
            : CoreTypes.double.ref(ctx);
        return InvokeResult(
          receiverUnboxed,
          Variable.ssa(
            ctx,
            operation,
            resultType,
            rep: unboxedRepOf(resultType),
          ),
          [right],
        );
      }
    }
    return null;
  }
}
