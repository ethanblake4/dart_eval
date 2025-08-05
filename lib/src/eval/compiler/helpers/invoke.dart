import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

extension Invoke on Variable {
  /// Warning! Calling invoke() may modify the state of input variables. They should be refreshed
  /// after use.
  InvokeResult invoke(CompilerContext ctx, String? method, List<Variable> args,
      {Map<String, Variable>? namedArgs}) {
    var $this = this;

    if (method == null) {
      if (!type.isAssignableTo(ctx, CoreTypes.function.ref(ctx))) {
        throw CompileError(
            'Cannot invoke variable of type $type as it is not a function');
      }

      if (callingConvention == CallingConvention.dynamic ||
          (type == CoreTypes.function.ref(ctx) && methodOffset == null)) {
        final result = invokeClosure(ctx, null, this, null,
            positional: args, named: namedArgs);
        return InvokeResult($this, result.result, result.args,
            namedArgs: result.namedArgs);
      }

      if (methodOffset == null) {
        throw CompileError('Cannot invoke $this as it is not a valid method');
      }

      final offset = methodOffset!;
      if (offset.file == ctx.library &&
          offset.className != null &&
          offset.className == (ctx.currentClass?.name.lexeme)) {
        final inst = ctx.lookupLocal('#this')!;
        return inst.invoke(ctx, method, args, namedArgs: namedArgs);
      }

      for (final arg in args) {
        ctx.pushOp(PushArg.make(arg.scopeFrameOffset), PushArg.LEN);
      }

      final argTypes = args.map((e) => e.type).toList();
      final namedArgTypes =
          namedArgs?.map((key, value) => MapEntry(key, value.type)) ?? {};

      final loc = ctx.pushOp(Call.make(offset.offset ?? -1), Call.length);
      if (offset.offset == null) {
        ctx.offsetTracker.setOffset(loc, offset);
      }
      ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

      final returnType = methodReturnType
              ?.toAlwaysReturnType(ctx, type, argTypes, namedArgTypes)
              ?.type ??
          CoreTypes.dynamic.ref(ctx);
      final v = Variable.alloc(
          ctx,
          returnType.copyWith(
              boxed: !returnType.isUnboxedAcrossFunctionBoundaries));

      return InvokeResult($this, v, args, namedArgs: namedArgs ?? {});
    }

    final supportedNumIntrinsicOps = {'+', '-', '<', '>', '<=', '>='};
    final supportedBoolIntrinsicOps = {'!'};
    if (type.isAssignableTo(ctx, CoreTypes.num.ref(ctx),
            forceAllowDynamic: false) &&
        supportedNumIntrinsicOps.contains(method)) {
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
          // Num intrinsic add
          ctx.pushOp(NumAdd.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumAdd.LEN);
          result = Variable.alloc(
              ctx,
              TypeRef.commonBaseType(ctx, {$this.type, R.type})
                  .copyWith(boxed: false));
          break;
        case '-':
          // Num intrinsic sub
          ctx.pushOp(NumSub.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumSub.LEN);
          result = Variable.alloc(
              ctx,
              TypeRef.commonBaseType(ctx, {$this.type, R.type})
                  .copyWith(boxed: false));
          break;

        case '<':
          // Num intrinsic less than
          ctx.pushOp(NumLt.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumLt.LEN);
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '>':
          // Num intrinsic greater than
          ctx.pushOp(NumLt.make(R.scopeFrameOffset, $this.scopeFrameOffset),
              NumLtEq.LEN);
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '<=':
          // Num intrinsic less than equal to
          ctx.pushOp(NumLtEq.make($this.scopeFrameOffset, R.scopeFrameOffset),
              NumLtEq.LEN);
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;
        case '>=':
          // Num intrinsic greater than equal to
          ctx.pushOp(NumLtEq.make(R.scopeFrameOffset, $this.scopeFrameOffset),
              NumLt.LEN);
          result = Variable.alloc(
              ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
          break;

        default:
          throw CompileError('Unknown num intrinsic method "$method"');
      }

      return InvokeResult($this, result, [R]);
    } else if (type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx),
            forceAllowDynamic: false) &&
        supportedBoolIntrinsicOps.contains(method)) {
      $this = unboxIfNeeded(ctx);
      ctx.pushOp(LogicalNot.make($this.scopeFrameOffset), LogicalNot.LEN);
      var result =
          Variable.alloc(ctx, CoreTypes.bool.ref(ctx).copyWith(boxed: false));
      return InvokeResult($this, result, []);
    }

    final boxed = Variable.boxUnboxMultiple(ctx, [$this, ...args], true);
    $this = boxed[0];
    final args0 = boxed.sublist(1);
    final checkEq = method == '==' && args0.length == 1;
    final checkNotEq = method == '!=' && args0.length == 1;
    if (checkEq || checkNotEq) {
      if ($this.scopeFrameOffset == -1 && args0[0].scopeFrameOffset == -1) {
        final result = $this.methodOffset! == args0[0].methodOffset!;
        final rV = BuiltinValue(boolval: result).push(ctx);
        return InvokeResult($this, rV, args0);
      } else if ($this.scopeFrameOffset == -1) {
        $this = $this.tearOff(ctx);
      } else if (args0[0].scopeFrameOffset == -1) {
        args0[0] = args0[0].tearOff(ctx);
      }
      ctx.pushOp(
          CheckEq.make($this.scopeFrameOffset, args0[0].scopeFrameOffset),
          CheckEq.LEN);
    } else {
      for (final invokeArg in args0) {
        ctx.pushOp(PushArg.make(invokeArg.scopeFrameOffset), PushArg.LEN);
      }

      final invokeOp = InvokeDynamic.make(
          $this.scopeFrameOffset, ctx.constantPool.addOrGet(method));
      ctx.pushOp(invokeOp, InvokeDynamic.len(invokeOp));
    }

    ctx.pushOp(PushReturnValue.make(), PushReturnValue.LEN);

    if (checkNotEq) {
      final res = Variable.alloc(ctx, CoreTypes.bool.ref(ctx));
      ctx.pushOp(LogicalNot.make(res.scopeFrameOffset), LogicalNot.LEN);
    }

    final AlwaysReturnType? returnType;
    if ($this.type == CoreTypes.function.ref(ctx) && method == 'call') {
      returnType = null;
    } else if (checkEq || checkNotEq) {
      returnType = AlwaysReturnType(CoreTypes.bool.ref(ctx), false);
    } else {
      returnType = AlwaysReturnType.fromInstanceMethodOrBuiltin(
          ctx, $this.type, method, [...args0.map((e) => e.type)], {});
    }

    final v = Variable.alloc(
        ctx,
        (returnType?.type ?? CoreTypes.dynamic.ref(ctx))
            .copyWith(boxed: !(checkEq || checkNotEq)));
    return InvokeResult($this, v, args0);
  }
}
