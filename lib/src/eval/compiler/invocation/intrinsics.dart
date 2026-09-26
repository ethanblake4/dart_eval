import '../../ir/collection.dart' show ListAppend, ListSet, MapSet, SetAdd;
import '../../ir/objects.dart' show BufferWrite;
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
/// returned [OperatorResult] carries the unboxed operand values compound
/// assignments write back.
final class Intrinsics {
  const Intrinsics(this.ctx);

  final CompilerContext ctx;

  OperatorResult? tryEmit(
    Variable receiver,
    String method,
    List<Variable> args,
  ) {
    final type = receiver.type;
    final boolType = CoreTypes.bool.ref(ctx);
    if (method == 'write' &&
        args.length == 1 &&
        type.isAssignableTo(
          ctx,
          CoreTypes.stringBuffer.ref(ctx),
          forceAllowDynamic: false,
        )) {
      final buffer = receiver.boxIfNeeded(ctx);
      final isString =
          args.single.type.isSpec(CoreTypes.string) &&
          !args.single.type.nullable;
      final argument = isString
          ? args.single.unboxIfNeeded(ctx, false)
          : args.single.boxIfNeeded(ctx);
      ctx.pushOp(BufferWrite(buffer.ssa, argument.ssa, isString: isString));
      return (
        target: buffer,
        result: Variable.of(
          ctx,
          ctx.svar('buffer_write'),
          CoreTypes.voidType.ref(ctx),
          rep: ValueRep.boxed,
        ),
        args: [argument],
        namedArgs: const {},
      );
    }
    // An allocation-exact boxed List also proves its storage and type
    // arguments. Use those arguments, not a possibly widened static type, to
    // preserve covariant write checks. Unknown boxed receivers still dispatch.
    final collectionType = !receiver.boxed
        ? type
        : receiver.exactType?.isSpec(CoreTypes.list) == true
        ? receiver.exactType
        : null;
    final collectionRep = collectionType == null
        ? null
        : unboxedRepOf(collectionType);
    if (args.length == 1 && method == 'add' && collectionType != null) {
      final isList = collectionRep == ValueRep.nativeList;
      final typeArgs = interfaceArgumentsOf(collectionType);
      final elementType = typeArgs.isEmpty ? null : typeArgs.first;
      if ((isList || collectionRep == ValueRep.nativeSet) &&
          (elementType == null ||
              args.single.type.isAssignableTo(
                ctx,
                elementType,
                forceAllowDynamic: false,
              ))) {
        final collection = receiver.unboxIfNeeded(ctx);
        final value = args.single.boxIfNeeded(ctx);
        final ssa = ctx.svar(isList ? 'list_add' : 'set_add');
        ctx.pushOp(
          isList
              ? ListAppend(collection.ssa, value.ssa)
              : SetAdd(collection.ssa, value.ssa, target: ssa),
        );
        return (
          target: collection,
          result: Variable.of(
            ctx,
            ssa,
            isList ? CoreTypes.voidType.ref(ctx) : boolType,
            rep: isList ? ValueRep.boxed : ValueRep.bool,
          ),
          args: [value],
          namedArgs: const {},
        );
      }
    }
    if (args.length == 2 && method == '[]=' && collectionType != null) {
      final typeArgs = interfaceArgumentsOf(collectionType);
      bool storable(Variable arg, int parameter) =>
          typeArgs.length <= parameter ||
          arg.type.isAssignableTo(
            ctx,
            typeArgs[parameter],
            forceAllowDynamic: false,
          );
      if (collectionRep == ValueRep.nativeMap &&
          storable(args[0], 0) &&
          storable(args[1], 1)) {
        final map = receiver.unboxIfNeeded(ctx);
        final key = args[0].boxIfNeeded(ctx);
        final value = args[1].boxIfNeeded(ctx);
        ctx.pushOp(MapSet(map.ssa, key.ssa, value.ssa));
        return (
          target: map,
          result: value,
          args: [key, value],
          namedArgs: const {},
        );
      }
      if (collectionRep == ValueRep.nativeList &&
          args[0].type.isAssignableTo(ctx, CoreTypes.int.ref(ctx)) &&
          storable(args[1], 0)) {
        final list = receiver.unboxIfNeeded(ctx);
        final index = args[0].unboxIfNeeded(ctx);
        final value = args[1].boxIfNeeded(ctx);
        ctx.pushOp(ListSet(list.ssa, index.ssa, value.ssa));
        return (
          target: list,
          result: value,
          args: [index, value],
          namedArgs: const {},
        );
      }
    }
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
      return (
        target: receiverUnboxed,
        result: Variable.ssa(
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
        args: [argument],
        namedArgs: const {},
      );
    }

    if (args.length == 2 &&
        method == 'substring' &&
        type.isAssignableTo(
          ctx,
          CoreTypes.string.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        args.every(
          (arg) => arg.type.isAssignableTo(
            ctx,
            CoreTypes.int.ref(ctx),
            forceAllowDynamic: false,
          ),
        )) {
      final receiverUnboxed = receiver.unboxIfNeeded(ctx, false);
      final start = args[0].ssa == receiver.ssa
          ? receiverUnboxed
          : args[0].unboxIfNeeded(ctx, false);
      final end = args[1].ssa == receiver.ssa
          ? receiverUnboxed
          : args[1].unboxIfNeeded(ctx, false);
      return (
        target: receiverUnboxed,
        result: Variable.ssa(
          ctx,
          StringSubstring(
            ctx.svar('string_result'),
            receiverUnboxed.ssa,
            start.ssa,
            end.ssa,
          ),
          CoreTypes.string.ref(ctx),
          rep: ValueRep.string,
        ),
        args: [start, end],
        namedArgs: const {},
      );
    }

    if ((method == '==' || method == '!=' || method == 'startsWith') &&
        args.length == 1 &&
        type.isSpec(CoreTypes.string) &&
        !type.nullable &&
        args.single.type.isSpec(CoreTypes.string) &&
        !args.single.type.nullable) {
      final left = receiver.unboxIfNeeded(ctx);
      final right = args.single.ssa == receiver.ssa
          ? left
          : args.single.unboxIfNeeded(ctx);
      return (
        target: left,
        result: Variable.ssa(
          ctx,
          StringOperation(
            ctx.svar('string_equal'),
            switch (method) {
              '==' => StringOperator.equal,
              '!=' => StringOperator.notEqual,
              _ => StringOperator.startsWith,
            },
            left.ssa,
            right.ssa,
          ),
          boolType,
          rep: ValueRep.bool,
        ),
        args: [right],
        namedArgs: const {},
      );
    }
    if (method == '!' &&
        type.isAssignableTo(
          ctx,
          CoreTypes.bool.ref(ctx),
          forceAllowDynamic: false,
        )) {
      final receiverUnboxed = receiver.unboxIfNeeded(ctx);
      return (
        target: receiverUnboxed,
        result: Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('not_result'), receiverUnboxed.ssa),
          boolType,
          rep: ValueRep.bool,
        ),
        args: [],
        namedArgs: const {},
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
      return (
        target: receiverUnboxed,
        result: Variable.ssa(
          ctx,
          operation,
          method == '+' || method == '-' ? CoreTypes.int.ref(ctx) : boolType,
          rep: method == '+' || method == '-' ? ValueRep.int : ValueRep.bool,
        ),
        args: [right],
        namedArgs: const {},
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
        return (
          target: receiverUnboxed,
          result: Variable.ssa(
            ctx,
            operation,
            resultType,
            rep: unboxedRepOf(resultType),
          ),
          args: [right],
          namedArgs: const {},
        );
      }
    }
    return null;
  }
}
