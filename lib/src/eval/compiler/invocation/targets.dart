import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'deferred.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import '../values/abi.dart';
import 'binder.dart';
import 'resolver.dart';
import 'bound_call.dart';

/// What is called — the resolver's output: a value holding only the
/// information resolution established (offsets, resolved members,
/// receivers). [emit] produces the IR ops and the result value; binding
/// runs before it, so `emit` never does member lookup. [signature] is
/// statically known on most targets and `null` for dynamic ones.
sealed class CallTarget {
  const CallTarget();

  CallSignature? get signature;

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
    this.declaringLink,
  });

  final DeferredOrOffset offset;
  final Member? member;

  /// For devirtualized methods: the chain link declaring the
  /// implementation — used to bind the implementation's signature
  /// (defaults, context types) rather than the interface's.
  final TypeRef? declaringLink;

  /// An instance receiver prepended to the argument vector (super calls
  /// and devirtualized methods).
  final Variable? receiver;

  /// For devirtualized calls whose body uses `super`: the receiver link
  /// [StaticCall.emit] positions at the declaring owner — `(from, owner)`
  /// chain links — emitted as `LoadSuper` hops at emission time.
  final (TypeRef from, TypeRef owner)? ownerLink;

  /// A boxed receiver carried for runtime generic checks.
  final Variable? typeEnvironmentReceiver;

  @override
  final CallSignature? signature;

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final s = ctx.svar('method_result');
    final link = ownerLink;
    ctx.pushOp(
      Call(
        offset,
        [
          if (receiver != null)
            link != null
                ? ownerLinkSsa(ctx, receiver!.ssa, link.$1, link.$2)
                : receiver!.ssa,
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

  /// A statically known target — today: `getDirectCall` on a
  /// reference-typed callee.
  final DirectCall? known;

  /// The known target's signature, else the callee's own callable
  /// signature (a tear-off's `methodSignature`).
  @override
  CallSignature? get signature => known?.signature ?? callee?.methodSignature;

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
      // Prefer the callee snapshotted at bind time — the binder copies it
      // before the arguments evaluate; the path below remains for bound
      // calls built outside [ArgumentBinder.bindSuppliedOnly]. The callee
      // sits in object position at the call boundary: boxing in place
      // would double-define the SSA, so unboxed values box into a fresh
      // slot.
      final closure =
          call.callee ??
          () {
            final boxed = callee!.boxed
                ? callee!
                : callee!.boxIntoFreshSlot(ctx);
            return Variable.ssa(
              ctx,
              Assign(ctx.svar('closure_target'), boxed.ssa),
              boxed.type,
            );
          }();
      ctx.pushOp(
        InvokeClosure(
          target,
          closure.ssa,
          [for (final arg in call.positional) arg.value.ssa],
          {for (final entry in call.named) entry.$1: entry.$2.value.ssa},
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
    required this.staticType,
    required this.instantiatedType,
    this.name = '',
    this.offset,
    this.constructor,
    this.isConst = false,
    this.externalIndex,
    this.classBridge,
    this.implicitDefault = false,
  });

  /// The declaring class.
  final TypeRef staticType;

  /// The applied type arguments delivered to the callee.
  final TypeRef instantiatedType;

  /// Constructor name (`''` for the unnamed/default constructor).
  final String name;

  /// The resolved call offset for non-bridge constructors.
  final DeferredOrOffset? offset;
  final ConstructorDeclaration? constructor;
  final bool isConst;

  /// Bridge constructors call the host: [externalIndex] is the
  /// `bridgeStaticFunctionIndices` entry; a non-`wrap` [classBridge]
  /// instantiates through `BridgeInstantiate`.
  final int? externalIndex;
  final BridgeClassDef? classBridge;

  /// A class with no declared constructors gets a synthesized `Name.` body
  /// taking only the runtime-type argument.
  final bool implicitDefault;

  bool get _isFactory => constructor?.factoryKeyword != null;

  @override
  CallSignature? get signature => null;

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    var result = ctx.svar('instance');
    if (externalIndex != null) {
      if (classBridge is BridgeClassDef && !classBridge!.wrap) {
        final subclass = BuiltinValue().push(ctx);
        ctx.pushOp(
          BridgeInstantiate(
            result,
            externalIndex!,
            subclass.ssa,
            call.vector(),
            runtimeTypeId: ctx.runtimeTypes.idOf(staticType),
          ),
        );
      } else {
        ctx.pushOp(InvokeExternal(result, externalIndex!, call.vector()));
      }
    } else {
      final callArguments = <SSA>[
        // Enum constructors carry two synthetic leading parameters (index,
        // name) bound by the enum's own value materialization; direct calls
        // — only factories are reachable — bind them to null.
        if (constructor != null &&
            constructor!.parent?.parent is EnumDeclaration) ...[
          BuiltinValue().push(ctx).ssa,
          BuiltinValue().push(ctx).ssa,
        ],
        if (!implicitDefault) ...call.vector(),
        // Generative constructors take a hidden trailing runtime-type arg;
        // the implicit default's synthesized body takes it as its only arg.
        if (implicitDefault || (constructor != null && !_isFactory))
          pushRuntimeTypeId(ctx, instantiatedType),
      ];
      ctx.pushOp(
        Call(
          offset!,
          callArguments,
          result: result,
          // Factories have no receiver, so the class's instantiated type
          // arguments are delivered through the callable-type-argument
          // channel.
          typeArguments: _isFactory
              ? [
                  for (final arg in instantiatedType.typeArguments)
                    ctx.runtimeTypes.idOf(arg),
                ]
              : const [],
        ),
      );
    }
    if (isConst) {
      result = pushInternConst(ctx, result, instantiatedType);
    }
    return Variable.of(
      ctx,
      result,
      instantiatedType,
      rep: ValueRep.boxed,
      concreteTypes: [instantiatedType],
      // A factory may return any subtype — the result is not exactly the
      // declared class.
      exactType: _isFactory ? null : instantiatedType,
    );
  }
}

/// An instance member invoked through the receiver's static type.
/// [member] is the interface member resolution found for [name] — the
/// signature supplied arguments are checked against; the runtime still
/// picks the override.
final class VirtualCall extends CallTarget {
  const VirtualCall({
    required this.receiver,
    required this.name,
    this.member,
    this.isSuperReceiver = false,
  });

  final Variable receiver;
  final String name;

  /// The interface member resolved on the receiver's static type — null
  /// only when no declaration could be found (an untyped `noSuchMethod`
  /// dispatch remains possible).
  final Member? member;

  /// `super.m(...)`: the receiver's link is positioned above the current
  /// layer, so devirtualization uses the link rather than `exactType`.
  final bool isSuperReceiver;

  @override
  CallSignature? get signature => member?.signature;

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
        superReceiver: isSuperReceiver,
      ),
    );
    return Variable.of(ctx, s, call.returnType, rep: ValueRep.boxed);
  }
}

