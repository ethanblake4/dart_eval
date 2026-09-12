import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

extension Invoke on Variable {
  InvokeResult invoke(
    CompilerContext ctx,
    String? method,
    List<Variable> args, {
    Map<String, Variable>? namedArgs,
  }) {
    if (method == null) return _invokeAsFunction(ctx, args, namedArgs);
    final boolType = CoreTypes.bool.ref(ctx).copyWith(boxed: false);
    if (method == '!' &&
        type.isAssignableTo(
          ctx,
          CoreTypes.bool.ref(ctx),
          forceAllowDynamic: false,
        )) {
      final receiver = unboxIfNeeded(ctx);
      return InvokeResult(
        receiver,
        Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('not_result'), receiver.ssa),
          boolType,
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
      final receiver = unboxIfNeeded(ctx);
      final right = args.single.ssa == ssa
          ? receiver
          : args.single.unboxIfNeeded(ctx);
      final target = ctx.svar('numeric_result');
      final Operation operation = switch (method) {
        '+' => IntAdd(target, receiver.ssa, right.ssa),
        '-' => IntSub(target, receiver.ssa, right.ssa),
        '<' => IntLessThan(target, receiver.ssa, right.ssa),
        '>' => IntGreaterThan(target, receiver.ssa, right.ssa),
        '<=' => IntLessThanOrEqual(target, receiver.ssa, right.ssa),
        '>=' => IntGreaterThanOrEqual(target, receiver.ssa, right.ssa),
        _ => throw StateError('Unknown numeric intrinsic $method'),
      };
      return InvokeResult(
        receiver,
        Variable.ssa(
          ctx,
          operation,
          method == '+' || method == '-'
              ? CoreTypes.int.ref(ctx).copyWith(boxed: false)
              : boolType,
        ),
        [right],
      );
    }
    var receiver = this;
    final values = [...args];
    final equality = (method == '==' || method == '!=') && values.length == 1;
    if (equality &&
        receiver.name == null &&
        receiver.methodOffset != null &&
        values.single.name == null &&
        values.single.methodOffset != null) {
      final equal = receiver.methodOffset == values.single.methodOffset;
      return InvokeResult(
        receiver,
        BuiltinValue(boolval: method == '!=' ? !equal : equal).push(ctx),
        values,
      );
    }
    if (receiver.name == null && receiver.methodOffset != null) {
      receiver = receiver.tearOff(ctx);
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i].name == null && values[i].methodOffset != null) {
        values[i] = values[i].tearOff(ctx);
      }
    }
    final boxed = Variable.boxUnboxMultiple(ctx, [receiver, ...values], true);
    receiver = boxed.first;
    final prepared = boxed.sublist(1);
    var result = ctx.svar(equality ? 'equals_result' : 'invoke_result');
    if (equality) {
      ctx.pushOp(DynamicEquals(result, receiver.ssa, prepared.single.ssa));
      if (method == '!=') {
        final negated = ctx.svar('not_equal_result');
        ctx.pushOp(LogicalNot(negated, result));
        result = negated;
      }
    } else {
      ctx.pushOp(
        InvokeDynamic(result, receiver.ssa, method, [
          ...prepared.map((arg) => arg.ssa),
          ...?namedArgs?.values.map((arg) => arg.boxIfNeeded(ctx).ssa),
        ]),
      );
    }
    final returnType = equality
        ? boolType
        : (receiver.type == CoreTypes.function.ref(ctx) && method == 'call'
              ? CoreTypes.dynamic.ref(ctx)
              : AlwaysReturnType.fromInstanceMethodOrBuiltin(
                      ctx,
                      receiver.type,
                      method,
                      prepared.map((arg) => arg.type).toList(),
                      namedArgs?.map((key, arg) => MapEntry(key, arg.type)) ??
                          {},
                    )?.type ??
                    CoreTypes.dynamic.ref(ctx));
    return InvokeResult(
      receiver,
      Variable.of(ctx, result, returnType.copyWith(boxed: !equality)),
      prepared,
      namedArgs: namedArgs ?? {},
    );
  }

  InvokeResult _invokeAsFunction(
    CompilerContext ctx,
    List<Variable> args,
    Map<String, Variable>? namedArgs,
  ) {
    if (!type.isAssignableTo(ctx, CoreTypes.function.ref(ctx))) {
      throw CompileError(
        'Cannot invoke variable of type $type as it is not a function',
      );
    }
    if (callingConvention == CallingConvention.dynamic ||
        methodOffset == null) {
      return invokeClosure(
        ctx,
        null,
        this,
        null,
        positional: args,
        named: namedArgs,
      );
    }
    final target = ctx.svar('call_result');
    final returnType =
        methodReturnType
            ?.toAlwaysReturnType(
              ctx,
              type,
              args.map((arg) => arg.type).toList(),
              namedArgs?.map((key, arg) => MapEntry(key, arg.type)) ?? {},
            )
            ?.type ??
        CoreTypes.dynamic.ref(ctx);
    ctx.pushOp(
      Call(methodOffset!, [
        ...args.map((arg) => arg.ssa),
        ...?namedArgs?.values.map((arg) => arg.ssa),
      ], result: target),
    );
    return InvokeResult(
      this,
      Variable.of(
        ctx,
        target,
        returnType.copyWith(
          boxed: !returnType.isUnboxedAcrossFunctionBoundaries,
        ),
      ),
      args,
      namedArgs: namedArgs ?? {},
    );
  }
}
