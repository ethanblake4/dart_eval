import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import '../values/abi.dart';
import 'binder.dart';
import 'bound_call.dart';

/// What is called — the resolver's output. [signature] is null for
/// [DynamicCall]; [emit] produces the IR ops and the result value.
sealed class CallTarget {
  const CallTarget();

  CallSignature? get signature;

  BindingPolicy get policy;

  CallableAbi get abi;

  Variable emit(CompilerContext ctx, BoundCall call);
}

/// A compile-time-known function body: top-level functions, static
/// methods, extension members (receiver as argument 0), devirtualized
/// methods, and super methods.
final class StaticCall extends CallTarget {
  const StaticCall(
    this.offset, {
    this.member,
    this.receiver,
    this.ownerLink,
    this.typeEnvironmentReceiver,
    this.signature,
  });

  final DeferredOrOffset offset;
  final Member? member;

  /// An instance receiver prepended to the argument vector (super calls
  /// and devirtualized methods).
  final Variable? receiver;

  /// For devirtualized calls whose body uses `super`: the SSA holding the
  /// receiver's link positioned at the declaring owner.
  final SSA? ownerLink;

  /// A boxed receiver carried for runtime generic checks.
  final Variable? typeEnvironmentReceiver;

  @override
  final CallSignature? signature;

  @override
  BindingPolicy get policy => BindingPolicy.callerFillsDefaults;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final s = ctx.svar('method_result');
    ctx.pushOp(
      Call(
        offset,
        [
          if (receiver != null) ownerLink ?? receiver!.ssa,
          ...call.vector(),
        ],
        result: s,
        typeArguments: call.runtimeTypeArguments,
        typeEnvironmentReceiver: typeEnvironmentReceiver?.boxIfNeeded(ctx).ssa,
      ),
    );
    return Variable.of(ctx, s, call.returnType, rep: ValueRep.boxed);
  }
}

/// A function-typed value invoked dynamically — `f(args)`, `x.call(args)`.
/// When the exact function is statically known ([known]), a direct `Call`
/// replaces the `InvokeClosure`.
final class ClosureCall extends CallTarget {
  const ClosureCall({this.callee, this.known});

  /// The callee value; null when [known] dispatches statically.
  final Variable? callee;

  /// A statically known target — today: `getStaticDispatch` on a
  /// reference-typed callee.
  final StaticDispatch? known;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.calleeBinds;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final target = ctx.svar('closure_result');
    if (known != null) {
      ctx.pushOp(
        Call(
          known!.offset,
          call.vector(),
          result: target,
          typeArguments: call.runtimeTypeArguments,
        ),
      );
    } else {
      // The callee sits in object position at the call boundary — box
      // unboxed results into a fresh slot; boxing in place would
      // double-define the SSA.
      final callableBoxed = callee!.boxed
          ? callee!
          : callee!.boxIntoFreshSlot(ctx);
      final closure = Variable.ssa(
        ctx,
        Assign(ctx.svar('closure_target'), callableBoxed.ssa),
        callableBoxed.type,
      );
      ctx.pushOp(
        InvokeClosure(
          target,
          closure.ssa,
          [for (final arg in call.positional) arg.value.ssa],
          {
            for (final entry in call.named) entry.$1: entry.$2.value.ssa,
          },
          typeArguments: call.runtimeTypeArguments,
          trusted: call.trusted,
        ),
      );
    }
    return Variable.of(ctx, target, call.returnType, rep: ValueRep.boxed);
  }
}

/// `new`/`const` object construction, dot shorthands, type-alias
/// construction, super-constructor calls, and enum constants.
final class ConstructorCall extends CallTarget {
  const ConstructorCall({
    required this.offset,
    required this.instantiatedType,
    this.constructor,
    this.isConst = false,
    this.factory = false,
  });

  final DeferredOrOffset offset;
  final TypeRef instantiatedType;
  final Member? constructor;
  final bool isConst;

  /// A factory-redirecting constructor: instantiated class arguments travel
  /// through `typeArguments` instead of the hidden runtime-id argument.
  final bool factory;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.callerFillsDefaults;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    // Filled in with the constructor migration (step 5).
    throw UnimplementedError('ConstructorCall.emit');
  }
}

/// An instance member invoked through the receiver's static type.
final class VirtualCall extends CallTarget {
  const VirtualCall({
    required this.receiver,
    required this.name,
    this.isSuperReceiver = false,
  });

  final Variable receiver;
  final String name;

  /// `super.m(...)`: the receiver's link is positioned above the current
  /// layer, so devirtualization uses the link rather than `exactType`.
  final bool isSuperReceiver;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.callerFillsDefaults;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final s = ctx.svar('method_result');
    ctx.pushOp(
      InvokeDynamic(
        s,
        receiver.boxIfNeeded(ctx).ssa,
        name,
        call.vector(),
        positionalCount: call.positional.length,
        namedNames: [for (final entry in call.named) entry.$1],
        callerLibrary: ctx.library,
        typeArguments: call.runtimeTypeArguments,
      ),
    );
    return Variable.of(ctx, s, call.returnType, rep: ValueRep.boxed);
  }
}