/// A bridge function, constructor, or member.
final class BridgeCall extends CallTarget {
  const BridgeCall({
    this.receiver,
    this.name = '',
    this.externalIndex,
    this.isSuperReceiver = false,
    this.member,
  });

  /// The receiver for an instance bridge member; null for statics.
  final Variable? receiver;
  final String name;

  /// `bridgeStaticFunctionIndices` index for static calls; null emits an
  /// `InvokeDynamic` for an instance member instead.
  final int? externalIndex;

  /// `super.m()` on a bridge member: the receiver is a mid-chain link, so
  /// the runtime resolves the member at-or-below it — dispatching by name
  /// from the root would re-enter the override this call sits beneath.
  final bool isSuperReceiver;

  /// The resolved bridge member, when the call resolved statically.
  final Member? member;

  @override
  CallSignature? get signature => member?.signature;

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
          superReceiver: isSuperReceiver,
        ),
      );
    }
    return Variable.of(ctx, s, call.returnType, rep: ValueRep.boxed);
  }
}

/// The SSA of [receiver]'s inheritance-chain link owned by [owner], emitting
/// a `LoadSuper` hop per level. [from] is the receiver's static type and
/// [owner] a link found on its chain (e.g. via
/// [MemberLookup.implementationOwner]). Method and accessor bodies take
/// `this` as the declaring class's link — the same binding
/// `TypedDispatch.resolve` performs — so direct calls must hand them that
/// link rather than the dispatch root.
SSA ownerLinkSsa(
  CompilerContext ctx,
  SSA receiver,
  TypeRef from,
  TypeRef owner,
) {
  final links = [from, ...ctx.typeSystem.superclassChain(from)];
  var ssa = receiver;
  for (var i = 0; i < links.length; i++) {
    final link = links[i];
    if (link.file == owner.file && link.name == owner.name) return ssa;
    if (i + 1 >= links.length) return receiver; // owner isn't on the chain
    final parent = links[i + 1];
    ssa = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), ssa),
      parent,
      concreteTypes: [parent],
    ).ssa;
  }
  return ssa;
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
  const EqualityCall({
    required this.left,
    required this.right,
    this.negated = false,
  });

  final Variable left;
  final Variable right;
  final bool negated;

  @override
  CallSignature? get signature => null;

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
  const MemberValueCall({
    required this.read,
    this.order = EvalOrder.argumentsFirst,
  });

  /// Reads the member value (a getter invocation or field load).
  final Variable Function(CompilerContext ctx) read;
  final EvalOrder order;

  @override
  CallSignature? get signature => null;

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final callee = read(ctx);
    final result = ClosureCall(callee: callee).emit(ctx, call);
    // The bound call was computed without knowing the callee; the freshly
    // read value may carry callable metadata that refines the result type.
    final refined = callResultType(
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

/// `super.m(...)` with no concrete member — builds an `Invocation.method`
/// or `Invocation.getter` describing the call and dispatches to
/// `noSuchMethod` on `this`.
final class NoSuchMethodCall extends CallTarget {
  const NoSuchMethodCall({required this.name, this.getterShaped = false});

  final String name;
  final bool getterShaped;

  @override
  CallSignature? get signature => null;

  Variable _symbolFor(CompilerContext ctx, String member) {
    final bridge =
        ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:core']!]!;
    final arg = BuiltinValue(stringval: member).push(ctx).boxIfNeeded(ctx);
    return Variable.ssa(
      ctx,
      InvokeExternal(ctx.svar('sym'), bridge['Symbol.']!, [arg.ssa]),
      CoreTypes.symbol.ref(ctx),
    );
  }

  /// The `Invocation.getter` + `noSuchMethod` read producing the callable
  /// member value — evaluated before argument binding on the getter-shaped
  /// `super.m(...)` path.
  Variable emitGetterValue(CompilerContext ctx) {
    final bridge =
        ctx.bridgeStaticFunctionIndices[ctx.libraryMap['dart:core']!]!;
    final invocation = Variable.ssa(
      ctx,
      InvokeExternal(ctx.svar('inv'), bridge['Invocation.getter']!, [
        _symbolFor(ctx, name).ssa,
      ]),
      CoreTypes.invocation.ref(ctx),
    );
    return CallResolver(ctx).invokeOperator(
      ctx.lookupLocal('#this')!,
      'noSuchMethod',
      [invocation],
    ).result;
  }

  @override
  Variable emit(CompilerContext ctx, BoundCall call) {
    final coreLib = ctx.libraryMap['dart:core']!;
    final bridge = ctx.bridgeStaticFunctionIndices[coreLib]!;

    // An abstract getter produces a getter-shaped Invocation; the fetched
    // value is then invoked as a closure.
    if (getterShaped) {
      final getterValue = emitGetterValue(ctx);
      final result = ClosureCall(callee: getterValue).emit(ctx, call);
      final refined = callResultType(
        ctx,
        callee: getterValue,
        dispatch: null,
        argTypes: [for (final arg in call.positional) arg.value.type],
        namedArgTypes: {
          for (final entry in call.named) entry.$1: entry.$2.value.type,
        },
      );
      return refined == null ? result : result.copyWith(type: refined);
    }

    final $this = ctx.lookupLocal('#this')!;

    final listType = CoreTypes.list
        .ref(ctx)
        .copyWith(arguments: [CoreTypes.dynamic.ref(ctx)]);
    final list = Variable.ssa(
      ctx,
      NewList(ctx.svar('list')),
      listType,
      rep: ValueRep.nativeList,
    );
    for (final arg in call.positional) {
      ctx.pushOp(ListAppend(list.ssa, arg.value.boxIfNeeded(ctx).ssa));
    }
    final invArgs = [_symbolFor(ctx, name).ssa, list.boxIfNeeded(ctx).ssa];
    if (call.named.isNotEmpty) {
      final mapType = CoreTypes.map
          .ref(ctx)
          .copyWith(
            arguments: [CoreTypes.symbol.ref(ctx), CoreTypes.dynamic.ref(ctx)],
          );
      final map = Variable.ssa(
        ctx,
        NewMap(ctx.svar('map')),
        mapType,
        rep: ValueRep.nativeMap,
      );
      for (final entry in call.named) {
        ctx.pushOp(
          MapSet(
            map.ssa,
            _symbolFor(ctx, entry.$1).ssa,
            entry.$2.value.boxIfNeeded(ctx).ssa,
          ),
        );
      }
      invArgs.add(map.boxIfNeeded(ctx).ssa);
    }
    final invocation = Variable.ssa(
      ctx,
      InvokeExternal(ctx.svar('inv'), bridge['Invocation.method']!, invArgs),
      CoreTypes.invocation.ref(ctx),
    );
    return CallResolver(
      ctx,
    ).invokeOperator($this, 'noSuchMethod', [invocation]).result;
  }
}
