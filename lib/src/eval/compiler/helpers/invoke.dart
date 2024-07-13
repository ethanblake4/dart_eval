import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

extension Invoke on Variable {
  /// Warning! Calling invoke() may modify the state of input variables. They should be refreshed
  /// after use.
  InvokeResult invoke(CompilerContext ctx, String method, List<Variable> args) {
    var $this = this;

    final supportedIntIntrinsicOps = {'+', '-', '<', '>', '<=', '>='};
    final supportedBoolIntrinsicOps = {'!'};
    if (type.isAssignableTo(ctx, CoreTypes.int.ref(ctx),
            forceAllowDynamic: false) &&
        supportedIntIntrinsicOps.contains(method) &&
        args[0].type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
      $this = unboxIfNeeded(ctx);
      if (args.length != 1) {
        throw CompileError(
            'Cannot invoke method "$method" on variable of type $type with args count: ${args.length} (required: 1)');
      }
      var R = args[0];
      if (R.scopeFrameOffset == scopeFrameOffset) {
        R = $this;
      } else {
        R = R.unboxIfNeeded(ctx);
      }

      Variable result;
      switch (method) {
        case '+':
          // Int intrinsic add
          result = Variable.ssa(
              ctx,
              IntAdd(ctx.svar('add_result'), $this.ssa, R.ssa),
              CoreTypes.int.ref(ctx).copyWith(boxed: false));
          break;
        case '-':
          // Int intrinsic sub
          result = Variable.ssa(
              ctx,
              IntSub(ctx.svar('sub_result'), $this.ssa, R.ssa),
              CoreTypes.int.ref(ctx).copyWith(boxed: false));
          break;

        case '<':
          // Int intrinsic less than
          result = Variable.ssa(
              ctx,
              IntLessThan(ctx.svar('lt_result'), $this.ssa, R.ssa),
              CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '>':
          // Int intrinsic greater than
          result = Variable.ssa(
              ctx,
              IntGreaterThan(ctx.svar('gt_result'), $this.ssa, R.ssa),
              CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '<=':
          // Int intrinsic less than or equal
          result = Variable.ssa(
              ctx,
              IntLessThanOrEqual(ctx.svar('le_result'), $this.ssa, R.ssa),
              CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '>=':
          // Int intrinsic greater than or equal
          result = Variable.ssa(
              ctx,
              IntGreaterThanOrEqual(ctx.svar('ge_result'), $this.ssa, R.ssa),
              CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;

        default:
          throw CompileError('Unknown num intrinsic method "$method"');
      }

      return InvokeResult($this, result, [R]);
    } else if (type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx),
            forceAllowDynamic: false) &&
        supportedBoolIntrinsicOps.contains(method)) {
      $this = unboxIfNeeded(ctx);
      var result = Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('not_result'), $this.ssa),
          CoreTypes.bool.ref(ctx).copyWith(boxed: false));
      return InvokeResult($this, result, []);
    }

    final _boxed = Variable.boxUnboxMultiple(ctx, [$this, ...args], true);
    $this = _boxed[0];
    final _args = _boxed.sublist(1);
    final checkEq = method == '==' && _args.length == 1;
    final checkNotEq = method == '!=' && _args.length == 1;
    final resvar =
        ctx.svar(checkEq || checkNotEq ? 'equals_result' : 'invoke_result');
    if (checkEq || checkNotEq) {
      if ($this.scopeFrameOffset == -1 && _args[0].scopeFrameOffset == -1) {
        final result = $this.methodOffset! == _args[0].methodOffset!;
        final rV = BuiltinValue(boolval: result).push(ctx);
        return InvokeResult($this, rV, _args);
      } else if ($this.scopeFrameOffset == -1) {
        $this = $this.tearOff(ctx);
      } else if (_args[0].scopeFrameOffset == -1) {
        _args[0] = _args[0].tearOff(ctx);
      }
      ctx.pushOp(DynamicEquals(resvar, $this.ssa, _args[0].ssa));
    } else {
      ctx.pushOp(InvokeDynamic(
          resvar, $this.ssa, method, [for (final arg in args) arg.ssa]));
    }

    if (checkNotEq) {
      ctx.pushOp(LogicalNot(resvar, resvar));
    }

    final AlwaysReturnType? returnType;
    if ($this.type == CoreTypes.function.ref(ctx) && method == 'call') {
      returnType = null;
    } else if (checkEq || checkNotEq) {
      returnType = AlwaysReturnType(CoreTypes.bool.ref(ctx), false);
    } else {
      returnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
          ctx, $this.type, method, [..._args.map((e) => e.type)], {});
    }

    final v = Variable.of(
        ctx,
        resvar,
        (returnType?.type ?? CoreTypes.dynamic.ref(ctx))
            .copyWith(boxed: !(checkEq || checkNotEq)));
    return InvokeResult($this, v, _args);
  }
}
