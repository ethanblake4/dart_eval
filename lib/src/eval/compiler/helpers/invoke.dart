import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/optimizer/intrinsics.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

extension Invoke on Variable {
  /// Warning! Calling invoke() may modify the state of input variables. They should be refreshed
  /// after use.
  InvokeResult invoke(CompilerContext ctx, String method, List<Variable> args) {
    var $this = this;

    if (type.isAssignableTo(ctx, CoreTypes.int.ref(ctx),
            forceAllowDynamic: false) &&
        intIntrinsics.keys.contains(method) &&
        args[0].type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
      $this = unboxIfNeeded(ctx);
      if (args.length != 1) {
        throw CompileError(
            'Cannot invoke method "$method" on variable of type $type with args count: ${args.length} (required: 1)');
      }
      var R = args[0];
      R = R.ssa == ssa ? $this : R.unboxIfNeeded(ctx);

      final (itype, intrinsic) = intIntrinsics[method]!;
      final result = Variable.ssa(
          ctx,
          intrinsic(
              ctx.svar('${intrinsicNames[method]}_result'), $this.ssa, R.ssa),
          itype.ref(ctx).copyWith(boxed: false));

      return InvokeResult($this, result, [R]);
    } else if (type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx),
            forceAllowDynamic: false) &&
        boolIntrinsics.keys.contains(method) &&
        (method == '!' ||
            args[0].type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx)))) {
      $this = unboxIfNeeded(ctx);
      final (itype, intrinsic) = boolIntrinsics[method]!;
      var R = method == '!' ? null : args[0];
      R = R == null ? null : (R.ssa == ssa ? $this : R.unboxIfNeeded(ctx));
      var result = Variable.ssa(
          ctx,
          intrinsic(
              ctx.svar('${intrinsicNames[method]}_result'), $this.ssa, R?.ssa),
          itype.ref(ctx).copyWith(boxed: false));
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
      if ($this.methodOffset != null && _args[0].methodOffset != null) {
        final result = $this.methodOffset! == _args[0].methodOffset!;
        final rV = BuiltinValue(boolval: result).push(ctx);
        return InvokeResult($this, rV, _args);
      } else if ($this.methodOffset != null) {
        $this = $this.tearOff(ctx);
      } else if (_args[0].methodOffset != null) {
        _args[0] = _args[0].tearOff(ctx);
      }
      ctx.pushOp(DynamicEquals(resvar, $this.ssa, _args[0].ssa));
    } else {
      ctx.pushOp(InvokeDynamic(
          resvar, $this.ssa, method, [for (final arg in args) arg.ssa]));
    }

    if (checkNotEq) {
      ctx.pushOp(LogicalNot(resvar.copy(), resvar));
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