/// A bridge function, constructor, or member.
final class BridgeCall extends CallTarget {
  const BridgeCall({this.receiver, this.name = '', this.externalIndex});

  /// The receiver for an instance bridge member; null for statics.
  final Variable? receiver;
  final String name;

  /// `bridgeStaticFunctionIndices` index for static calls; null emits an
  /// `InvokeDynamic` for an instance member instead.
  final int? externalIndex;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.bridgeVector;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final s = ctx.svar('method_result');
    final index = externalIndex;
    if (index != null) {
      ctx.pushOp(InvokeExternal(s, index, call.vector()));
    } else {
      // Instance bridge members use the legacy padded ABI: named arguments
      // were flattened into the positional vector in declaration order.
      ctx.pushOp(
        InvokeDynamic(
          s,
          receiver!.boxIfNeeded(ctx).ssa,
          name,
          call.vector(),
          positionalCount: call.vector().length,
          namedNames: const [],
          callerLibrary: ctx.library,
          typeArguments: call.runtimeTypeArguments,
        ),
      );
    }
    return Variable.of(ctx, s, call.returnType, rep: ValueRep.boxed);
  }
}

/// A `dynamic` receiver: all arguments boxed, tear-offs materialized, no
/// signature.
final class DynamicCall extends CallTarget {
  const DynamicCall({required this.receiver, required this.name});

  final Variable receiver;
  final String name;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.calleeBinds;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final s = ctx.svar('method_result');
    ctx.pushOp(
      InvokeDynamic(
        s,
        receiver.boxIfNeeded(ctx).ssa,
        name,
        call.vector(),
        positionalCount: call.positional.length,
        namedNames: [for (final entry in call.named) entry.$1],
        callerLibrary: ctx.library,
        typeArguments: call.runtimeTypeArguments,
      ),
    );
    return Variable.of(ctx, s, call.returnType, rep: ValueRep.boxed);
  }
}

/// `==`/`!=` without an applicable extension member.
final class EqualityCall extends CallTarget {
  const EqualityCall({required this.left, required this.right, this.negated = false});

  final Variable left;
  final Variable right;
  final bool negated;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.calleeBinds;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    // Operands arrive materialized (torn off) — the resolver performs the
    // unmaterialized-reference checks first, and `tearOff` keeps the method
    // offset so re-checking here would create a second closure.
    final boxed = Variable.boxUnboxMultiple(ctx, [left, right], true);
    var result = ctx.svar('equals_result');
    ctx.pushOp(DynamicEquals(result, boxed.first.ssa, boxed.last.ssa));
    if (negated) {
      final negated = ctx.svar('not_equal_result');
      ctx.pushOp(LogicalNot(negated, result));
      result = negated;
    }
    final boolType = call.returnType;
    return Variable.of(ctx, result, boolType, rep: unboxedRepOf(boolType));
  }
}

/// Calling the *value* held by a field, getter, or record field: read the
/// member, then invoke the result as a closure.
final class MemberValueCall extends CallTarget {
  const MemberValueCall({required this.read, this.order = EvalOrder.argumentsFirst});

  /// Reads the member value (a getter invocation or field load).
  final Variable Function(CompilerContext ctx) read;
  final EvalOrder order;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.calleeBinds;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final callee = read(ctx);
    final result = ClosureCall(callee: callee).emit(ctx, call);
    // The bound call was computed without knowing the callee; the freshly
    // read value may carry callable metadata that refines the result type.
    final refined = resolveCallResultType(
      ctx,
      callee: callee,
      dispatch: null,
      argTypes: [for (final arg in call.positional) arg.value.type],
      namedArgTypes: {
        for (final entry in call.named) entry.$1: entry.$2.value.type,
      },
    );
    return refined == null ? result : result.copyWith(type: refined);
  }
}

/// `super.m(...)` with no concrete member — `Invocation.method`/`getter`
/// then `noSuchMethod` on `this`.
final class NoSuchMethodCall extends CallTarget {
  const NoSuchMethodCall({required this.receiver, required this.name, this.getterShaped = false});

  final Variable receiver;
  final String name;
  final bool getterShaped;

  @override
  CallSignature? get signature => null;

  @override
  BindingPolicy get policy => BindingPolicy.calleeBinds;

  @override
  CallableAbi get abi => const CallableAbi(<ValueRep>[], ValueRep.boxed);

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    // Filled in with the super migration (step 5).
    throw UnimplementedError('NoSuchMethodCall.emit');
  }
}
